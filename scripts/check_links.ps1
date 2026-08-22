$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Net.Http
# 项目根目录 = scripts 的上层目录
$root = Split-Path $PSScriptRoot -Parent
$lines = Get-Content (Join-Path $root 'data\webstack.yml')
$entries = New-Object System.Collections.ArrayList
$curTitle = $null
foreach ($line in $lines) {
    if ($line -match '^\s*- title:\s*(.+)$') { $curTitle = $Matches[1].Trim() }
    elseif ($line -match '^\s*url:\s*(.+)$' -and $curTitle) {
        [void]$entries.Add([PSCustomObject]@{ Title = $curTitle; Url = $Matches[1].Trim() })
        $curTitle = $null
    }
}
Write-Host "Parsed $($entries.Count) entries"

$handler = New-Object System.Net.Http.HttpClientHandler
$handler.AllowAutoRedirect = $true
$handler.MaxAutomaticRedirections = 5
$handler.UseCookies = $true
$client = New-Object System.Net.Http.HttpClient($handler)
$client.Timeout = [TimeSpan]::FromSeconds(15)
$client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

$results = New-Object System.Collections.ArrayList
$batchSize = 8
for ($b = 0; $b -lt $entries.Count; $b += $batchSize) {
    $batch = $entries[$b..([Math]::Min($b + $batchSize - 1, $entries.Count - 1))]
    $tasks = @()
    foreach ($e in $batch) {
        $tasks += [PSCustomObject]@{ T = $e.Title; U = $e.Url; Task = $client.GetAsync($e.Url) }
    }
    foreach ($t in $tasks) {
        try {
            # 用 GetAwaiter().GetResult() 直接抛出原始异常，避免 .Result 的非终止错误导致重复记录
            $resp = $t.Task.GetAwaiter().GetResult()
            $status = [int]$resp.StatusCode
            $finalUrl = $resp.RequestMessage.RequestUri.AbsoluteUri
            [void]$results.Add([PSCustomObject]@{ Title = $t.T; Url = $t.U; Status = $status; Final = $finalUrl; Error = '' })
            $resp.Dispose()
        } catch {
            $msg = ''
            if ($_.Exception.InnerException) { $msg = $_.Exception.InnerException.Message }
            if (-not $msg) { $msg = $_.Exception.Message }
            [void]$results.Add([PSCustomObject]@{ Title = $t.T; Url = $t.U; Status = 0; Final = ''; Error = $msg })
        }
    }
    Write-Host "Progress: $([Math]::Min($b + $batchSize, $entries.Count))/$($entries.Count)"
}

$client.Dispose()
$results | Sort-Object Status, Title | Export-Csv -Path (Join-Path $PSScriptRoot 'check_links_result.csv') -NoTypeInformation -Encoding UTF8
Write-Host "Done. Results saved to $PSScriptRoot\check_links_result.csv"
