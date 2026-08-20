@echo off
chcp 65001 >nul
setlocal
title WebStack-Hugo 自动构建部署
cd /d "%~dp0"

echo ==========================================
echo    WebStack-Hugo 自动构建 + 发布
echo ==========================================
echo.

rem 检查 Hugo 是否可用
where hugo >nul 2>&1
if errorlevel 1 (
    echo [错误] 未找到 hugo 命令，请先安装 Hugo 并加入 PATH。
    pause
    exit /b 1
)

echo [1/3] Hugo 构建中...
call hugo --gc --minify
if errorlevel 1 (
    echo.
    echo [错误] Hugo 构建失败，请检查配置/内容后重试。
    pause
    exit /b 1
)
echo [成功] 构建完成 (public/)
echo.

set "DT=%date:~0,4%-%date:~5,2%-%date:~8,2%"

echo [2/3] 提交变更到 Git...
git add -A
git diff --cached --quiet
if errorlevel 1 (
    rem 未配置 git 作者信息时使用一次性覆盖，不修改全局配置
    git config user.email >nul 2>&1
    if errorlevel 1 (
        git -c user.name="xmore2046" -c user.email="xmore2046@outlook.com" commit -m "site update %DT%" >nul
    ) else (
        git commit -m "site update %DT%" >nul
    )
    if errorlevel 1 (
        echo [错误] Git 提交失败。
        pause
        exit /b 1
    )
    echo [成功] 已提交: site update %DT%
) else (
    echo [提示] 未检测到改动，跳过提交。
)
echo.

echo [3/3] 推送到远程仓库（触发 Cloudflare 自动部署）...
git push
if errorlevel 1 (
    echo.
    echo [错误] 推送失败，请检查网络连接与仓库权限。
    pause
    exit /b 1
)
echo [成功] 推送完成
echo.

echo ==========================================
echo    全部完成！
echo    Cloudflare 正在自动构建部署，约 1-2 分钟后生效
echo    访问: https://web-panel.vpmaxs.dpdns.org
echo ==========================================
echo.
pause
