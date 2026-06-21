---
name: batch-english-learning-card-maker
description: >-
  批量生成可下载的儿童英语学习图片卡片和主题课程包，输出 PNG/JPG、预览页、manifest 和 ZIP 包，包含英文短句、英文单词、单词+例句组合卡、多句组合学习页，并为每条内容附上 IPA 音标和中文意思。
  内置已审核动物插画，支持素材指纹校验、错图拦截、生成前预检、边缘截断风险检测和自适应排版。
  默认生成 download.html、互动学习页、今日学习单、家长进度页、复习安排、小白使用说明和下一包建议，适合家长、老师和儿童英语启蒙资料制作者直接下载使用。
  Use when Codex needs to create many portrait PNG/JPG children's English learning posters, 儿童英语卡片, 英语单词卡, 英文短句卡, 幼儿英语启蒙图, 学前班英语, 一年级英语, 多句组合学习页,
  Duolingo-style lesson cards, watercolor children's-book backgrounds, central readable typography, translations, preview pages, manifests,
  国内课标, 国际英语分级, Cambridge Starters/Movers/Flyers, CEFR Pre-A1/A1/A2, preschool, kindergarten, grade 1, grade 2, or 3-12 year-old children's English.
---

# 儿童英语学习卡片批量生成器

这个 skill 用来批量生成干净、适合小朋友观看的英语学习图片卡。

它可以生成：

- 英文单词卡
- 英文短句卡
- 单词 + 例句组合卡
- 多句组合学习页
- 一课一练课程包
- 7天学习包和每日打卡计划
- 互动练习页、自然拼读包、学习记录表
- 可下载免费学习包、小白使用说明、复习安排和下一包推荐
- 缺素材提示词包、练习答案表、家长每日 HTML 指南
- 按年龄、年级、国内课标、国际分级自动匹配内容
- 完整学习包、正式完整包、主题推荐、方案预览、严格素材校验、练习图片、难度递进、打印拼版、zip 打包和质量等级检查
- 常用学习预设、严格音标模式、严格内容数量检查和重复内容报告
- 可独立复制使用的内置正式动物素材库、素材指纹校验、生成前预检和边缘截断风险检查
- 内容准确性审计、个性化学习路径和基于掌握度的间隔复习

每张卡必须包含：

- 英文
- IPA 音标
- 中文意思
- 清晰的图片提示或儿童插画区域

## 默认交付规则

当用户说“生成卡片”“生成学习包”“批量生成”“给我卡片”“直接可下载”时，默认必须生成真实文件，而不是只在聊天中列内容表格。

默认交付应包含：

- PNG 图片卡片
- `download.html` 下载入口页
- `lesson-player.html` 孩子互动学习页
- `today-learning-sheet.html` 今日学习单，告诉家长今天先学哪几张、怎么提问
- `parent-dashboard.html` 家长进度页
- `review-plan.html` 家长复习安排
- `usage-guide.txt` 小白使用说明
- `next-pack-suggestion.txt` 下一套学习包建议
- `parent-guide-card.png` 家长说明卡，一张图说明怎么带孩子学
- `parent-use-pack.zip` 家长使用包，只放普通家长会直接打开的学习、打印、复习和说明文件
- `preview.html` 预览页
- `manifest.csv` 内容清单
- `quality-report.csv` 质量报告
- `content-gap-report.csv` 内容缺口报告，汇总缺图、数量不足和质量复查建议
- `creator-next-actions.txt` 制作者下一步建议，告诉制作者先补素材、补内容还是复查图片
- `english-learning-pack.zip` 下载包

所有面向用户下载的 CSV 必须使用 Excel 直接可识别的 UTF-8 BOM 编码，避免 Windows Excel 双击打开后中文乱码。CSV 或 HTML 里凡是给家长、老师、普通用户看的字段名和字段值都要中文化：

- 表头使用 `文件`、`类型`、`英文`、`音标`、`中文意思`、`状态`、`说明` 等中文，不要直接暴露 `file`、`type`、`english`、`status` 等内部字段名。
- 类型值使用 `单词卡`、`短句卡`、`单词+短句卡`、`多句学习页`，不要直接显示 `word`、`sentence`、`combo`、`lesson`。
- `status`、`edge_status`、`generation_status` 等状态字段必须显示中文，例如 `已完成`、`已减少（不重复凑数）`、`通过`、`需要检查`，不要直接暴露 `fulfilled`、`reduced-no-repeat`、`pass` 这类内部状态码。
- 下载入口页的“关键文件”必须说明用途，例如“质量报告：检查英文、音标、中文、排版和问题项”，不要只列技术文件名。
- 下载入口页必须优先展示“我要给孩子看、今天学什么、我要打印、我要复习、下一套学什么”等中文操作入口。质检 CSV、素材检查 CSV 和完整清单放入“高级检查文件”，不要作为普通用户第一眼看到的主入口。

