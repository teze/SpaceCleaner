#!/bin/bash

APP_PATH="build/SpaceCleaner.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ 应用未找到，正在构建..."
    ./build-unified.sh
fi

echo "🚀 启动 SpaceCleaner..."
open "$APP_PATH"
