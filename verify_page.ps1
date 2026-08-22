$html = (Invoke-WebRequest -Uri 'http://127.0.0.1:1313/' -UseBasicParsing -TimeoutSec 20).Content
Write-Host '=== 已删除站点检查 ==='
@('365PSD','EasyIcon','FindIcons','Trianglify','素材搜索','蝉小红','新红','头榜','短鱼儿','叠叠加','SaltyLeo','求职招聘','招聘平台') | ForEach-Object {
    Write-Host "$_ 已移除: $(-not ($html -match $_))"
}
Write-Host '=== 更新后链接检查 ==='
@('devin.ai','syt.kwaixiaodian.com','simplelineicons.github.io','www.khroma.co','http://ui-cloud.com','www.ziticq.com','http://pc.zbyan.net','http://www.sccnn.com','http://www.dzkbw.com','http://value500.com') | ForEach-Object {
    Write-Host "$_ 存在: $($html -match $_)"
}
Write-Host ('链接总数: ' + [regex]::Matches($html, 'url:').Count)