除非用户明确说“先预览方案”“先列内容”“只要表格”“不生成图片”，否则不要把 Markdown 表格当作最终交付。可以先简单说明正在生成，但最终回复必须给出输出文件夹、`download.html`、`parent-use-pack.zip`、`lesson-player.html`、`today-learning-sheet.html`、`parent-dashboard.html`、`review-plan.html` 和 ZIP 路径。

如果当前运行环境不能写文件、不能执行脚本或不能提供附件下载，要明确说明限制，并给出可复制执行的命令；不要声称已经生成可下载卡片。

## 快速使用

想直接生成，可以这样说：

```text
使用 batch-english-learning-card-maker，生成一年级英语学习卡：20张单词卡 + 10张短句卡 + 2张多句组合页，并打包成可下载 ZIP。
```

```text
使用 batch-english-learning-card-maker，按 Pre-A1 生成动物主题英语启蒙卡，自动分配数量。
```

```text
使用 batch-english-learning-card-maker，生成学前班英语启蒙卡：50张单词卡，每张都有英文、音标、中文意思和图片提示。
```

```text
使用 batch-english-learning-card-maker，生成一年级教室主题课程包，自动配好单词卡、短句卡、组合卡、学习页和家长说明。
```

```text
使用 batch-english-learning-card-maker，一键生成一年级动物主题课程包，附带A4打印拼版和质量检查。
```

```text
使用 batch-english-learning-card-maker，先预览一年级动物主题生成方案，不生成图片。
```

```text
使用 batch-english-learning-card-maker，生成学前班食物主题7天学习包，适合家长每天带读。
```

```text
使用 batch-english-learning-card-maker，生成一年级动物主题学习卡，并附带互动练习、自然拼读和学习记录表。
```

```text
使用 batch-english-learning-card-maker，生成一年级动物主题完整学习包，包含课程包、7天计划、互动练习、自然拼读、学习记录、A4打印和质量检查。
```

```text
使用 batch-english-learning-card-maker，按 grade1-weather 预设一键生成免费英语学习包。
```

```text
使用 batch-english-learning-card-maker，生成正式版一年级动物主题完整学习包，缺素材就停止并列出缺失清单。
```

```text
使用 batch-english-learning-card-maker，按一年级动物预设生成，音标只使用已整理内容，不要重复短句。
```

更多复制即用的提示词，读取：

- [references/prompt-examples.md](references/prompt-examples.md)

## 小白优先工作流

如果用户只说年龄、年级、主题或“帮我生成”，不要先要求用户理解参数。先按以下顺序自动处理：

1. 判断年龄、年级、国内或国际分级。
2. 判断主题，例如动物、教室、家庭、食物、天气、打扫房间。
3. 如果用户没有给数量，使用自动数量，并默认生成图片文件。
4. 如果用户要打印或给孩子正式学习，使用正式版素材流程。
5. 如果用户不确定主题，先输出推荐主题。
6. 如果用户不确定数量，先生成方案预览，再正式生成。
7. 生成后检查英文、音标、中文、配图含义、文字大小和多句页行距。
8. 正式学习内容优先使用严格音标模式，不使用模板拼接的句子音标。
9. 不要为了满足数量重复短句；内容不足时减少输出，严格模式下直接报告不足。
10. 最终回复提供 `download.html`、`lesson-player.html`、`today-learning-sheet.html`、`parent-dashboard.html`、`english-learning-pack.zip`、`preview.html` 和输出目录；不要只回复表格。
11. 面向普通家长时优先发送 `parent-use-pack.zip`，完整检查包 `english-learning-pack.zip` 只作为备查或给制作者复核。

## 一键预设

当用户说“按年龄生成”“按年级生成”“不知道怎么选”“免费给家长用”“直接生成一套”时，优先使用内置预设。预设会自动开启完整学习包、ZIP 打包、互动学习页、今日学习单、家长进度页、复习安排和下一包建议。

推荐预设：

| 预设 | 适合用户 | 主题 |
| --- | --- | --- |
| `preschool-animals` | 3-5岁 / 幼儿启蒙 | 动物 |
| `preschool-breakfast` | 3-5岁 / 亲子日常 | 早餐 |
| `preschool-family` | 3-5岁 / 家庭场景 | 家庭 |
| `preschool-bedtime` | 3-5岁 / 睡前启蒙 | 睡前 |
| `kindergarten-animals` | 学前班 / 5-6岁 | 动物 |
| `kindergarten-classroom` | 学前班 / 入学准备 | 教室 |
| `kindergarten-breakfast` | 学前班 / 日常表达 | 早餐 |
| `kindergarten-family` | 学前班 / 家庭表达 | 家庭 |
| `grade1-classroom` | 一年级 / 6-7岁 | 教室 |
| `grade1-animals` | 一年级 / 6-7岁 | 动物 |
| `grade1-breakfast` | 一年级 / 6-7岁 | 早餐 |
| `grade1-family` | 一年级 / 6-7岁 | 家庭 |
| `grade1-weather` | 一年级 / 6-7岁 | 天气 |
| `grade1-park` | 一年级 / 6-7岁 | 公园 |
| `grade1-cleaning` | 一年级 / 生活场景 | 打扫房间 |
| `grade2-classroom` | 二年级 / 7-8岁 | 教室 |
| `grade2-animals` | 二年级 / 7-8岁 | 动物 |
| `grade2-weather` | 二年级 / 7-8岁 | 天气 |
| `prea1-animals` | Cambridge Starters / Pre-A1 | 动物 |
| `prea1-daily` | Cambridge Starters / Pre-A1 | 日常家庭 |

