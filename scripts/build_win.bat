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

:: 1. 绝对路径计算：获取 scripts 文件夹的上一层（项目根目录）
for %%i in ("%~dp0..") do set "PROJECT_ROOT=%%~fi"

set "RELEASE_DIR=%PROJECT_ROOT%\build\windows\x64\runner\Release"
set "OUTPUT_DIR=%PROJECT_ROOT%\build\windows\installer"
set "ISS_FILE=%PROJECT_ROOT%\temp_installer.iss"

echo [*] 项目根目录定位: %PROJECT_ROOT%

:: 切换工作目录到根目录，确保 flutter 命令能正常执行
cd /d "%PROJECT_ROOT%"

:: 2. 检查编译产物
if not exist "%RELEASE_DIR%\%EXE_NAME%" (
    echo [!] 未发现编译产物: %RELEASE_DIR%\%EXE_NAME%
    echo [*] 正在启动全流程编译...

    :: 执行编译
    call flutter pub get
    call flutter build windows --release

    :: 编译后的二次检查
    if not exist "%RELEASE_DIR%\%EXE_NAME%" (
        echo [!] Flutter 编译似乎失败了，请检查上方控制台输出。
        pause
        exit /b 1
    )
) else (
    echo [OK] 发现现有产物，跳过编译。
)

:: 3. 准备打包目录
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
echo ; 核心：指定下载到 C:\Windows 的语言文件
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

:: 4. 调用 ISCC 打包
echo [*] 正在执行 ISCC 打包...
iscc "%ISS_FILE%"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [OK] 打包成功！
    echo 安装包: %OUTPUT_DIR%\%APP_NAME%_v%VERSION%_Setup.exe
    echo ========================================
) else (
    echo [!] ISCC 执行失败，请检查 C:\Windows 下是否有 iscc.exe, iscmplr.dll 和 Default.isl
)

:: 清理临时文件
if exist "%ISS_FILE%" del "%ISS_FILE%"

pause