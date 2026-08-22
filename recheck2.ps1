$tests = @(
    @{ name = 'ui-cloud.com'; url = 'http://ui-cloud.com/' },
    @{ name = 'ui-cloud www'; url = 'https://www.ui-cloud.com/' },
    @{ name = 'ziticq http'; url = 'http://www.ziticq.com/' },
    @{ name = 'ziticq www'; url = 'https://www.ziticq.com/' },
    @{ name = 'dzkbw http'; url = 'http://www.dzkbw.com/' },
    @{ name = 'zbyan http'; url = 'http://pc.zbyan.net/' },
    @{ name = 'ui001 http'; url = 'http://so.ui001.com/' },
    @{ name = 'value500 long'; url = 'https://value500.com/' },
    @{ name = 'diediejia www'; url = 'https://www.diediejia.com/' },
    @{ name = 'toubang www'; url = 'https://www.toubang.tv/' },
    @{ name = 'duanyuer www'; url = 'https://www.duanyuer.com/' },
    @{ name = 'sccnn www'; url = 'http://www.sccnn.com/' },
    @{ name = 'simplelineicons long'; url = 'https://simplelineicons.com/' },
    @{ name = 'windsurf devin'; url = 'https://devin.ai/' },
    @{ name = 'khroma new'; url = 'https://www.khroma.co/generator/' }
)
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
foreach ($t in $tests) {
    $out = & curl.exe -s -o NUL -w '%{http_code} %{errormsg}' -L -k --connect-timeout 10 --max-time 25 -A $ua $t.url 2>&1
    Write-Host "$($t.name) | $($t.url) => $out"
}