示例命令：

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -Preset grade1-weather -OutputDir .\output\grade1-weather-pack
```

保留旧预设 `preschool-daily`，用于兼容之前的调用。

遇到小白用户、模糊需求、年龄段/年级需求、配图准确性需求时，读取：

- [references/user-friendly-workflow.md](references/user-friendly-workflow.md)

## 内容选择规则

当用户说明年龄、年级、阶段或分级时，先选择合适内容，再生成图片。

| 用户说法 | 对应处理 |
| --- | --- |
| `3-5岁`、`幼儿园` | 使用幼儿启蒙内容，文字少，图片大 |
| `学前班`、`5-6岁` | 使用学前英语内容，单词和简单短句为主 |
| `一年级`、`6-7岁` | 使用一年级内容，单词 + 短句 + 简单学习页 |
| `二年级`、`7-8岁` | 增加短句和主题表达 |
| `三年级`、`8-9岁` | 增加多句组合页和主题复习 |
| `小学高年级`、`9-12岁` | 增加阅读式句子和主题学习页 |

需要加载的参考文件：

- 年龄/年级短句库：读取 [references/graded-library.md](references/graded-library.md)
- 每阶段 100 个单词库：读取 [references/graded-word-bank-100.md](references/graded-word-bank-100.md)
- 国内/国际分级：读取 [references/level-systems.md](references/level-systems.md)
- 主题课程包：读取 [references/theme-lesson-packs.md](references/theme-lesson-packs.md)
- 视觉和排版规则：读取 [references/visual-templates.md](references/visual-templates.md)
- 小白操作和痛点优化：读取 [references/user-friendly-workflow.md](references/user-friendly-workflow.md)
- 正式素材库规则：读取 [references/asset-library.md](references/asset-library.md)
- 长期课程化方向：读取 [references/sustainable-roadmap.md](references/sustainable-roadmap.md)
- 互动练习、自然拼读和学习记录：读取 [references/activity-phonics-publishing.md](references/activity-phonics-publishing.md)
- 内容审计、每日学习路径和复习计划：读取 [references/adaptive-learning.md](references/adaptive-learning.md)

如果用户指定主题，优先使用主题课程包。主题内容不够时，再用同阶段词库或短句库补齐。

## 国内和国际分级

支持两套分级方式。

| 体系 | 用户可能会说 | 处理方式 |
| --- | --- | --- |
| 国内分级 | `国内一年级`、`一二年级`、`课标一级`、`课标二级` | 映射到适合的小学阶段内容 |
| 国际分级 | `Pre-A1`、`A1`、`A2`、`Starters`、`Movers`、`Flyers` | 映射到适合的国际英语启蒙内容 |

规则：

- 如果用户说国内年级或课标，使用 `system=domestic`。
- 如果用户说 CEFR、Cambridge、Starters、Movers、Flyers，使用 `system=international`。
- 如果用户只说年龄或年级，自动选择最接近的阶段。
- 最终图片里不要显示内部代码，例如 `cleaning-room`、`grade-1-6-7`。
- 给中文用户看的图片，标题和辅助文字使用中文，例如 `复习`、`跟读`、`打扫房间`。

## 支持的卡片类型

| 类型 | 用途 | 内容 |
| --- | --- | --- |
| `english-word-card` | 单词学习 | 单词、音标、中文意思、图片提示、可选例句 |
| `english-sentence-card` | 短句跟读 | 英文短句、音标、中文意思 |
| `word-sentence-combo-card` | 单词 + 场景句 | 一个单词 + 一个匹配短句 |
| `lesson-phrase-list-card` | 多句组合学习页 | 一个主题下的 4-8 组英文短句和中文意思 |
| `mixed-review-card` | 复习页 | 同主题的多个单词和短句 |

## 课程包模式

当用户说“课程包”“一课一练”“一整套”“直接给孩子学”“主题一键生成”时，优先使用课程包模式。

课程包会包含：

- 单词卡：先认识新词
- 短句卡：练习跟读
- 组合卡：把单词放进句子
- 多句组合页：集中学习一个主题
- `course-plan.csv`：课程顺序清单
- `parent-guide.txt`：中文家长使用说明
- `quality-report.csv`：字段完整性和预览检查提示
- 可选 `print-a4.html`：A4 打印拼版

脚本参数：

```powershell
-CoursePack
```

主题一键生成可使用：

```powershell
-ThemePack
```

课程包默认会按阶段自动控制数量，避免一次内容太多。

默认学习顺序：

1. 单词卡：认识图片和新词
2. 短句卡：跟读日常表达
3. 组合卡：把单词放进句子
4. 多句学习页：集中学习一个主题
5. 家长说明：复习和陪读建议

## 方案预览和7天学习包

当用户不知道选什么主题，先输出推荐主题。

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -Stage grade-1-6-7 -RecommendThemesOnly
```

