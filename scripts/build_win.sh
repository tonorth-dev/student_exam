#!/bin/bash

# 获取操作系统类型
OS="$(uname -s)"

# 清理之前的构建
echo "清理之前的构建..."
flutter clean

# 获取依赖
echo "获取依赖..."
flutter pub get

# 生成应用图标
echo "生成应用图标..."
python3 scripts/generate_icons.py

# 根据操作系统执行不同的构建命令
if [ "$OS" = "Darwin" ]; then
    echo "在 macOS 上构建..."
    
    # 构建 macOS 应用
    flutter build macos --release
    
    # 创建 DMG 文件
    # 首先确保已安装 create-dmg
    if ! command -v create-dmg &> /dev/null; then
        echo "安装 create-dmg..."
        brew install create-dmg
    fi
    
    # 应用路径
    APP_PATH="build/macos/Build/Products/Release/红师教育学生端.app"
    DMG_PATH="build/红师教育学生端.dmg"
    
    # 创建 DMG
    echo "创建 DMG 安装包..."
    create-dmg \
        --volname "红师教育学生端" \
        --window-pos 200 120 \
        --window-size 800 400 \
        --icon-size 100 \
        --icon "红师教育学生端.app" 200 190 \
        --hide-extension "红师教育学生端.app" \
        --app-drop-link 600 185 \
        "$DMG_PATH" \
        "$APP_PATH"
    
    echo "DMG 安装包已生成: $DMG_PATH"

elif [ "$OS" = "MINGW64_NT-10.0" ] || [ "$OS" = "MINGW32_NT-10.0" ]; then
    echo "在 Windows 上构建..."
    
    # 构建 Windows 应用
    flutter build windows --release
    
    echo "使用 Inno Setup 创建安装程序（无需证书）..."
    
    # 创建 Inno Setup 脚本
    cat > installer.iss << 'EOF'
#define MyAppName "红师教育学生端"
#define MyAppVersion "1.1.0"
#define MyAppPublisher "红师教育"
#define MyAppExeName "student_exam.exe"
#define MyAppURL "https://www.hongshiedu.com"

[Setup]
; 基本信息
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; 安装路径
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

; 输出设置
OutputDir=build
OutputBaseFilename=红师教育学生端_setup
Compression=lzma2/max
SolidCompression=yes

; 图标和界面
SetupIconFile=windows\runner\resources\app_icon.ico
WizardStyle=modern

; 权限
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

; 其他设置
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "quicklaunchicon"; Description: "创建快速启动图标"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\卸载 {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
EOF

    # 检查 Inno Setup 是否安装
    ISCC_PATH=""
    if [ -f "/c/Program Files (x86)/Inno Setup 6/ISCC.exe" ]; then
        ISCC_PATH="/c/Program Files (x86)/Inno Setup 6/ISCC.exe"
    elif [ -f "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" ]; then
        ISCC_PATH="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
    else
        echo "错误: 未找到 Inno Setup"
        echo "请从以下地址下载并安装 Inno Setup 6:"
        echo "https://jrsoftware.org/isdl.php"
        exit 1
    fi
    
    # 编译安装程序
    echo "正在编译安装程序..."
    "$ISCC_PATH" installer.iss
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "=========================================="
        echo "✓ Windows 安装程序已生成成功！"
        echo "=========================================="
        echo "文件位置: build/红师教育学生端_setup.exe"
        echo ""
        echo "特点："
        echo "  • 无需证书签名"
        echo "  • 用户无需安装证书"
        echo "  • 传统 .exe 安装程序"
        echo "  • 支持桌面快捷方式"
        echo "  • 支持开始菜单"
        echo ""
        echo "分发说明："
        echo "  直接将 build/红师教育学生端_setup.exe 发给用户"
        echo "  用户双击即可安装，无需任何额外操作"
        echo "=========================================="
    else
        echo "错误: 安装程序编译失败"
        exit 1
    fi
else
    echo "不支持的操作系统"
    exit 1
fi

echo "构建完成！"
