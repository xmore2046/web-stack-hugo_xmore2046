$p = Get-Content 'public\index.html' -Raw
Write-Host ('public kwaixiaodian: ' + ($p -match 'kwaixiaodian'))
Write-Host ('public zbyan: ' + ($p -match 'pc\.zbyan\.net'))
$ports = netstat -ano | Select-String ':1313.*LISTENING'
if ($ports) { Write-Host 'hugo server listening:'; $ports } else { Write-Host 'hugo server NOT listening on 1313' }
