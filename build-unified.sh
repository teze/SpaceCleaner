#!/bin/bash

set -e

echo "🚀 开始构建 CleanMyMac 统一版..."

# 配置
APP_NAME="CleanMyMac"
BUNDLE_ID="com.cleanmymac.unified"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# 清理旧的构建
echo "🧹 清理旧构建..."
rm -rf "$APP_DIR"

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
    CleanMyMacUnified/Models.swift \
    CleanMyMacUnified/Scanner.swift \
    CleanMyMacUnified/SpaceLensModels.swift \
    CleanMyMacUnified/SpaceLensScanner.swift \
    CleanMyMacUnified/Treemap.swift \
    CleanMyMacUnified/TreemapView.swift \
    CleanMyMacUnified/FolderSelectionMixin.swift \
    CleanMyMacUnified/ViewControllers.swift \
    CleanMyMacUnified/main.swift

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
    <string>com.cleanmymac.unified</string>
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
echo "🎯 统一版功能："
echo "  ✅ 智能扫描 - 一键扫描所有类别"
echo "  ✅ Space Lens - 树状图可视化"
echo "  ✅ 系统垃圾 - 清理系统缓存"
echo "  ✅ 大文件 - 查找大文件"
echo "  ✅ 旧文件 - 查找旧文件"
echo "  ⏳ 应用卸载 - 即将推出"
echo "  ⏳ 隐私清理 - 即将推出"
echo ""
echo "运行方式："
echo "  双击打开: open \"$APP_DIR\""
echo ""
open "$APP_DIR"
