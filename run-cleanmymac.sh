#!/bin/bash

APP_PATH="build/CleanMyMac.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ 应用未找到，正在构建..."
    ./build-cleanmymac.sh
fi

echo "🚀 启动 CleanMyMac..."
open "$APP_PATH"
