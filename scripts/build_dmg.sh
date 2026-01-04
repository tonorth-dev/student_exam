#!/bin/bash

# ===============================================================================
# Flutter DMG 终极构建脚本 - 签名 & 公证增强版
# ===============================================================================

set -e

# --- 配置区域 (已根据你的信息预填) ---
CERT_NAME="Developer ID Application: Beijing Hengxin Yunchuang Technology Co., Ltd (GU5KP26YVC)"
APPLE_ID="953409121@qq.com"
TEAM_ID="GU5KP26YVC"
# 请在此处填写你在 appleid.apple.com 生成的 16 位专用密码 (格式: xxxx-xxxx-xxxx-xxxx)
APP_SPECIFIC_PASSWORD="fnzw-qfow-yssw-xpzi"
# ------------------------------------

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# 参数解析
BUILD_TYPE="release"
CLEAN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type) BUILD_TYPE="$2"; shift 2 ;;
        -c|--clean) CLEAN=true; shift ;;
        *) shift ;;
    esac
done

# 1. 环境准备
if [ "$CLEAN" = true ]; then
    print_info "执行 flutter clean..."
    flutter clean
fi
flutter pub get

# 2. 执行构建
print_info "开始构建 $BUILD_TYPE 版本..."
BUILD_CMD="flutter build macos"
[ "$BUILD_TYPE" == "release" ] && BUILD_CMD="$BUILD_CMD --release --obfuscate --split-debug-info=build/symbols"
eval $BUILD_CMD

# 3. 定位产物
BUILD_TYPE_CAP=$(echo "${BUILD_TYPE:0:1}" | tr '[:lower:]' '[:upper:]')${BUILD_TYPE:1}
APP_PATH=$(ls -d build/macos/Build/Products/${BUILD_TYPE_CAP}/*.app | head -1)
APP_NAME=$(basename "$APP_PATH")
BASE_NAME="${APP_NAME%.app}"
DMG_PATH="build/${BASE_NAME}-${BUILD_TYPE}.dmg"

# 4. 代码签名 (.app)
print_info "正在进行代码签名: $APP_NAME"
# 这里的 --options runtime 是开启 Hardened Runtime，公证必备
codesign --deep --force --options runtime --sign "$CERT_NAME" "$APP_PATH"

# 5. 创建 DMG
print_info "正在打包 DMG..."
[ -f "$DMG_PATH" ] && rm "$DMG_PATH"
TEMP_DIR=$(mktemp -d)
cp -R "$APP_PATH" "$TEMP_DIR/"
# 修复权限防止“已损坏”报错
chmod -R 755 "$TEMP_DIR/$APP_NAME"

hdiutil create -volname "$BASE_NAME" -srcfolder "$TEMP_DIR" -ov -format UDZO "$DMG_PATH"
rm -rf "$TEMP_DIR"

# 6. 对 DMG 签名
print_info "正在为 DMG 文件签名..."
codesign --force --sign "$CERT_NAME" "$DMG_PATH"

# 7. 提交 Apple 公证 (核心步骤：解决“文件损坏”的关键)
print_info "正在向 Apple 提交公证，请稍候 (这取决于网络，通常 1-3 分钟)..."
# 使用 notarytool 提交并同步等待结果
xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$APP_SPECIFIC_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait

# 8. 钉住票据 (Staple)
# 公证成功后，将结果附加到 DMG 上，用户离线也能打开
print_info "正在将公证票据钉住到 DMG..."
xcrun stapler staple "$DMG_PATH"

echo "--------------------------------------------------"
print_success "恭喜！构建、签名与公证全部完成。"
print_info "生成的 DMG: $DMG_PATH"
print_info "现在你可以将此文件分发给任何 Mac 用户，不再会有‘文件损坏’提示。"