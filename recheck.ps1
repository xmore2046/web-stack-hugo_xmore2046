$urls = @(
    'https://365psd.com/',
    'https://www.easyicon.net/',
    'https://findicons.com/',
    'https://khroma.co/generator/',
    'https://mustsee.earth/',
    'https://book.saltyleo.com/',
    'https://screenshots.pro/',
    'https://simplelineicons.com/',
    'https://qrohlf.com/trianglify-generator/',
    'https://ui-cloud.com/',
    'https://windsurf.com/',
    'https://value500.com/',
    'https://www.diediejia.com/',
    'https://www.toubang.tv/',
    'https://ziticq.com/',
    'https://business.kuaishou.com/',
    'https://xh.newrank.cn/',
    'https://www.dzkbw.com/',
    'https://pc.zbyan.net/',
    'https://www.duanyuer.com/',
    'https://sicangziti.com/',
    'https://www.sccnn.com/',
    'https://so.ui001.com/',
    'https://bbs.pinggu.org/',
    'https://www.chanxiaohong.com/'
)
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
foreach ($u in $urls) {
    $out = & curl.exe -s -o NUL -w '%{http_code} %{errormsg} %{url_effective}' -L --connect-timeout 8 --max-time 20 -A $ua $u 2>&1
    Write-Host "$u => $out"
}
