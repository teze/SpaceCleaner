#!/bin/bash

APP_PATH="build/SpaceLens.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ 应用未找到，正在构建..."
    ./build-spacelens.sh
fi

echo "🚀 启动 Space Lens..."
open "$APP_PATH"
