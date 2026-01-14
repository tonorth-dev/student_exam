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

:: 自动定位项目根目录 (假设脚本在 scripts/ 目录下，寻找上一级)
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%.."
set "PROJECT_ROOT=%cd%"

set "RELEASE_DIR=%PROJECT_ROOT%\build\windows\x64\runner\Release"
set "OUTPUT_DIR=%PROJECT_ROOT%\build\windows\installer"

echo [*] 当前项目根目录: %PROJECT_ROOT%

:: --- 第一步：检查并编译 ---
if not exist "%RELEASE_DIR%\%EXE_NAME%" (
    echo [!] 未检测到编译产物，正在开始全流程构建...

    echo [*] 正在获取 Flutter 依赖...
    call flutter pub get

    echo [*] 正在执行 Flutter 编译 (Windows Release)...
    call flutter build windows --release

    if !errorlevel! neq 0 (
        echo [!] Flutter 编译失败，请检查代码错误。
        pause
        exit /b 1
    )
) else (
    echo [OK] 检测到现有编译产物，跳过编译步骤直接打包。
    echo [Tips] 如果需要重新编译，请先运行 flutter clean 或删除 build 目录。
)

:: --- 第二步：准备打包 ---
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo [*] 正在生成 Inno Setup 配置文件...
set "ISS_FILE=%PROJECT_ROOT%\temp_installer.iss"

(
echo [Setup]
echo AppId={{HONGSHI-STUDENT-APP-ID-2026}}
echo AppName=%APP_NAME%
echo AppVersion=%VERSION%
echo AppPublisher=%PUBLISHER%
echo DefaultDirName={autopf}\%APP_NAME%
echo OutputDir=%OUTPUT_DIR%
echo OutputBaseFilename=%APP_NAME%_v%VERSION%_Setup
echo Compression=lzma
echo SolidCompression=yes
echo WizardStyle=modern
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

:: --- 第三步：执行打包 ---
echo [*] 正在调用 ISCC 生成安装包...
iscc "%ISS_FILE%"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [OK] 任务圆满完成！
    echo 安装包位置: %OUTPUT_DIR%\%APP_NAME%_v%VERSION%_Setup.exe
    echo ========================================
) else (
    echo [!] 打包过程出现异常。
)

:: 清理
if exist "%ISS_FILE%" del "%ISS_FILE%"
pause