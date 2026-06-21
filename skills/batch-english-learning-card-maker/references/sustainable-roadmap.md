# Sustainable Product Direction

Use this reference when the user asks how to keep improving the skill, build a long-term content system, create courses instead of one-off cards, or make the output more useful for parents and teachers.

## Product Direction

Move from one-off card generation to reusable learning products:

- one-click age or grade packs
- theme-based mini courses
- complete learning packs
- formal complete packs with strict asset checks
- 7-day learning packs
- printable card sets
- parent guide and review plan
- activity pack, phonics pack, and learning record
- formal asset library with visual audits

## Repeatable Content Units

Each reusable unit should contain:

- theme title in Chinese
- age/stage or level
- 8-20 vocabulary records
- 6-12 sentence records
- 4-8 combo card records
- 1-3 lesson pages
- 1 review activity
- parent guidance
- asset requirements

## 7-Day Learning Pack

When the user asks for 一周学习, 7天计划, 每日打卡, 亲子带读, or sustained learning, generate a 7-day sequence:

1. Day 1: picture-word recognition.
2. Day 2: IPA and oral repetition.
3. Day 3: short sentence input.
4. Day 4: word + sentence output.
5. Day 5: theme lesson page.
6. Day 6: review game or picture recall.
7. Day 7: mini test and reward.

Use `-SevenDayPack` when running the batch script.

## Generation Preview

When the user is unsure, run a plan before rendering:

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -System domestic -Level domestic-grade-1-2 -Theme zoo-animals -Mode mixed -AutoCounts -PlanOnly
```

The preview should tell the user:

- stage and level
- theme
- number of word cards, sentence cards, combo cards, and lesson pages
- difficulty
- whether formal assets are required
- expected output files

## Long-Term Expansion

Recommended expansion order:

1. Complete asset library for high-frequency words.
2. Build 100 lessons for preschool, kindergarten, grade 1, grade 2, and grade 3.
3. Add phonics cards for letters, CVC words, blends, and common sounds.
4. Add activity cards: choose, match, circle, trace, say, and review.
5. Add phone-friendly and print-friendly output presets.
6. Add quality scoring: A = ready, B = minor review, C = needs asset, D = blocked.

## Current Productized Outputs

The script can now output:

- `generation-plan.csv` and `generation-plan.txt` for preview.
- `recommended-themes.csv` for beginner theme choice.
- `asset-check.csv` for formal asset readiness.
- `asset-prompt-pack.txt` for copy-paste missing asset prompts.
- `missing-assets.csv` when strict formal asset checks fail.
- `missing-assets-prompts.txt` when strict checks need user-supplied assets.
- `seven-day-learning-plan.csv` for sustained learning.
- `daily-parent-guide.html` for a parent-readable 7-day plan.
- `activity-pack.csv` for simple interactive exercises.
- `activity-answer-key.csv` and `activity-answer-key.html` for parent answer checks.
- `activity-*.png` for printable activity images.
- `phonics-pack.csv` for first-letter phonics add-ons.
- `learning-record.csv` for parent tracking.
- `bundle-summary.txt` for a simple output index.
- `english-learning-pack.zip` for sharing or archiving.

Use `-CompletePack` for a one-shot learning product pack. It turns on course pack, 7-day learning plan, activity pack, phonics pack, learning record, print layout, and output summary.

Use `-StrictAssets` for final or formal output when image accuracy matters more than speed.

Use `-FormalCompletePack` when the user wants the safest final workflow: strict asset check first, then complete pack only when required formal assets exist.

Use `-RecommendThemesOnly` when the user only knows the age or grade and needs help choosing a theme.

`seven-day-learning-plan.csv` should name the actual card files for each day so parents do not need to decide the order themselves.

`daily-parent-guide.html` should be preferred when explaining the result to non-technical users, because it is easier to open, read, and print than CSV.

`activity-answer-key.html` should be generated with every activity pack so parents can quickly check answers without reading spreadsheet files.

## Content Safety

- Keep content concrete, kind, and age-appropriate.
- Avoid test-prep phrasing for preschool and lower primary unless requested.
- Avoid slang, idioms, abstract words, and culturally confusing examples for beginners.
- For Chinese-facing users, keep helper labels in Chinese.
