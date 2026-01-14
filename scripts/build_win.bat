@echo off
:: 强制 CMD 使用 UTF-8 编码
chcp 65001 >nul
setlocal

:: ================= 配置区域 =================
set "APP_NAME=红师学生端"
set "EXE_NAME=hongshi_student.exe"
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

:: 2. 构建逻辑 (强制检查文件)
if not exist "%RELEASE_DIR%\%EXE_NAME%" (
    echo [!] 未发现产物，开始构建...
    call flutter pub get
    call flutter build windows --release

    :: 关键修正：编译后不再检查 errorlevel，直接检查文件是否存在
    if not exist "%RELEASE_DIR%\%EXE_NAME%" (
        echo [!] 错误：文件仍然不存在。请检查磁盘空间或权限。
        pause
        exit /b 1
    )
    echo [OK] 编译完成。
) else (
    echo [OK] 产物已存在，跳过编译。
)

:: 3. 准备输出目录
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
echo ; 使用 C:\Windows 下的语言文件
echo DefaultLanguagesFile=compiler:Default.isl

echo [Files]
echo Source: "%RELEASE_DIR%\%EXE_NAME%"; DestDir: "{app}"; Flags: ignoreversion
echo Source: "%RELEASE_DIR%\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

echo [Icons]
echo Name: "{autoprograms}\%APP_NAME%"; Filename: "{app}\%EXE_NAME%"
echo Name: "{autodesktop}\%APP_NAME%"; Filename: "{app}\%EXE_NAME%"

echo [Run]
echo Description: "运行 %APP_NAME%"; Filename: "{app}\%EXE_NAME%"; Flags: nowait postinstall skipifsilent
) > "%ISS_FILE%"

:: 4. 打包
echo [*] 正在执行 ISCC 打包...
iscc "%ISS_FILE%"

if exist "%ISS_FILE%" del "%ISS_FILE%"

if exist "%OUTPUT_DIR%\%APP_NAME%_v%VERSION%_Setup.exe" (
    echo.
    echo ========================================
    echo [OK] 安装包打包成功！
    echo 位置: %OUTPUT_DIR%
    echo ========================================
) else (
    echo [!] 打包失败，请确保 C:\Windows 下有 iscc.exe 和 Default.isl
)

pause