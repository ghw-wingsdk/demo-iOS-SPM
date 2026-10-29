#!/bin/bash
# WADemo archive + exportArchive 打包脚本（SPM 版，自动签名，依赖 Xcode 已登录 Y8Z2D47ET4 账号）
# 用法: ./archive_export_ipa.sh [development|distribution]
#   development  -> 开发签名，发给注册过 UDID 的测试者
#   distribution -> 企业分发（in-house），任何设备可装
set -e

METHOD="${1:-development}"
TEAM_ID="Y8Z2D47ET4"

PROJ_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$PROJ_DIR")"
OUT_DIR="$ROOT_DIR/ipa"

case "$METHOD" in
    development)
        METHOD_NAME="development"
        ;;
    distribution)
        METHOD_NAME="in-house"
        ;;
    *)
        echo "未知导出方式: $METHOD（支持 development / distribution）"
        exit 1
        ;;
esac

TS=$(date +%Y%m%d_%H%M)
IPA_NAME="WADemo_spm_${METHOD}_${TS}.ipa"
ARCHIVE_PATH="/tmp/wademo_spm_archive/WADemo.xcarchive"
TMP_DIR="/tmp/wademo_spm_archive"

echo "== 1. archive 中（自动签名，Team=$TEAM_ID）..."
cd "$PROJ_DIR"
rm -rf "$ARCHIVE_PATH"
xcodebuild -project WADemo.xcodeproj -scheme WADemo \
    -configuration Release -sdk iphoneos \
    -archivePath "$ARCHIVE_PATH" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    -allowProvisioningUpdates archive

echo "== 2. 生成 exportOptions（自动签名）..."
EXPORT_OPTIONS="$TMP_DIR/exportOptions.plist"
mkdir -p "$TMP_DIR"
cat > "$EXPORT_OPTIONS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>$METHOD_NAME</string>
	<key>teamID</key>
	<string>$TEAM_ID</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>stripSwiftSymbols</key>
	<true/>
	<key>compileBitcode</key>
	<false/>
</dict>
</plist>
EOF

echo "== 3. exportArchive 中（method=$METHOD_NAME）..."
EXPORT_DIR="$TMP_DIR/export"
rm -rf "$EXPORT_DIR"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "$EXPORT_DIR" \
    -allowProvisioningUpdates

echo "== 4. 输出 ipa..."
mkdir -p "$OUT_DIR"
IPA_FILE=$(find "$EXPORT_DIR" -name "*.ipa" | head -n 1)
if [ -z "$IPA_FILE" ]; then
    echo "错误: 未找到导出的 ipa，请检查签名/描述文件配置"
    exit 1
fi
mv "$IPA_FILE" "$OUT_DIR/$IPA_NAME"

echo "== 完成: $OUT_DIR/$IPA_NAME"