推荐主题会输出：

- `recommended-themes.csv`

当用户不确定要生成什么，或只说“帮我看看怎么生成”，先使用方案预览。

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -System domestic -Level domestic-grade-1-2 -Theme zoo-animals -Mode mixed -AutoCounts -PlanOnly
```

方案预览会输出：

- `generation-plan.csv`
- `generation-plan.txt`

当用户说“一周学习”“7天计划”“每日打卡”“亲子带读计划”时，开启 7 天学习包。

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -System domestic -Level domestic-grade-1-2 -Theme zoo-animals -CoursePack -SevenDayPack
```

7天学习包会额外输出：

- `seven-day-learning-plan.csv`
- `daily-parent-guide.html`

`seven-day-learning-plan.csv` 会细化到每天学哪些卡片文件、当天学习重点、家长提问方式和复习方式。`daily-parent-guide.html` 是更适合家长直接打开查看或打印的版本。

默认节奏：

1. 看图认单词
2. 音标和跟读
3. 短句输入
4. 单词放进句子
5. 主题学习页
6. 趣味复习
7. 小测和奖励

## 素材检查、互动练习和学习记录

正式生成前，如果用户担心“配图不准”或要求“正式版”，可以先做素材检查。

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -System domestic -Level domestic-grade-1-2 -Theme zoo-animals -Mode mixed -AutoCounts -AssetCheckOnly
```

素材检查会输出：

- `asset-check.csv`
- `asset-prompt-pack.txt`

`asset-prompt-pack.txt` 只列出缺失素材，并给出可复制到绘图工具的提示词、建议文件名和保存位置。

如果用户要求“不能缺图”“正式版不要错图”“缺素材就停止”，开启严格素材校验。

```powershell
-StrictAssets
```

严格素材校验会在缺少正式插画时停止生成，并输出：

- `missing-assets.csv`
- `missing-assets-prompts.txt`

`missing-assets.csv` 会列出缺少的英文单词、中文意思、素材分类、应放入的文件名、应显示的画面和可用于生成素材的提示词。`missing-assets-prompts.txt` 是给小白用户看的复制版素材补全清单。

如果用户要“更有趣”“像国外儿童英语产品”“练习页”“小测验”，开启互动练习包。

```powershell
-ActivityPack
```

互动练习包会输出：

- `activity-pack.csv`
- `activity-answer-key.csv`
- `activity-answer-key.html`

`activity-answer-key.html` 是家长核对答案用的清爽页面，避免用户打开 CSV 才能看答案。

如果用户要把互动练习也做成图片，开启练习图片。

```powershell
-ActivityImages
```

练习图片要求：

- “看图选单词”必须展示目标图片和英文选项。
- “看中文说英文”必须展示多张对应图片和中文提示。
- “中英连线”必须展示图片、中文和英文连线区域。
- 不能只显示答案文字，也不能把纯文字列表称为看图练习。

如果用户要“自然拼读”“phonics”“字母发音”“CVC”，开启自然拼读包。

```powershell
-PhonicsPack
```

如果用户要“打卡”“记录掌握情况”“复习表”，开启学习记录表。

```powershell
-LearningRecord
```

这些开关可以组合使用，例如：

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -System domestic -Level domestic-grade-1-2 -Theme zoo-animals -CoursePack -SevenDayPack -ActivityPack -PhonicsPack -LearningRecord
```

如果用户要“一次生成完整学习包”，优先使用：

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -System domestic -Level domestic-grade-1-2 -Theme zoo-animals -CompletePack
```

完整学习包会自动开启：

- 课程包
- 7天学习计划
- 互动练习
- 互动练习图片
- 自然拼读
- 学习记录
- A4 打印拼版
- zip 打包
- 输出摘要
- 家长每日 HTML 指南
- 互动练习答案表

如果用户要“正式版完整包”或“缺素材就停”，优先使用：

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -System domestic -Level domestic-grade-1-2 -Theme zoo-animals -FormalCompletePack
```

正式完整包会自动开启完整学习包、严格素材校验、严格内容数量检查和 `curated-only` 音标策略。缺少正式插画或已整理内容不足时停止并报告，不会用无关素材或重复短句凑数。

## 常用预设和严格内容模式

用户不想重复描述年龄、主题和输出类型时，可以使用内置预设：

| 预设 | 用途 |
| --- | --- |
| `preschool-daily` | 学前日常英语完整包 |
| `grade1-classroom` | 一年级教室主题完整包 |
| `grade1-animals` | 一年级动物主题完整包 |
| `prea1-animals` | Pre-A1 动物主题完整包 |

