$csv = Import-Csv "check_links_result.csv"
Write-Host "=== Status Distribution ==="
$csv | Group-Object Status | Sort-Object {[int]$_.Name} | ForEach-Object {
    if ($_.Name -eq '0') { Write-Host "NETWORK-FAIL: $($_.Count)" }
    else { Write-Host "HTTP $($_.Name): $($_.Count)" }
}
Write-Host ""
Write-Host "=== Network Failures (Status 0) ==="
$csv | Where-Object { $_.Status -eq '0' } | ForEach-Object { Write-Host "$($_.Title) | $($_.Url) | $($_.Error)" }
Write-Host ""
Write-Host "=== HTTP 4xx ==="
$csv | Where-Object { $_.Status -ge 400 -and $_.Status -lt 500 } | ForEach-Object { Write-Host "$($_.Title) | $($_.Url) | $($_.Status) | final:$($_.Final)" }
Write-Host ""
Write-Host "=== HTTP 5xx ==="
$csv | Where-Object { $_.Status -ge 500 } | ForEach-Object { Write-Host "$($_.Title) | $($_.Url) | $($_.Status)" }
Write-Host ""
Write-Host "=== HTTP 3xx (redirects) ==="
$csv | Where-Object { $_.Status -ge 300 -and $_.Status -lt 400 } | ForEach-Object { Write-Host "$($_.Title) | $($_.Url) -> $($_.Final)" }
