@echo off
chcp 65001 >nul
setlocal EnableExtensions
title WebStack-Hugo 自动构建部署

rem ============================================================
rem  build-and-push.bat - 构建 -> 提交 -> 推送（CI 自动部署）
rem
rem  用法:
rem    build-and-push.bat                     默认：构建并发布
rem    build-and-push.bat "提交说明"           使用自定义提交信息
rem    build-and-push.bat --skip-build        跳过本地构建，仅提交+推送
rem    build-and-push.bat --dry-run           演练：只做检查，不提交不推送
rem    build-and-push.bat --help              显示本用法
rem
rem  说明:
rem    - 部署由 GitHub Actions (.github/workflows/hugo.yml)
rem      在 push 到 main 分支后自动构建并发布到 Cloudflare Pages
rem    - 构建产物 public/ 已被 .gitignore 忽略，不会提交入库
rem ============================================================

rem 切换到项目根目录（脚本位于 scripts/ 子目录）
cd /d "%~dp0.."

rem ---- 参数解析 ----
set "SKIP_BUILD=0"
set "DRY_RUN=0"
set "MSG=%~1"
if /i "%MSG%"=="--help"       goto usage
if /i "%MSG%"=="--skip-build" set "SKIP_BUILD=1" & set "MSG=%~2"
if /i "%MSG%"=="--dry-run"    set "DRY_RUN=1"    & set "MSG=%~2"

rem ---- 标准时间戳（避免中文系统 %date% 格式差异导致的乱码日期）----
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm'"`) do set "DT=%%i"
if "%MSG%"=="" set "MSG=site update %DT%"

echo ==========================================
echo   WebStack-Hugo 自动构建 + 发布
echo   时间: %DT%
if "%DRY_RUN%"=="1" echo   模式: 演练模式 (--dry-run)
echo ==========================================
echo.

rem ---- 前置检查 ----
where hugo >nul 2>&1 || (echo [错误] 未找到 hugo 命令，请先安装 Hugo 并加入 PATH。 & pause & exit /b 1)
where git  >nul 2>&1 || (echo [错误] 未找到 git 命令，请先安装 Git。 & pause & exit /b 1)
if not exist ".git" (echo [错误] 当前目录不是 Git 仓库：%CD% & pause & exit /b 1)
git remote get-url origin >nul 2>&1 || (echo [错误] 未配置远程仓库 origin，请先执行 git remote add origin ^<url^> & pause & exit /b 1)

for /f "delims=" %%i in ('git rev-parse --abbrev-ref HEAD') do set "CUR_BRANCH=%%i"
if not "%CUR_BRANCH%"=="main" (
    echo [警告] 当前分支为 %CUR_BRANCH%，CI 仅在 main 分支触发 Cloudflare Pages 部署。
    choice /C YN /N /M "是否仍要继续? [Y/N]: "
    if errorlevel 2 exit /b 1
)

echo [1/3] Hugo 构建中...
if "%SKIP_BUILD%"=="1" (
    echo [跳过] 已指定 --skip-build
) else (
    call hugo --gc --minify --cleanDestinationDir
    if errorlevel 1 (
        echo.
        echo [错误] Hugo 构建失败，请检查配置/内容后重试。
        pause & exit /b 1
    )
    echo [成功] 构建完成 (public/)
)
echo.

echo [2/3] 提交变更到 Git...
git add -A
git diff --cached --quiet
if errorlevel 1 (
    rem 未配置 git 作者信息时使用一次性覆盖，不修改全局配置
    git config user.email >nul 2>&1
    if errorlevel 1 (
        git -c user.name="xmore2046" -c user.email="xmore2046@outlook.com" commit -m "%MSG%" >nul
    ) else (
        git commit -m "%MSG%" >nul
    )
    if errorlevel 1 (echo [错误] Git 提交失败。 & pause & exit /b 1)
    echo [成功] 已提交: %MSG%
    set "HAS_COMMIT=1"
    echo [%DT%] commit: %MSG% >> scripts\deploy.log
) else (
    echo [提示] 未检测到改动，跳过提交。
    set "HAS_COMMIT=0"
)
echo.

rem ---- 演练模式：到此为止 ----
if "%DRY_RUN%"=="1" (
    echo [演练] --dry-run 模式：未执行 git push，未产生任何提交/推送。
    echo.
    echo ==========================================
    echo    演练结束
    echo ==========================================
    pause
    exit /b 0
)

if "%HAS_COMMIT%"=="0" (
    echo [提示] 本地无新提交，无需推送。
    echo.
    pause
    exit /b 0
)

echo [3/3] 推送到远程仓库（触发 Cloudflare Pages 自动部署）...
git push origin main
if errorlevel 1 (
    echo.
    echo [错误] 推送失败，请检查网络连接与仓库权限。
    pause & exit /b 1
)
echo [成功] 推送完成
echo [%DT%] push origin main: OK >> scripts\deploy.log
echo.

for /f "delims=" %%i in ('git remote get-url origin') do set "REMOTE_URL=%%i"
echo ==========================================
echo    全部完成！
echo    仓库: %REMOTE_URL%
echo    Cloudflare Pages 正在自动构建部署，约 1-2 分钟生效
echo    访问: https://web-panel.vpmaxs.dpdns.org
echo ==========================================
echo.
pause
exit /b 0

:usage
echo 用法: build-and-push.bat [选项] ["提交说明"]
echo.
echo   无参数       构建并发布（提交信息为 site update ^<时间^>）
echo   "提交说明"   使用自定义提交信息
echo   --skip-build 跳过本地构建，仅提交并推送
echo   --dry-run    演练模式：执行检查但不提交、不推送
echo   --help       显示本用法
echo.
exit /b 0
