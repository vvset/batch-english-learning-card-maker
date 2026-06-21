# Level Systems

Use this reference when the user asks for domestic Chinese school stages, international English levels, Cambridge-style levels, CEFR levels, or automatic content density.

## Domestic China System

| Level key | User may say | Recommended stage | Content goal |
| --- | --- | --- | --- |
| domestic-preschool | 幼儿园, 幼儿英语, 3-6岁, 英语启蒙 | preschool-3-5 or kindergarten-5-6 | Build listening interest with concrete nouns and very short commands. |
| domestic-grade-1-2 | 一年级, 二年级, 小学低年级, 一二年级 | grade-1-6-7 or grade-2-7-8 | Learn daily words, classroom language, family, animals, food, and short oral sentences. |
| domestic-grade-3-4 | 三年级, 四年级, 课标一级, 小学中年级 | grade-3-8-9 | Move from single words to reusable sentence patterns and topic-based lessons. |
| domestic-grade-5-6 | 五年级, 六年级, 课标二级, 小学高年级 | primary-4-6-9-12 | Increase reading sentences, routines, questions, descriptions, and short paragraph-like lesson pages. |

## International System

| Level key | User may say | Recommended stage | Content goal |
| --- | --- | --- | --- |
| pre-a1 | Pre-A1, pre A1, Starters, Cambridge Starters | kindergarten-5-6 or grade-1-6-7 | Recognize familiar words, simple classroom commands, colors, numbers, food, animals, and family. |
| a1 | A1, Movers, Cambridge Movers | grade-2-7-8 or grade-3-8-9 | Use simple present-tense sentences, questions, likes, abilities, locations, and daily routines. |
| a2 | A2, Flyers, Cambridge Flyers | primary-4-6-9-12 | Read and produce longer sentence pairs, descriptions, reasons, simple past/future, and themed review pages. |

## Automatic Density

Use these ratios when the user says "自动", "按年龄自动", "按阶段生成", or omits exact counts.

| Level or stage | Word cards | Sentence cards | Combo cards | Lesson pages | Visual rule |
| --- | ---: | ---: | ---: | ---: | --- |
| preschool-3-5 / domestic-preschool early | 20 | 4 | 8 | 1 | Very large cue, one idea per card. |
| kindergarten-5-6 / pre-a1 early | 20 | 6 | 8 | 1 | Large cue, short examples only. |
| grade-1-6-7 / domestic-grade-1-2 / pre-a1 | 20 | 10 | 10 | 2 | Balanced word, sentence, and lesson practice. |
| grade-2-7-8 / a1 early | 16 | 12 | 8 | 2 | More sentence practice and themed oral patterns. |
| grade-3-8-9 / domestic-grade-3-4 / a1 | 12 | 14 | 6 | 3 | Topic pages become the main learning surface. |
| primary-4-6-9-12 / domestic-grade-5-6 / a2 | 10 | 16 | 4 | 3 | Reading-card style with longer sentence lists. |

## Metadata Tags

Every generated manifest row should include these tags when possible:

```csv
system,level,stage,theme,skill,difficulty,source
```

- `system`: `domestic`, `international`, or `auto`.
- `level`: selected level key, such as `domestic-grade-1-2`, `pre-a1`, `a1`, or `a2`.
- `stage`: concrete bundled stage key used for content selection.
- `theme`: normalized theme key or Chinese display name.
- `skill`: output type, such as `word`, `sentence`, `combo`, or `lesson`.
- `difficulty`: `starter`, `easy`, `medium`, or `upper-primary`.
- `source`: `theme-pack`, `stage-bank`, or `generated`.

## Selection Rules

1. If the user names a domestic grade or curriculum level, set `system=domestic`.
2. If the user names CEFR, Cambridge, Starters, Movers, or Flyers, set `system=international`.
3. If the user names both age and grade, prefer the grade, then use the age to choose the easier or harder adjacent bundled stage.
4. If the user names a topic, select theme-pack records before generic stage-bank records.
5. Do not show internal level keys on the final image. Use Chinese display text for Chinese-speaking users.
