# Activity, Phonics, and Learning Record Packs

Use this reference when the user asks for fun learning, exercises, phonics, daily practice, review sheets, or a more product-like learning package.

## Activity Pack

Use `-ActivityPack` when the user asks for:

- 趣味练习
- 互动练习
- 小测验
- 看图选单词
- 连线题
- 圈一圈
- 中文说英文
- 复习游戏

Default activity types:

- 看图选单词
- 中英连线
- 看中文说英文
- Printable activity images when `-ActivityImages` is enabled.

Default output:

- `activity-pack.csv`
- `activity-answer-key.csv`
- `activity-answer-key.html`
- `activity-*.png` when `-ActivityImages` is enabled.

Rules:

- Each activity must use words from the generated batch.
- Options must each have correct English, Chinese, and visual meaning.
- Distractors can be wrong answers, but their own pictures cannot be misleading.
- For children under 7, keep activities visual and simple.
- The answer key should be easy for Chinese-speaking parents to read without opening raw CSV files.

## Phonics Pack

Use `-PhonicsPack` when the user asks for:

- phonics
- 自然拼读
- 字母发音
- 首字母发音
- CVC 单词
- 字母和单词一起学

Default output:

- word
- IPA phonetic transcription
- Chinese meaning
- first letter
- phonics focus
- parent practice tip

Rules:

- Keep phonics as an add-on, not a replacement for IPA.
- For preschool and grade 1, start with first-letter sounds and simple CVC words.
- Avoid complex phonics explanations unless the user asks for older children.

## Learning Record

Use `-LearningRecord` when the user asks for:

- 学习记录
- 打卡表
- 掌握情况
- 复习清单
- 家长记录

Default fields:

- date
- card
- type
- English
- Chinese meaning
- status: 未学 / 半会 / 已会
- review date
- parent note

## Combined Product Pack

When the user asks for a complete productized pack, combine:

```powershell
-CompletePack
```

For formal output, use:

```powershell
-FormalCompletePack
```

If the user requires no missing or misleading pictures but does not need a full pack, add:

```powershell
-StrictAssets
```

Complete packs should also include parent-friendly helper outputs:

- `daily-parent-guide.html` for the 7-day study plan.
- `activity-answer-key.html` for exercise answers.
- `bundle-summary.txt` as the file index.