示例：

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -Preset grade1-animals
```

正式学习或发布时，优先使用：

```powershell
-PhoneticPolicy curated-only -StrictContent
```

- `curated-only`：只使用参考库中已整理的句子音标。
- `allow-generated`：内容不足时允许使用模板生成句子，适合草稿。
- `StrictContent`：数量不足时停止并报告，不重复句子凑数。

## 难度和视觉风格

可用 `-DifficultyMode` 控制句子难度。

| 参数 | 效果 |
| --- | --- |
| `auto` | 按年龄/年级自动选择 |
| `starter` | 更短、更适合启蒙 |
| `basic` | 简单完整句 |
| `challenge` | 轻微进阶，加入问句或更完整表达 |

可用 `-VisualStyle` 控制画面风格。

| 参数 | 效果 |
| --- | --- |
| `icon` | 更像干净图标卡，装饰少 |
| `storybook` | 默认儿童绘本感 |
| `watercolor` | 更柔和的水彩感 |

## 正式版和草稿版

当用户要“正式版”“打印给孩子看”“高质量配图”时，优先使用正式版素材流程。

| 模式 | 适合场景 | 配图方式 |
| --- | --- | --- |
| 草稿版 | 快速预览、测试排版 | 可用脚本内置简图 |
| 正式版 | 打印、发布、给孩子正式学习 | 必须使用 `assets/illustrations` 中的高质量素材或用户提供的素材 |

正式版推荐脚本：

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\render_asset_cards.ps1 -InputCsv .\input.csv -AssetDir .\assets\illustrations -OutputDir .\output\formal-cards
```

正式版输出：

- PNG/JPG 图片
- `manifest.csv`
- `visual-audit.csv`

`visual-audit.csv` 会记录素材路径、素材占比、字段缺失和是否需要复查。

正式版如果找不到匹配素材，不要用无关图标替代，应报告缺少素材并建议补充对应图片。

正式素材库建设规则见：

- [references/asset-library.md](references/asset-library.md)

已审核素材登记表：

- [references/verified-asset-registry.csv](references/verified-asset-registry.csv)

动物素材只有在文件名、审核状态和 SHA-256 文件指纹都与登记表一致时，才会被认定为正确正式配图。图片被替换或修改后会变成未审核状态，正式模式必须停止或排除该内容。

## 默认视觉风格

整体风格要干净、温柔、适合儿童。

推荐：

- 竖版画布，默认 `1080x1620`
- 柔和水彩儿童绘本风
- 暖奶油色、浅蓝、薄荷绿、桃橙、奶黄色、淡紫色
- 文字区域居中、干净、留白充足
- 装饰只放在边缘、角落或底部
- 英文和中文必须清楚可读

避免：

- 不要使用杂乱背景
- 不要使用霓虹色或过重边框
- 不要让背景干扰文字
- 不要让图片模型直接生成最终文字
- 不要模仿用户提供的参考图或具体 App 角色
- 不要使用和单词无关的装饰图标

## 图片提示规则

单词卡和组合卡的图片提示必须和英文单词对应。

生成前先为每个单词确定 `expected_visual`，生成后在 `quality-report.csv` 或 `visual-audit.csv` 中保留检查线索。

优先级：

1. 正式版优先使用 `assets/illustrations/{english}.png` 或用户提供的高质量素材。
2. 草稿版可以使用 `assets/icons/{english}.png` 或 `.jpg`。
3. 仅用于预览时，才允许使用内置语义图标。
4. 仍无法匹配时，不要生成正式卡，应报告缺少素材。
5. 默认禁止用同一张通用水果、动物脸、人物或概念图代表多个不同单词。
6. 只有用户明确要求快速草稿时，才允许使用 `-AllowApproximateVisuals`。
7. 动物类不允许使用内置简图作为正确配图，必须使用对应动物的独立完整插画。
8. 配图必须完整显示主体；耳朵、头部、脚、尾巴、翅膀、长颈、象鼻等任何关键部位都不能被裁切。

配图检查文件：

- `visual-coverage.csv`：逐条记录 `exact-asset`、`reliable-built-in`、`approximate-built-in` 或 `missing`。
- `visual-missing-prompts.txt`：存在缺图时，自动生成可用于补素材的绘图提示词。

默认处理：

- `exact-asset`：可以正式使用。
- `reliable-built-in`：可以用于草稿和基础学习卡，正式发布仍建议更换高质量插画。
- `approximate-built-in`：默认不使用；启用后必须人工检查。
- `missing`：页面明确显示“待补对应图片”，不能用错误图片替代。

默认批量生成时，缺少可靠配图的单词会从儿童学习卡中排除：

- `excluded-visuals.csv`：记录被排除的单词、中文意思和应显示画面。
- `excluded-visual-prompts.txt`：提供补充对应插画的提示词。

宁可减少生成数量，也不能使用错误图片凑数。补齐素材后再重新生成即可。

示例：

