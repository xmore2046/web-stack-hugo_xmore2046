$p = Get-Content 'public\index.html' -Raw
Write-Host ('public has 快手生意通 title: ' + ($p -match '快手生意通'))
Write-Host ('public has 直播眼 title: ' + ($p -match '直播眼'))
Write-Host ('public has any kuaishou ref: ' + ($p -match 'kuaishou'))
Write-Host ('public has any zbyan ref: ' + ($p -match 'zbyan'))
Write-Host ('data file mtime: ' + (Get-Item 'data\webstack.yml').LastWriteTime)
Write-Host ('public index mtime: ' + (Get-Item 'public\index.html').LastWriteTime)
# 检查这两个条目的上下文是否正确缩进
$lines = Get-Content 'data\webstack.yml'
$start = 750; $end = 790
for ($i = $start; $i -le $end -and $i -lt $lines.Count; $i++) { Write-Host ($i+1).ToString() + ': ' + $lines[$i] }
