@echo off
:: 强制 CMD 使用 UTF-8 编码，确保能正确处理中文变量
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ================= 配置区域 =================
set "APP_NAME=红师学生端"
set "EXE_NAME=hongshi_student_app.exe"
set "PUBLISHER=红师教育"
set "VERSION=1.3.0"
:: ============================================

:: 1. 路径推导
for %%i in ("%~dp0..") do set "PROJECT_ROOT=%%~fi"
set "RELEASE_DIR=%PROJECT_ROOT%\build\windows\x64\runner\Release"
set "OUTPUT_DIR=%PROJECT_ROOT%\build\windows\installer"
set "ISS_FILE=%PROJECT_ROOT%\temp_installer.iss"

echo [*] 项目根目录: %PROJECT_ROOT%
cd /d "%PROJECT_ROOT%"

:: 2. 检查产物（如果不存在则构建）
if not exist "%RELEASE_DIR%\%EXE_NAME%" (
    echo [!] 未发现产物，开始全量构建...
    call flutter build windows --release
    if not exist "%RELEASE_DIR%\%EXE_NAME%" (
        echo [!] 错误：Flutter 编译未能生成 %EXE_NAME%
        pause
        exit /b 1
    )
)

:: 3. 生成安装配置文件 (关键：给中文字符加上双引号)
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo [*] 正在生成 Inno Setup 配置...
(
echo [Setup]
echo AppId={{88888888-4444-4444-4444-1234567890AB}
echo AppName="%APP_NAME%"
echo AppVersion="%VERSION%"
echo AppPublisher="%PUBLISHER%"
echo DefaultDirName="{autopf}\%APP_NAME%"
echo OutputDir="%OUTPUT_DIR%"
echo OutputBaseFilename="%APP_NAME%_v%VERSION%_Setup"
echo Compression=lzma
echo SolidCompression=yes
echo WizardStyle=modern

echo.
echo [Languages]
echo Name: "chinesesimplified"; MessagesFile: "compiler:Default.isl"

echo.
echo [Files]
echo Source: "%RELEASE_DIR%\%EXE_NAME%"; DestDir: "{app}"; Flags: ignoreversion
echo Source: "%RELEASE_DIR%\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

echo.
echo [Icons]
echo Name: "{autoprograms}\%APP_NAME%"; Filename: "{app}\%EXE_NAME%"
echo Name: "{autodesktop}\%APP_NAME%"; Filename: "{app}\%EXE_NAME%"

echo.
echo [Run]
echo Description: "运行 %APP_NAME%"; Filename: "{app}\%EXE_NAME%"; Flags: nowait postinstall skipifsilent
) > "%ISS_FILE%"

:: 4. 打包
echo [*] 正在执行 ISCC 打包...
:: 注意：这里显式指定 /UTF-8 参数，确保中文不乱码
iscc /UTF-8 "%ISS_FILE%"

if %errorlevel% equ 0 (
    if exist "%ISS_FILE%" del "%ISS_FILE%"
    echo.
    echo ========================================
    echo [OK] 安装包打包成功！
    echo 路径: %OUTPUT_DIR%
    echo ========================================
) else (
    echo [!] 打包失败，请检查报错内容。
)

pause