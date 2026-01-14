@echo off
:: 强制 CMD 使用 UTF-8 编码
chcp 65001 >nul
setlocal

:: ================= 配置区域 =================
set "APP_NAME=我的应用"
set "EXE_NAME=my_app.exe"
set "PUBLISHER=我的公司"
set "VERSION=1.0.0"
:: ============================================

echo [*] 正在清理旧构建...
call flutter clean

echo [*] 正在执行 Flutter 编译 (Windows Release)...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo [!] Flutter 编译失败，请检查代码。
    pause
    exit /b %errorlevel%
)

echo [*] 正在检测 Inno Setup...
where iscc >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] 未找到 iscc 命令。请确保安装了 Inno Setup 并将路径加入环境变量 PATH。
    pause
    exit /b 1
)

echo [*] 正在生成安装程序...
:: 使用命令行参数直接传递配置，无需独立的 .iss 文件
iscc /Q /DAppName="%APP_NAME%" /DAppVersion="%VERSION%" /DAppPublisher="%PUBLISHER%" /DAppExeName="%EXE_NAME%" /DOutputDir="build\windows\installer" /DSourcePath="build\windows\x64\runner\Release" "scripts\template.iss"

echo.
echo ========================================
echo [OK] 打包成功! 
echo 安装包路径: build\windows\installer\
echo ========================================
pause