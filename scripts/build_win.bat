@echo off
:: 强制 CMD 使用 UTF-8 编码
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ================= 配置区域 =================
set "APP_NAME=hongshi_student_app"
set "EXE_NAME=hongshi_student_app.exe"
set "PUBLISHER=hongshi"
set "VERSION=1.3.0"
:: 图标路径 (注意：必须是 .ico 格式)
set "ICON_PATH=assets\images\logo.ico"
:: ============================================

:: 1. 路径推导
for %%i in ("%~dp0..") do set "PROJECT_ROOT=%%~fi"
set "RELEASE_DIR=%PROJECT_ROOT%\build\windows\x64\runner\Release"
set "OUTPUT_DIR=%PROJECT_ROOT%\build\windows\installer"
set "ISS_FILE=%PROJECT_ROOT%\temp_installer.iss"
set "ABSOLUTE_ICON_PATH=%PROJECT_ROOT%\%ICON_PATH%"

echo [*] 项目根目录: %PROJECT_ROOT%
cd /d "%PROJECT_ROOT%"

:: 2. 检查图标是否存在
if not exist "%ABSOLUTE_ICON_PATH%" (
    echo [!] 警告: 找不到图标文件 %ABSOLUTE_ICON_PATH%
    echo [!] 请确保你已经把 png 转换成了 ico 格式并放在该路径。
    pause
    exit /b 1
)

:: 3. 检查产物（如果不存在则构建）
if not exist "%RELEASE_DIR%\%EXE_NAME%" (
    echo [!] 未发现产物，开始全量构建...
    call flutter build windows --release
    if not exist "%RELEASE_DIR%\%EXE_NAME%" (
        echo [!] 错误：Flutter 编译未能生成 %EXE_NAME%
        pause
        exit /b 1
    )
)

:: 4. 准备输出目录并生成正确的 ISS 配置
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo [*] 正在生成 Inno Setup 配置...
(
echo [Setup]
echo AppId={{HONGSHI-STUDENT-APP-ID}}
echo AppName=%APP_NAME%
echo AppVersion=%VERSION%
echo AppPublisher=%PUBLISHER%
echo DefaultDirName={autopf}\%APP_NAME%
echo OutputDir=%OUTPUT_DIR%
echo OutputBaseFilename=%APP_NAME%_v%VERSION%_Setup
echo Compression=lzma
echo SolidCompression=yes
echo WizardStyle=modern
echo ; --- 设置安装包自己的图标 ---
echo SetupIconFile=%ABSOLUTE_ICON_PATH%

echo.
echo [Languages]
echo Name: "default"; MessagesFile: "compiler:Default.isl"

echo.
echo [Files]
echo Source: "%RELEASE_DIR%\%EXE_NAME%"; DestDir: "{app}"; Flags: ignoreversion
echo Source: "%RELEASE_DIR%\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
echo ; 把图标也打包进去，方便快捷方式引用
echo Source: "%ABSOLUTE_ICON_PATH%"; DestDir: "{app}"; Flags: ignoreversion

echo.
echo [Icons]
echo ; --- 设置桌面和开始菜单快捷方式的图标 ---
echo Name: "{autoprograms}\%APP_NAME%"; Filename: "{app}\%EXE_NAME%"; IconFilename: "{app}\logo.ico"
echo Name: "{autodesktop}\%APP_NAME%"; Filename: "{app}\%EXE_NAME%"; IconFilename: "{app}\logo.ico"

echo.
echo [Run]
echo Description: "运行 %APP_NAME%"; Filename: "{app}\%EXE_NAME%"; Flags: nowait postinstall skipifsilent
) > "%ISS_FILE%"

:: 5. 打包
echo [*] 正在执行 ISCC 打包...
iscc "%ISS_FILE%"

if %errorlevel% equ 0 (
    if exist "%ISS_FILE%" del "%ISS_FILE%"
    echo.
    echo ========================================
    echo [OK] 安装包打包成功！(已应用自定义图标)
    echo 路径: %OUTPUT_DIR%
    echo ========================================
) else (
    echo [!] 打包失败，请检查报错内容。
)

pause