| 英文 | 应显示 |
| --- | --- |
| `cat` | 小猫图片 |
| `book` | 书本图片 |
| `pencil` | 铅笔图片 |
| `bag` | 书包图片 |
| `sun` | 太阳图片 |
| `apple` | 苹果图片 |

禁止：

- `book` 却显示水果或橘子形状
- `cat` 却显示通用圆形装饰
- 用误导性图案代替真实含义

动物主题额外要求：

- 每个动物必须绑定独立的 `{english}.png`、`.jpg`、`.jpeg` 或 `.webp` 素材。
- `cat` 必须有猫耳、胡须、爪子、尾巴等明显特征。
- `dog` 必须有狗耳、狗鼻口、尾巴等明显特征。
- `rabbit` 必须有长耳朵等明显特征。
- 动物类不要只画一个圆脸；正式输出必须使用完整半身或全身动物插画。
- 缺少独立动物素材时，必须排除该词并生成补图清单，不能回退到脚本简笔图。
- 动物配图占页面上方约 `25%-30%`，不要过大；下方必须保留足够空间放英文、音标、中文和例句。
- 生成动物卡时，优先生成或选择“无文字动物插画背景”，再本地叠加学习文字。
- 如果是批量生成动物、食物、交通工具、文具等具象内容，先准备素材库，再批量排版。
- 每张正式图都要在 `visual-audit.csv` 中记录素材文件和素材占比。

## 不得截断规则

- 图片主体四周必须保留安全留白，不得贴边或裁掉关键部位。
- 图片区、中文标签区、英文区和提示区必须使用独立布局空间，不能互相覆盖。
- 紧凑练习页应根据题目数量自动计算行高、图片高度和字号。
- 中文标签必须预留足够行高，文字基线不得靠近容器底边。
- 内容过长时优先减小字号、换行或增加区域高度，不允许直接裁切。
- 生成后必须人工抽查首张、末张、最长文本卡和最密集练习页。
- 每次生成自动输出 `asset-safety-report.csv`，检测素材边缘安全区是否存在内容。
- 正式素材边缘检查未通过时，不得继续作为正式版输出。

## 默认生成前预检

每次批量生成都会先输出：

- `preflight-report.csv`：汇总请求数量、可生成数量、会排除数量和待复查数量。
- `preflight-assets.csv`：逐词记录素材路径、审核状态、文件指纹结果、边缘安全状态和最终处理方式。
- `qa-dashboard.html`：中文可视化质检总览，可按卡片类型筛选或只查看问题图片。

预检发现动物素材未登记、文件被替换、缺少素材或图片贴边时，应先修复素材，再生成正式图片。

生成完成后优先打开 `qa-dashboard.html`。该页面集中展示质量通过数量、待复查数量、配图边缘安全情况和数量完成情况；互动练习页默认进入人工抽查列表，方便快速发现错图、截断或重叠。

同时查看 `content-gap-report.csv` 和 `creator-next-actions.txt`。前者用中文汇总缺少配图、数量不足、质量复查等问题；后者给制作者一个下一步清单，优先说明该补素材、补内容，还是先复查某些图片。给普通家长时不要优先发送这两个文件，把它们放在“高级检查文件”里。

生成给家长直接使用的学习包时，必须输出 `today-learning-sheet.html`。这个页面负责回答“今天到底学哪几张、家长怎么问孩子”，避免家长打开一整包图片后不知道从哪里开始。

## 趣味学习卡一致性规则

如果生成任务卡、问答卡、选择题卡、圈一圈卡、奖励页等趣味学习卡，必须先建立“词图绑定表”。

每个选项都要同时绑定：

- 英文
- IPA 音标
- 中文意思
- 图片类型
- 选项字母或题目位置

示例：

| 选项 | 英文 | 中文 | 图片 |
| --- | --- | --- | --- |
| A | `book` | 书 | 打开的书本 |
| B | `cat` | 猫 | 小猫 |
| C | `apple` | 苹果 | 苹果 |

要求：

- 题目问 `cat`，正确选项必须显示小猫图片。
- 干扰选项也必须准确，例如 `book` 必须显示书本，`apple` 必须显示苹果。
- 不允许用通用图形、临时占位图或相似但容易误解的图替代。
- 如果无法确定某个单词的图像，应换成更具体、更容易画准的单词。
- 生成后必须检查英文、中文、图片和选项位置是否一致。

## 排版规则

### 单词卡

布局：

```text
[对应图片]

book
/bʊk/
书

Open your book.
打开你的书。
```

要求：

- 英文单词最大
- 音标放在单词下面
- 中文意思放在音标下面
- 图片提示放在上方
- 例句比主单词小，但必须明显可读，不能像注释一样过小
- 例句区域使用自适应布局：短句自动放大，长句自动缩小并换行
- 单词、音标、中文意思、例句之间保留清晰间距，不能互相挤压

### 短句卡

布局：

```text
Good morning.
/ɡʊd ˈmɔːrnɪŋ/
早上好。
```

