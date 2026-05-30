#!/bin/bash

set -e

echo "🚀 开始构建 CleanMyMac 风格清理工具..."

# 配置
APP_NAME="CleanMyMac"
BUNDLE_ID="com.cleanmymac.app"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# 清理旧的构建
echo "🧹 清理旧构建..."
rm -rf "$BUILD_DIR/$APP_NAME.app"

# 创建 .app 目录结构
echo "📁 创建应用目录结构..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 编译 Swift 代码
echo "⚙️  编译 Swift 代码..."
swiftc -O \
    -target arm64-apple-macos13.0 \
    -framework Cocoa \
    -framework Foundation \
    -o "$MACOS_DIR/$APP_NAME" \
    CleanMyMac/Models.swift \
    CleanMyMac/Scanner.swift \
    CleanMyMac/main.swift

if [ $? -ne 0 ]; then
    echo "❌ 编译失败"
    exit 1
fi

echo "✅ 编译完成"

# 创建 Info.plist
echo "📝 创建 Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CleanMyMac</string>
    <key>CFBundleIdentifier</key>
    <string>com.cleanmymac.app</string>
    <key>CFBundleName</key>
    <string>CleanMyMac</string>
    <key>CFBundleDisplayName</key>
    <string>CleanMyMac</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

# 创建 PkgInfo
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

# 设置可执行权限
chmod +x "$MACOS_DIR/$APP_NAME"

# 尝试代码签名
echo "🔐 尝试代码签名..."
if codesign --force --deep --sign - "$APP_DIR" 2>/dev/null; then
    echo "✅ 代码签名成功"
else
    echo "⚠️  代码签名失败（应用仍可运行）"
fi

echo ""
echo "✨ 构建完成！"
echo "📦 应用位置: $APP_DIR"
echo ""
echo "运行方式："
echo "  双击打开: open \"$APP_DIR\""
echo ""
echo "功能特性："
echo "  ✅ 系统垃圾扫描"
echo "  ✅ 用户缓存清理"
echo "  ✅ 应用缓存清理"
echo "  ✅ 日志文件清理"
echo "  ✅ 废纸篓管理"
echo "  ✅ 大文件查找"
echo "  ✅ 旧文件查找"
echo "  ✅ 下载文件管理"
echo "  ✅ 开发者垃圾清理"
echo ""
echo "或者直接运行："
open "$APP_DIR"
