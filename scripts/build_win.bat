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

:: 获取当前脚本所在目录的绝对路径
set "PROJECT_DIR=%~dp0"
set "RELEASE_DIR=%PROJECT_DIR%build\windows\x64\runner\Release"
set "OUTPUT_DIR=%PROJECT_DIR%build\windows\installer"

echo [*] 正在检查编译产物...
if not exist "%RELEASE_DIR%\%EXE_NAME%" (
    echo [!] 错误: 找不到生成的 EXE 文件，请确认路径:
    echo %RELEASE_DIR%\%EXE_NAME%
    pause
    exit /b 1
)

echo [*] 正在创建安装包输出目录...
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo [*] 正在生成打包配置文件...
(
echo [Setup]
echo AppId={{HONGSHI-STUDENT-APP-UNIQUE-ID}}
echo AppName=%APP_NAME%
echo AppVersion=%VERSION%
echo AppPublisher=%PUBLISHER%
echo DefaultDirName={autopf}\%APP_NAME%
echo OutputDir=%OUTPUT_DIR%
echo OutputBaseFilename=%APP_NAME%_Setup
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
) > "%PROJECT_DIR%temp_build.iss"

echo [*] 正在执行打包程序 (ISCC)...
iscc "%PROJECT_DIR%temp_build.iss"

if %errorlevel% neq 0 (
    echo [!] 打包失败，请检查上面 ISCC 的错误提示。
) else (
    echo.
    echo ========================================
    echo [OK] 打包成功！
    echo 安装包位于: %OUTPUT_DIR%
    echo ========================================
)

:: 清理临时文件
if exist "%PROJECT_DIR%temp_build.iss" del "%PROJECT_DIR%temp_build.iss"
pause