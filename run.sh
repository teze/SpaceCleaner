#!/bin/bash

# 快速启动脚本

APP_PATH="build/空间管理.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ 应用未找到，正在构建..."
    ./build-simple.sh
fi

echo "🚀 启动空间管理工具..."
open "$APP_PATH"
