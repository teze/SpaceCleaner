#!/bin/bash

# 更新 Git 远程仓库地址脚本
# 在 GitHub 网站上修改仓库名后运行此脚本

echo "🔄 更新 Git 远程仓库地址..."
echo ""

# 显示当前远程地址
echo "📍 当前远程地址："
git remote -v
echo ""

# 更新远程地址
echo "🔧 更新为新地址..."
git remote set-url origin https://github.com/teze/SpaceCleaner.git

# 验证更新
echo ""
echo "✅ 更新后的远程地址："
git remote -v
echo ""

# 测试连接
echo "🧪 测试连接..."
if git ls-remote origin &> /dev/null; then
    echo "✅ 连接成功！"
    echo ""
    echo "🎉 远程仓库地址已更新为："
    echo "   https://github.com/teze/SpaceCleaner"
else
    echo "❌ 连接失败！"
    echo ""
    echo "⚠️  请确保："
    echo "   1. 已在 GitHub 网站上修改了仓库名"
    echo "   2. 新仓库名为：SpaceCleaner"
    echo "   3. 网络连接正常"
fi

echo ""
echo "📝 下一步："
echo "   1. 更新 README.md 中的仓库链接"
echo "   2. 运行: git add README.md"
echo "   3. 运行: git commit -m '📝 更新仓库链接'"
echo "   4. 运行: git push origin main"