要求：

- 英文短句放在中上区域
- 音标紧跟英文
- 中文意思紧跟音标
- 短句要尽量放大，方便儿童跟读
- 长句自动缩小、换行，不能溢出

### 单词 + 短句组合卡

布局：

```text
[对应图片]

apple
/ˈæpəl/
苹果

I eat an apple.
我吃一个苹果。
```

要求：

- 一个单词搭配一个简单短句
- 图片、单词、句子必须语义一致
- 句子要短，适合儿童跟读

### 多句组合学习页

布局：

```text
打扫房间

1. Let's wipe the floor.
   我们来擦地板吧。

2. Can you get me the rag?
   你能帮我拿抹布吗？
```

要求：

- 每页放 4-8 组英文 + 中文
- 英文在上，中文在下
- 同一页只讲一个主题
- 行距自动适配，不要重叠
- 句子多时缩小底部装饰
- 不要为了凑数重复句子

## 数据要求

每条最终生成内容必须有：

- 英文
- IPA 音标
- 中文意思

如果缺少任何一项，不要生成最终卡片，应先报告缺失字段。

## 分级生成规则

按年龄或阶段生成时：

1. 先判断是否属于国内分级或国际分级。
2. 再映射到具体年龄/年级内容库。
3. 有主题时，优先使用主题课程包。
4. 生成单词卡时，优先使用每阶段 100 词词库。
5. 每个英文单词或短句都必须带音标。
6. 中文意思要自然，适合中文家长和孩子理解。
7. 低龄阶段多图片、少文字。
8. 高年级阶段增加短句和多句组合页。
9. 避免太难的语法、抽象词、俚语、考试化表达，除非用户明确要求。

## 批量生成脚本

快速批量生成时，使用：

- [scripts/generate_cards.ps1](scripts/generate_cards.ps1)

正式素材排版时，使用：

- [scripts/render_asset_cards.ps1](scripts/render_asset_cards.ps1)

生成后进行内容审计和个性化学习安排时，使用：

- [scripts/build_adaptive_learning_plan.ps1](scripts/build_adaptive_learning_plan.ps1)

示例：为 7 岁孩子安排每天 15 分钟、持续 7 天的学习和复习：

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\build_adaptive_learning_plan.ps1 -PackDir .\output\english-learning-cards -Age 7 -DailyMinutes 15 -Days 7
```

该脚本会根据 `learning-record.csv` 中的 `未学`、`半会`、`已会` 和复习日期动态排序，并输出 `content-audit.csv`、`review-queue.csv`、`personalized-learning-plan.csv` 与 `learner-summary.txt`。新学内容会自动安排第 1 天和第 3 天后的间隔复习。

示例 1：按一年级生成

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -Stage grade-1-6-7 -Mode mixed -Theme classroom -WordCount 20 -SentenceCount 10 -LessonCount 2 -ExportZip
```

示例 2：按国内一二年级自动生成

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -System domestic -Level domestic-grade-1-2 -Mode mixed -Theme classroom -AutoCounts -ExportZip
```

示例 3：按国际 Pre-A1 自动生成

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -System international -Level pre-a1 -Mode mixed -Theme zoo-animals -AutoCounts -ExportZip
```

示例 4：生成一整套课程包

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -System domestic -Level domestic-grade-1-2 -Theme classroom -CoursePack -ExportZip
```

示例 5：主题一键生成，并输出 A4 打印拼版

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -System domestic -Level domestic-grade-1-2 -Theme zoo-animals -ThemePack -PrintLayout -CardsPerPrintPage 4
```

