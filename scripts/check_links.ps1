# ============================================================
# check_links.ps1 - 站点链接与图标完整性校验
#
# 功能：
#   1. 真实链接校验：GET 请求 data/webstack.yml 与 data/friendlinks.yml 中所有链接
#   2. 图标校验：检查 webstack.yml 中引用的 logo 文件是否存在于
#      static/assets/images/logos/
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File scripts/check_links.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/check_links.ps1 -SkipLinks   # 只查图标
#   powershell -ExecutionPolicy Bypass -File scripts/check_links.ps1 -SkipIcons  # 只查链接
#
# 结果输出：
#   scripts/check_links_result.csv  （全部条目的详细结果）
# ============================================================

param(
    [switch]$SkipLinks,
    [switch]$SkipIcons
)

$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Net.Http

# ---- 路径 ----
$root       = Split-Path $PSScriptRoot -Parent
$dataFile   = Join-Path $root 'data\webstack.yml'
$friendFile = Join-Path $root 'data\friendlinks.yml'
$logosDir   = Join-Path $root 'static\assets\images\logos'
$outCsv     = Join-Path $PSScriptRoot 'check_links_result.csv'

# ============================================================
# 1. 解析 YAML 条目（只取 title/url/logo 三个字段）
# ============================================================
function Parse-Yaml($path) {
    $items = New-Object System.Collections.ArrayList
    if (-not (Test-Path $path)) { Write-Warning "File not found: $path"; return $items }
    $lines = Get-Content $path
    $t = $null; $u = $null; $l = $null
    foreach ($line in $lines) {
        if ($line -match '^\s*- title:\s*(.+)$') {
            if ($t) { [void]$items.Add([PSCustomObject]@{ Title = $t; Url = $u; Logo = $l }) }
            $t = $Matches[1].Trim(); $u = $null; $l = $null
        }
        elseif ($line -match '^\s*url:\s*(.+)$' -and $t)      { $u = $Matches[1].Trim() }
        elseif ($line -match '^\s*logo:\s*(.+)$' -and $t)     { $l = $Matches[1].Trim() }
    }
    if ($t) { [void]$items.Add([PSCustomObject]@{ Title = $t; Url = $u; Logo = $l }) }
    return $items
}

$entries = @(Parse-Yaml $dataFile)
$friends = @(Parse-Yaml $friendFile)
Write-Host "Parsed: webstack=$($entries.Count) friendlinks=$($friends.Count)"

# ============================================================
# 2. 图标完整性校验
# ============================================================
$missingIcons = New-Object System.Collections.ArrayList
if (-not $SkipIcons) {
    Write-Host "`n[Icons] Checking logo files in $logosDir"
    foreach ($e in $entries) {
        if (-not $e.Logo) { continue }
        if ($e.Logo -match '^(https?://|/)') { continue }   # 远程 URL 或站点绝对路径，跳过
        $fp = Join-Path $logosDir $e.Logo
        if (-not (Test-Path $fp)) {
            [void]$missingIcons.Add([PSCustomObject]@{ Title = $e.Title; Logo = $e.Logo })
        }
    }
    Write-Host "Icons missing: $($missingIcons.Count)"
    foreach ($m in ($missingIcons | Sort-Object Logo)) {
        Write-Host ("  [MISS] {0}  ->  logos/{1}" -f $m.Title, $m.Logo)
    }
}

# ============================================================
# 3. 真实链接校验
# ============================================================
$linkResults = New-Object System.Collections.ArrayList
if (-not $SkipLinks) {
    $all = @($entries | ForEach-Object { [PSCustomObject]@{ Title = $_.Title; Url = $_.Url; Logo = $_.Logo } }) +
           @($friends | ForEach-Object { [PSCustomObject]@{ Title = $_.Title; Url = $_.Url; Logo = $_.Logo } })
    $all = $all | Where-Object { $_.Url }
    Write-Host "`n[Links] Checking $($all.Count) URLs ..."

    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.AllowAutoRedirect = $true
    $handler.MaxAutomaticRedirections = 5
    $handler.UseCookies = $true
    $client = New-Object System.Net.Http.HttpClient($handler)
    $client.Timeout = [TimeSpan]::FromSeconds(15)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

    $batchSize = 8
    for ($b = 0; $b -lt $all.Count; $b += $batchSize) {
        $batch = $all[$b..([Math]::Min($b + $batchSize - 1, $all.Count - 1))]
        $tasks = @()
        foreach ($e in $batch) {
            $tasks += [PSCustomObject]@{ T = $e.Title; U = $e.Url; Task = $client.GetAsync($e.Url) }
        }
        foreach ($t in $tasks) {
            try {
                $resp = $t.Task.GetAwaiter().GetResult()
                $status = [int]$resp.StatusCode
                $finalUrl = $resp.RequestMessage.RequestUri.AbsoluteUri
                [void]$linkResults.Add([PSCustomObject]@{
                    Title = $t.T; Url = $t.U; Status = $status; Final = $finalUrl; Error = ''
                })
                $resp.Dispose()
            } catch {
                $msg = ''
                if ($_.Exception.InnerException) { $msg = $_.Exception.InnerException.Message }
                if (-not $msg) { $msg = $_.Exception.Message }
                [void]$linkResults.Add([PSCustomObject]@{
                    Title = $t.T; Url = $t.U; Status = 0; Final = ''; Error = $msg
                })
            }
        }
        Write-Host "Progress: $([Math]::Min($b + $batchSize, $all.Count))/$($all.Count)"
    }
    $client.Dispose()
}

# ============================================================
# 4. 汇总报告
# ============================================================
Write-Host "`n==================== SUMMARY ===================="
if (-not $SkipIcons) {
    Write-Host "Missing icons : $($missingIcons.Count)"
}
if (-not $SkipLinks) {
    $ok     = @($linkResults | Where-Object { $_.Status -ge 200 -and $_.Status -lt 400 })
    $warn   = @($linkResults | Where-Object { $_.Status -eq 403 })
    $dead   = @($linkResults | Where-Object { $_.Status -ge 400 -and $_.Status -ne 403 })
    $failed = @($linkResults | Where-Object { $_.Status -eq 0 })
    Write-Host "Links OK      : $($ok.Count)"
    Write-Host "Links 403     : $($warn.Count)  (可能为反爬/需登录，人工确认)"
    Write-Host "Links DEAD    : $($dead.Count)  (4xx/5xx)"
    Write-Host "Links FAILED  : $($failed.Count)  (超时/SSL/连接失败)"
    Write-Host "----------------------------------------------"
    foreach ($d in ($dead + $failed)) {
        $tag = if ($d.Status -eq 0) { 'FAIL' } else { 'DEAD' }
        Write-Host ("  [{0}] {1}  ->  {2}  {3}" -f $tag, $d.Title, $d.Url, $d.Error)
    }
    $linkResults | Sort-Object Status, Title |
        Export-Csv -Path $outCsv -NoTypeInformation -Encoding UTF8
    Write-Host "`nDetails saved to $outCsv"
}
Write-Host "================================================"
