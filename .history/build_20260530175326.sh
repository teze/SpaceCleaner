#!/bin/bash

set -e

echo "🚀 开始构建 SpaceManager..."

# 配置
APP_NAME="SpaceManager"
BUNDLE_ID="com.spacemanager.app"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# 清理旧的构建
echo "🧹 清理旧构建..."
rm -rf "$BUILD_DIR"

# 创建 .app 目录结构
echo "📁 创建应用目录结构..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 编译 Swift 代码
echo "⚙️  编译 Swift 代码..."
swiftc -O \
    -target arm64-apple-macos13.0 \
    -sdk $(xcrun --show-sdk-path) \
    -F /System/Library/Frameworks \
    -framework SwiftUI \
    -framework Foundation \
    -framework AppKit \
    -o "$MACOS_DIR/$APP_NAME" \
    SpaceManager/SpaceManagerApp.swift \
    SpaceManager/ContentView.swift \
    SpaceManager/Models/FileItem.swift \
    SpaceManager/Services/FileScanner.swift \
    SpaceManager/Services/StorageAnalyzer.swift \
    SpaceManager/Views/SidebarView.swift \
    SpaceManager/Views/StorageView.swift

echo "✅ 编译完成"

# 创建 Info.plist
echo "📝 创建 Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SpaceManager</string>
    <key>CFBundleIdentifier</key>
    <string>com.spacemanager.app</string>
    <key>CFBundleName</key>
    <string>SpaceManager</string>
    <key>CFBundleDisplayName</key>
    <string>空间管理</string>
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

# 尝试代码签名（如果失败也继续）
echo "🔐 尝试代码签名..."
if codesign --force --deep --sign - "$APP_DIR" 2>/dev/null; then
    echo "✅ 代码签名成功"
else
    echo "⚠️  代码签名失败（应用仍可运行，但可能有安全警告）"
fi

echo ""
echo "✨ 构建完成！"
echo "📦 应用位置: $APP_DIR"
echo ""
echo "运行方式："
echo "  1. 双击打开: open $APP_DIR"
echo "  2. 命令行: ./$APP_DIR/Contents/MacOS/$APP_NAME"
echo ""