示例 6：生成进阶短句和水彩风格

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -System international -Level a1 -Theme weather -CoursePack -DifficultyMode challenge -VisualStyle watercolor
```

脚本会生成：

- PNG 图片
- 互动练习 PNG 图片，开启练习图片时
- `manifest.csv`
- `download.html`
- `lesson-player.html`
- `parent-dashboard.html`
- `preview.html`
- `quality-report.csv`
- `visual-coverage.csv`
- `preflight-report.csv`
- `preflight-assets.csv`
- `asset-safety-report.csv`
- `qa-dashboard.html`
- `visual-missing-prompts.txt`，仅在仍有缺图时生成
- `excluded-visuals.csv` 和 `excluded-visual-prompts.txt`，仅在缺图词被排除时生成
- `duplicate-report.csv`
- `fulfillment-report.csv`
- `recommended-themes.csv`
- `bundle-summary.txt`
- 开启课程包时，还会生成 `course-plan.csv` 和 `parent-guide.txt`
- 开启打印拼版时，还会生成 `print-a4.html`
- 开启 zip 打包时，还会生成 `english-learning-pack.zip`

正式版 `render_asset_cards.ps1` 的输入 CSV 示例：

```csv
type,english,phonetic,meaning,example,example_meaning,asset
word,cat,/kæt/,猫,It is a cat.,这是一只猫。,cat.png
sentence,The dog is happy.,/ðə dɔːɡ ɪz ˈhæpi/,小狗很开心。,跟读 3 遍,,dog.png
lesson,animals,,动物短句组合,,,,animals.png
```

默认输出目录：

```text
output/english-learning-cards
```

## 文件命名规则

| 卡片类型 | 文件名示例 |
| --- | --- |
| 单词卡 | `word-apple.png` |
| 短句卡 | `sentence-good-morning.png` |
| 组合卡 | `combo-apple.png` |
| 学习页 | `lesson-cleaning-the-floor-01.png` |

## 输出清单字段

`manifest.csv` 尽量包含：

```csv
type,system,level,stage,theme,skill,difficulty,source,phonetic_source,english,phonetic,meaning,file
```

这些字段方便后续筛选：

- `system`：国内、国际或自动
- `level`：学习等级
- `stage`：实际使用的年龄/年级库
- `theme`：主题
- `difficulty`：难度
- `source`：内容来源
- `phonetic_source`：音标来源，正式输出应为 `curated-word` 或 `curated-bank`

`quality-report.csv` 包含质量等级：

| 等级 | 含义 |
| --- | --- |
| `A` | 字段完整 |
| `B` | 字段完整，但建议人工确认配图 |
| `C` | 需要检查排版或内容 |
| `D` | 缺少关键字段 |

`quality-report.csv` 还包含：

- `layout_score`：版式评分，越高越适合手机和打印。
- `readability`：阅读建议，例如“适合手机和打印”或“需要调整排版”。

`duplicate-report.csv` 用于检查同类型卡片是否出现重复英文。无重复时状态为 `pass`。

`fulfillment-report.csv` 对比每种卡片的请求数量和实际生成数量。内容不足且未开启严格模式时，状态会显示 `reduced-no-repeat`，表示已减少输出而没有重复凑数。

音标来源说明：

- `curated-word`：已整理的单词音标
- `curated-bank`：已整理的句子音标
- `generated-template`：模板生成音标，仅适合草稿检查
- `mixed-with-generated`：学习页包含模板生成内容

## 背景生成提示词

只生成无文字背景，不要让图片模型生成最终文字。

单词卡背景：

```text
soft watercolor children's vocabulary card background, objects related to "{english}" arranged around the edges, clean blank center for text, children's book illustration, cream paper texture, gentle pastel colors, no text, no letters, no watermark
```

短句卡背景：

```text
soft watercolor children's English learning poster background, warm friendly scene matching the sentence "{english}", decorative illustration around the edges, clean blank center for text, children's book style, cream paper texture, gentle pastel colors, no text, no letters, no watermark
```

推荐配色方向：

```text
warm cream blank center, mint green leaves, peach orange flowers, sky blue clouds, soft lavender stars, butter yellow accents, playful school objects around the edges, no text, no letters, no numbers, no watermark
```

## 生产流程

推荐流程：

1. 选择年龄、年级、分级或主题。
2. 从参考库中选择英文、音标、中文意思。
3. 准备无文字背景或使用脚本默认背景。
4. 用脚本本地渲染最终文字。
5. 检查文字、音标、中文意思和图片提示。
6. 导出 PNG/JPG、`download.html`、`lesson-player.html`、`parent-dashboard.html`、`manifest.csv`、`preview.html`。

## 完成前检查

完成前必须确认：

- 每张卡都有英文
- 每条英文都有音标
- 每张卡都有中文意思
- 图片提示和单词含义一致
- `visual-coverage.csv` 中没有未处理的 `missing` 或 `approximate-built-in`
- `preflight-report.csv` 没有未处理的 `reduced`、`missing` 或 `needs-review`
- `asset-safety-report.csv` 中所有正式素材均为 `safe`
- 打开 `qa-dashboard.html`，使用“只看问题”检查所有待复查图片和互动练习页
- 检查 `excluded-visuals.csv`，确认是否需要补图后重新生成
- 文字没有被裁切
- 动物图片主体完整，没有任何关键身体部位被裁切
- 中文标签、英文、音标和底部提示均位于各自安全区内
- 背景不影响阅读
- 多句学习页没有重叠
- 所有请求数量都已生成
- `manifest.csv` 和 `preview.html` 已生成
- `download.html` 已生成，并能作为给小白用户的第一入口
- `lesson-player.html` 已生成，并能用于点读和小测
- `parent-dashboard.html` 已生成，并能给家长查看今日学习和质量状态
- `quality-report.csv` 已生成并查看
- `content-audit.csv` 不包含未处理的 `blocked` 项
- 个性化学习任务已查看 `personalized-learning-plan.csv` 和 `review-queue.csv`
- `duplicate-report.csv` 显示无非预期重复
- `fulfillment-report.csv` 中请求数量与实际生成数量符合预期
- 正式输出的 `phonetic_source` 不包含 `generated-template`
- 如果需要打印，`print-a4.html` 已生成
- 如果使用课程包模式，`course-plan.csv` 和 `parent-guide.txt` 已生成
