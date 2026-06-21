# 安装说明

这个仓库提供的是同一个 Skill 文件夹，Codex 可以安装使用，支持自定义 Skills 的 Claude / Claude Code 也可以导入使用。

## Skill 文件夹

需要安装的是这个文件夹：

```text
skills/batch-english-learning-card-maker
```

## 安装到 Codex

1. 下载这个仓库，或下载 Release 里的 ZIP。
2. 复制这个 Skill 文件夹：

```text
skills/batch-english-learning-card-maker
```

3. 放到 Codex 的 skills 目录。常见位置：

```text
Windows: C:\Users\<你的用户名>\.codex\skills\batch-english-learning-card-maker
macOS/Linux: ~/.codex/skills/batch-english-learning-card-maker
```

4. 如有需要，重启 Codex。
5. 对 Codex 说：

```text
使用 batch-english-learning-card-maker，生成一年级天气主题英语学习包。
```

## 安装到 Claude / Claude Code

1. 下载这个仓库，或下载 Release 里的 ZIP。
2. 使用同一个 Skill 文件夹：

```text
skills/batch-english-learning-card-maker
```

3. 把它导入或复制到你的 Claude / Claude Code 自定义 Skills 工作区。
4. 如果你的 Claude 环境需要刷新或重启，重新加载一次。
5. 对 Claude 说：

```text
使用 batch-english-learning-card-maker，生成学前班动物主题英语学习包。
```

如果你的 Claude 环境要求上传 ZIP，而不是文件夹，可以把 `batch-english-learning-card-maker` 文件夹压缩成 ZIP 后作为自定义 Skill 导入。

## 不安装也能直接运行

也可以直接运行脚本：

```powershell
cd .\skills\batch-english-learning-card-maker
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -Preset grade1-weather -OutputDir .\output\grade1-weather-pack
```

