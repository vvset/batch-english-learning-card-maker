# 儿童英语学习卡片批量生成器

**[English](README.md) | 简体中文 | [安装说明](INSTALL.zh-CN.md) | [语言切换页](index.html)**

Batch English Learning Card Maker 是一个 Codex 和 Claude 都可使用的 Skill 包，用来批量生成儿童英语学习资料。它可以输出可下载的竖版 PNG 卡片、主题学习页、互动学习页、家长说明、复习计划、质量报告和 ZIP 学习包。

同一个 `skills/batch-english-learning-card-maker` 文件夹，可以安装到 Codex，也可以导入到支持自定义 Skills 的 Claude / Claude Code 环境中。

这个 Skill 适合中文家长、老师、儿童英语资料制作者使用，尤其适合生成幼儿园、学前班、一年级、二年级、Pre-A1、A1、A2 或 Cambridge 儿童英语风格的学习卡。

## 支持平台

| 平台 | 是否支持 | 使用方式 |
| --- | --- | --- |
| Codex | 支持 | 把 Skill 文件夹复制到 Codex 的 skills 目录，然后让 Codex 使用 `batch-english-learning-card-maker`。 |
| Claude / Claude Code | 支持自定义 Skills 时可用 | 把同一个 Skill 文件夹导入或复制到 Claude 的 skills 工作区，然后让 Claude 使用这个 Skill 生成学习包。 |

详细步骤看：[INSTALL.zh-CN.md](INSTALL.zh-CN.md)

## 可以生成什么

- 英语单词卡：英文、IPA 音标、中文意思、配图
- 英语短句卡：英文短句、IPA 音标、中文意思
- 单词 + 短句组合卡
- 多句组合学习页
- 今日学习单：告诉家长今天先学哪几张、怎么提问
- 孩子互动学习页：可点读、可做中文意思小测
- 家长进度页
- 复习安排
- A4 打印拼版
- 质量报告、配图检查表、内容缺口报告
- 家长使用包 ZIP 和完整检查包 ZIP

## 目录结构

```text
skills/batch-english-learning-card-maker/
  SKILL.md
  scripts/
  references/
  assets/

releases/
  batch-english-learning-card-maker-portable-20260621-no-share.zip
```

## 快速使用

进入 Skill 目录后运行：

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -Preset grade1-weather -OutputDir .\output\grade1-weather-pack
```

也可以直接这样对 Codex 或 Claude 说：

```text
使用 batch-english-learning-card-maker，生成一年级动物主题英语学习包，包含单词卡、短句卡、多句学习页、家长说明和可下载 ZIP。
```

## 生成后先打开哪个文件

生成完成后，先打开：

```text
download.html
```

如果要发给家长，优先发送：

```text
parent-use-pack.zip
```

如果你是制作者，要检查质量，查看：

```text
qa-dashboard.html
content-gap-report.csv
creator-next-actions.txt
quality-report.csv
visual-coverage.csv
```

## 特点

- 最终文字由本地脚本渲染，不依赖 AI 图片模型直接写字。
- 中文 CSV 使用 UTF-8 BOM，Windows Excel 双击打开不容易乱码。
- 家长使用包默认不混入技术报告。
- 动物正式素材会经过素材登记和边缘截断检查。
- 支持按年龄、年级、国内课标、国际分级、主题课程包自动选择内容。
