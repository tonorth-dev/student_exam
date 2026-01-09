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
    
    # 构建 Windows 应用并创建 MSIX 包
    flutter build windows --release
    flutter pub run msix:create
    
    # 使用 Inno Setup 创建安装程序
    # 注意：需要预先安装 Inno Setup
    echo "创建 Windows 安装程序..."
    
    # 创建 Inno Setup 脚本
    cat > installer.iss << EOF
#define MyAppName "红师教育学生端"
#define MyAppVersion "1.1.0"
#define MyAppPublisher "红师教育"
#define MyAppExeName "红师教育学生端.exe"

[Setup]
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=build
OutputBaseFilename=红师教育学生端_setup
Compression=lzma
SolidCompression=yes
SetupIconFile=assets\images\logo.png

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}";

[Files]
Source: "build\windows\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
EOF

    # 编译安装程序
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
    
    echo "Windows 安装程序已生成: build/红师教育学生端_setup.exe"
else
    echo "不支持的操作系统"
    exit 1
fi

echo "构建完成！"
