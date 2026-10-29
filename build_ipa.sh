#!/bin/bash
# WADemo 自动打包脚本（SPM 版）
# 用法: ./build_ipa.sh [签名证书名|none]
#   不传参数默认由 xcodebuild 自动签名；传 none 则只构建不签名
set -e

CERT="${1:-auto}"
PROJ_DIR="$(cd "$(dirname "$0")" && pwd)"
DD="/tmp/wademo_spm_dd"
TS=$(date +%Y%m%d_%H%M)
IPA_NAME="WADemo_spm_${TS}.ipa"
OUT_DIR="/Users/lpw/Documents/gamehollywood/git/gitdemo/4.9.0/ipa"

echo "== 1. 构建中（Release，由 Xcode 自动签名）..."
cd "$PROJ_DIR"
if [ "$CERT" != "none" ]; then
    xcodebuild -project WADemo.xcodeproj -scheme WADemo \
        -configuration Release -sdk iphoneos \
        -derivedDataPath "$DD" \
        -allowProvisioningUpdates build
else
    xcodebuild -project WADemo.xcodeproj -scheme WADemo \
        -configuration Release -sdk iphoneos \
        -derivedDataPath "$DD" CODE_SIGNING_ALLOWED=NO build
fi

echo "== 2. 组装 Payload（直接使用 xcodebuild 签名产物，不做重签）..."
APP="$DD/Build/Products/Release-iphoneos/WADemo.app"
rm -rf "$DD/Payload"
mkdir -p "$DD/Payload"
ditto "$APP" "$DD/Payload/WADemo.app"

echo "== 3. 压缩 ipa..."
mkdir -p "$OUT_DIR"
rm -f "$DD/WADemo.ipa"
(cd "$DD" && zip -qry WADemo.ipa Payload)
mv "$DD/WADemo.ipa" "$OUT_DIR/$IPA_NAME"

echo "== 完成: $OUT_DIR/$IPA_NAME"
