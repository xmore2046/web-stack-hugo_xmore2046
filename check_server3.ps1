$p = Get-Content 'public\index.html' -Raw
Write-Host ('public 巨量算数: ' + ($p -match '巨量算数'))
Write-Host ('public 新视: ' + ($p -match '新视'))
Write-Host ('public 友望数据: ' + ($p -match '友望数据'))
Write-Host ('public 火烧云数据: ' + ($p -match '火烧云数据'))
Write-Host ('public 星查查: ' + ($p -match '星查查'))
Write-Host ('public 清博大数据: ' + ($p -match '清博大数据'))
Write-Host ('public 火山引擎: ' + ($p -match '火山引擎'))
Write-Host ('public 灰豚数据: ' + ($p -match '灰豚数据'))
Write-Host ('public 海豚数据: ' + ($p -match '海豚数据'))
Write-Host ('public 蝉妈妈: ' + ($p -match '蝉妈妈'))
Write-Host ('public 飞瓜数据: ' + ($p -match '飞瓜数据'))
Write-Host '--- 数据分析相关分类标题 ---'
[regex]::Matches($p, '数据分析') | ForEach-Object { $s = [Math]::Max(0, $_.Index - 20); $p.Substring($s, [Math]::Min(60, $p.Length - $s)) -replace '[\r\n]+',' ' }
