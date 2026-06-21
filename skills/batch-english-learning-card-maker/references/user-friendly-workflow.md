# User-Friendly Workflow

Use this reference when the user is vague, new to skills, or only gives an age, grade, theme, or rough learning goal.

## Pain-Point First Defaults

| User pain point | Default action |
| --- | --- |
| 用户不知道生成什么 | Use one-click age or grade recipes. Do not ask for script parameters first. |
| 用户不知道要多少张 | Use automatic counts from `level-systems.md`, unless the user gives exact counts. |
| 用户担心内容太难 | Prefer easier adjacent stage, shorter sentences, and more visual cards. |
| 用户担心配图不准 | Use formal asset workflow for final output and write expected visual cues into reports. |
| 用户要给小朋友直接看 | Use Chinese helper labels, large text, clear visual cue, and one learning point per card. |
| 用户要打印或正式学习 | Use formal assets, export preview, manifest, quality report, and print layout if requested. |
| 用户不确定方案 | Use `-PlanOnly` first and show generation counts before rendering. |
| 用户不知道选主题 | Use `-RecommendThemesOnly` and show the top 5 themes for the stage. |
| 用户想持续学习 | Use `-SevenDayPack` and create a daily parent-led review plan. |

## One-Click Recipes

### 3-5岁 / 幼儿园

- Goal: interest, listening, picture recognition.
- Default output: 20 word cards, 4 sentence cards, 8 combo cards, 1 lesson page.
- Themes: animals, colors, family, toys, fruit, body parts.
- Text rule: one word or one very short sentence.
- Visual rule: largest picture, minimal decoration.

### 学前班 / 5-6岁

- Goal: recognize common words and repeat simple expressions.
- Default output: 20 word cards, 6 sentence cards, 8 combo cards, 1 lesson page.
- Themes: classroom, animals, food, family, weather, bedtime.
- Text rule: short examples only.
- Visual rule: large picture with clear English, IPA, and Chinese.

### 一年级 / 6-7岁

- Goal: daily words, classroom language, simple oral sentences.
- Default output: 20 word cards, 10 sentence cards, 10 combo cards, 2 lesson pages.
- Themes: classroom, animals, food, family, school, weather.
- Text rule: word + IPA + Chinese + one short example where possible.
- Visual rule: balance picture and text.

### 二年级 / 7-8岁

- Goal: sentence patterns, likes, actions, locations, simple questions.
- Default output: 16 word cards, 12 sentence cards, 8 combo cards, 2 lesson pages.
- Themes: home, park, classroom, meals, weather, hobbies.
- Text rule: more short sentence practice.
- Visual rule: sentence blocks become more prominent.

### 三年级 / 8-9岁

- Goal: reusable topic expressions and simple dialogues.
- Default output: 12 word cards, 14 sentence cards, 6 combo cards, 3 lesson pages.
- Themes: routines, school day, shopping, park, family, animals.
- Text rule: include question-answer pairs when useful.
- Visual rule: app-like rows, less decoration.

### 小学中高年级 / 9-12岁

- Goal: reading sentences, descriptions, reasons, and topic review.
- Default output: 10 word cards, 16 sentence cards, 4 combo cards, 3 lesson pages.
- Themes: travel, environment, health, hobbies, daily routines, science.
- Text rule: longer but still speakable sentences.
- Visual rule: reading-card style with clean rows.

## Domestic and International Mapping

When the user mentions Chinese schooling, use domestic mapping:

- 幼儿园 / 幼儿英语 -> `domestic-preschool`
- 学前班 / 5-6岁 -> `domestic-preschool`
- 一年级 / 二年级 / 小学低年级 -> `domestic-grade-1-2`
- 三年级 / 四年级 / 课标一级 -> `domestic-grade-3-4`
- 五年级 / 六年级 / 课标二级 -> `domestic-grade-5-6`

When the user mentions international levels, use international mapping:

- Pre-A1 / Starters -> picture recognition and simple oral English.
- A1 / Movers -> sentence patterns, questions, actions, and locations.
- A2 / Flyers -> longer themed reading and review pages.

If the user gives both systems, prefer the one they name most explicitly. For example, `国内一年级 Pre-A1 风格` means domestic stage with Pre-A1 difficulty.

## Visual-Cue Rules

For every word or combo card, decide the expected visual before rendering:

```csv
english,meaning,expected_visual,avoid
book,书,打开或合上的书本,水果/圆形装饰/无关图标
cat,猫,有猫耳胡须尾巴的小猫,狗/熊/圆脸通用动物
dog,狗,有狗鼻口狗耳和尾巴的小狗,猫/熊/圆脸通用动物
pencil,铅笔,清晰铅笔,蜡笔以外的随机文具
apple,苹果,红色或绿色苹果,橘子/圆形装饰
```

For final batches, prefer exact assets from `assets/illustrations`. If a concrete visual cannot be represented accurately, replace the word with a clearer word or report missing assets.

## User-Friendly Command Templates

Use these prompts when explaining operation to beginners:

```text
使用 batch-english-learning-card-maker，生成一年级动物主题英语学习卡，自动分配数量，要求每张都有英文、音标、中文意思，配图必须和单词一致。
```

```text
使用 batch-english-learning-card-maker，生成学前班英语启蒙课程包，主题为食物和家庭，适合中文家长带孩子跟读。
```

```text
使用 batch-english-learning-card-maker，生成正式版一年级教室主题卡片，使用 assets/illustrations 里的素材，输出预览页和质量报告。
```

```text
使用 batch-english-learning-card-maker，先预览一年级动物主题生成方案，不生成图片。
```

```text
使用 batch-english-learning-card-maker，生成学前班食物主题7天学习包，适合家长每天带读。
```

## Beginner Flow

If the user sounds unsure, follow this flow:

1. Run or describe a generation preview first.
2. Show stage, theme, difficulty, output types, and counts.
3. If the user wants final images, generate the batch.
4. If the user wants formal output, check asset availability first.
5. If the user wants ongoing learning, add a 7-day plan.

Use `-PlanOnly` for preview and `-SevenDayPack` for sustained learning packs.

Use `-CompletePack` when the user asks for a one-click learning pack. Use `-FormalCompletePack` when they ask for a formal final version with no missing or misleading pictures.

## Quality Report Expectations

Before finishing, check:

- `manifest.csv` has system, level, stage, theme, type, English, IPA, Chinese, file.
- `quality-report.csv` includes missing-field checks and expected visual cue for word/combo cards.
- Formal output includes `visual-audit.csv` with actual asset paths.
- Lesson pages with more than 6 sentence pairs have enough row spacing.
- Chinese-facing images use Chinese helper labels only.
