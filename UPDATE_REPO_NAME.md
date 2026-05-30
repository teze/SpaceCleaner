# 更新 GitHub 仓库名指南

## 📝 步骤 1：在 GitHub 网站上修改仓库名

1. 打开浏览器访问：https://github.com/teze/CleanMyMac-macOS
2. 点击页面右上角的 **Settings**（设置）标签
3. 在 "General" 设置页面的顶部找到 "Repository name"
4. 将仓库名从 `CleanMyMac-macOS` 改为 `SpaceCleaner`
5. 点击 **Rename** 按钮
6. GitHub 会显示警告信息，确认后点击 "I understand, rename this repository"

## 🔄 步骤 2：更新本地 Git 远程地址

在 GitHub 上修改完成后，在本地项目目录运行以下命令：

```bash
# 更新远程仓库地址
git remote set-url origin https://github.com/teze/SpaceCleaner.git

# 验证更新是否成功
git remote -v

# 应该显示：
# origin  https://github.com/teze/SpaceCleaner.git (fetch)
# origin  https://github.com/teze/SpaceCleaner.git (push)
```

## ✅ 步骤 3：测试连接

```bash
# 拉取最新代码（测试连接）
git pull origin main

# 推送代码（测试连接）
git push origin main
```

## 📋 步骤 4：更新 README.md 中的链接

修改 README.md 中的仓库链接：

```markdown
# 旧链接
https://github.com/teze/CleanMyMac-macOS

# 新链接
https://github.com/teze/SpaceCleaner
```

## 🎯 推荐的新仓库名

**SpaceCleaner** ✅

优点：
- 简洁明了
- 国际化友好
- 与应用名称一致
- 避免商标问题
- 易于记忆和分享

## ⚠️ 注意事项

1. **旧链接会自动重定向**：GitHub 会自动将旧的 URL 重定向到新的 URL
2. **克隆的仓库需要更新**：如果其他地方克隆了这个仓库，也需要更新远程地址
3. **Issues 和 PR**：所有 Issues 和 Pull Requests 会自动迁移到新名称
4. **Stars 和 Forks**：不会丢失，会保留在新仓库名下

## 🔗 相关链接

- GitHub 官方文档：https://docs.github.com/en/repositories/creating-and-managing-repositories/renaming-a-repository
- 新仓库地址（修改后）：https://github.com/teze/SpaceCleaner

---

完成以上步骤后，仓库名就成功更新了！🎉
