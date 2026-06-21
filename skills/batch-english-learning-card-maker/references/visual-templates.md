# Visual Templates

Use this reference when generating child-friendly English learning card images.

## General Principles

- Render final text locally. Do not ask an image model to draw the English, IPA, or Chinese text.
- Keep the center area clear and high contrast.
- Use original illustrations only. Do not copy a specific app, worksheet, or user-provided reference image.
- Use visual cues to help children understand meaning before reading.
- For vocabulary cards, match the visual cue to the English word whenever possible. For example, `book` should show a book illustration, not a generic shape with the Chinese label.
- Keep Chinese inside the visual cue optional and secondary; the picture should carry the meaning first.
- Prefer exact image assets from `assets/icons/{english}.png` or `.jpg` before built-in vector cues.
- For final output, define `expected_visual` before rendering and keep it in `quality-report.csv` or `visual-audit.csv`.
- Keep decoration at the edges, corners, or bottom band.
- For Chinese-only viewers, helper labels must be Chinese: use `跟读`, `复习`, and Chinese lesson titles. Do not show internal theme keys such as `cleaning-room` or `zoo-animals` inside the final image.

## Age-Based Density

| Preset | Visual density | Text density | Best card types |
| --- | --- | --- | --- |
| preschool-3-5 | Largest visual cue, simplest layout | 1 word or 1 very short sentence | word, combo |
| kindergarten-5-6 | Large visual cue, calm center | word + IPA + meaning + optional short example | word, sentence, combo |
| grade-1-6-7 | Balanced picture and text | word + IPA + meaning + example; short sentence cards | word, sentence, lesson |
| grade-2-7-8 | More text rows allowed | 5-6 sentence pairs per lesson page | sentence, lesson, mixed review |
| grade-3-8-9 | App-like review pages | 6-7 sentence pairs per page | lesson, mixed review |
| primary-4-6-9-12 | Reading-card style | 6-8 sentence pairs with less illustration | lesson, sentence, review |

## Level-Based Density

| Level | Maps to | Recommended emphasis | Visual treatment |
| --- | --- | --- | --- |
| domestic-preschool | preschool-3-5 / kindergarten-5-6 | concrete words, commands, parent-child reading | largest cue, very little text |
| domestic-grade-1-2 | grade-1-6-7 / grade-2-7-8 | daily words, classroom phrases, short oral sentences | balanced cue and text |
| domestic-grade-3-4 / 课标一级 | grade-3-8-9 | topic sentences, questions, short dialogues | lesson rows, clear grouping |
| domestic-grade-5-6 / 课标二级 | primary-4-6-9-12 | reading sentences, descriptions, routines | more text, smaller decoration |
| pre-a1 / Starters | kindergarten-5-6 / grade-1-6-7 | recognition and speaking confidence | colorful but uncluttered |
| a1 / Movers | grade-2-7-8 / grade-3-8-9 | reusable sentence patterns | app-like lesson pages |
| a2 / Flyers | primary-4-6-9-12 | longer sentence lists and review | reading-card style |

For automatic batches, younger levels should generate more word cards and combo cards. Older levels should generate more sentence cards and multi-sentence lesson pages.

## Learning Flow

For theme packs, order the output as a small lesson:

1. Word cards: recognize the picture and word.
2. Sentence cards: read one useful short sentence.
3. Combo cards: connect the word to a sentence.
4. Lesson pages: read several related sentences together.
5. Parent guide: tell Chinese-speaking adults how to review.

## Difficulty Modes

| Mode | Use for | Sentence feel |
| --- | --- | --- |
| starter | preschool and first exposure | shortest recognition sentences |
| basic | grade 1-2 and normal practice | simple complete sentences |
| challenge | older or faster learners | gentle question or expanded sentence |

Do not make challenge mode exam-like. It should still feel friendly and speakable.

## Visual Style Modes

| Mode | Look |
| --- | --- |
| icon | clean symbol-like cards with fewer decorations |
| storybook | default children's book poster style |
| watercolor | softer paper texture and gentler palette |

## Production Modes

Use two quality levels:

| Mode | Use case | Asset rule |
| --- | --- | --- |
| draft | fast preview and layout checks | built-in icons are acceptable |
| formal | print, publishing, children-facing final images | use high-quality assets from `assets/illustrations` or user-provided files |

For formal output, prefer `scripts/render_asset_cards.ps1` so the asset size and text layout are deterministic. Formal animal, food, transport, and classroom-object cards should not rely on script-drawn placeholder icons.

If formal assets are missing, stop and report the missing words. Do not silently substitute a generic shape, fruit-like icon, or unrelated decoration.

## Card Layouts

### Single Word Card

Use for vocabulary drilling.

```text
[visual cue area]

apple
/ˈæpəl/
苹果

I eat an apple.
我吃一个苹果。
```

Example text should be large enough for a child to read at a glance. Use adaptive sizing: short examples should become visibly larger, while long examples should shrink and wrap inside the reserved example area.

### Single Short Sentence Card

Use for daily spoken English.

```text
[small visual cue or scene]

Good morning.
/ɡʊd ˈmɔːrnɪŋ/
早上好。
```

### Word + Sentence Combo Card

Use when the user asks for one word with one practical sentence.

```text
[large visual cue]

rag
/ræɡ/
抹布

Can you get me the rag?
你能帮我拿抹布吗？
```

The sentence block is part of the learning focus, not a footnote. Keep it prominent, centered, and responsive to text length.

### Multi-Sentence Lesson Page

Use when the user asks for several related short sentences on one image, like an English learning app lesson page.

```text
14 Cleaning the Floor

Let's wipe the floor.
我们来擦地板吧。

I'm going to sweep the floor today.
今天我要扫地。

Can you get me the rag?
你能帮我拿抹布吗？
```

Layout rules:

- Put title at the top.
- Use 4-8 English/Chinese sentence pairs.
- Keep each pair visually grouped.
- Use English first, Chinese below.
- Use simple row spacing, not dense paragraphs.
- Auto-fit the lesson layout: calculate row height from the number of sentence pairs, reduce English and Chinese font sizes for long lines, and keep enough spacing so pairs do not overlap.
- Hide or shrink bottom decoration when the sentence list needs more vertical space.
- Never repeat a sentence just to fill a fixed page count; use fewer rows if the theme has fewer suitable sentence pairs.
- Label bottom review areas as `复习`, not `Review`.
- Put small characters, stars, classroom objects, or topic objects near the bottom or edges.
- Avoid copying Duolingo or any specific brand characters. Create original friendly characters if needed.

## Recommended Color Palettes

### Pastel Classroom

- Background: warm cream `#FFF7E8`
- Main text: deep teal `#1F5D68`
- IPA: soft lavender `#7D6A9F`
- Chinese: warm coral `#D86B5C`
- Accent: butter yellow `#F6C85F`
- Secondary: mint green `#8AC7A4`

### Sky Garden

- Background: pale sky `#EAF7FF`
- Main text: soft navy `#26364A`
- IPA: blue gray `#617C96`
- Chinese: leaf green `#4E8A67`
- Accent: peach `#F7A072`
- Secondary: cream `#FFF4D6`

### Playful Review

- Background: pale pink `#FFE7EC`
- Panel: white `#FFFFFF`
- Main text: cocoa `#4B332A`
- IPA: muted purple `#7463A6`
- Chinese: berry `#C45B7A`
- Accent: aqua `#77C9D4`

## Theme Guidance

- Animals: use recognizable animal illustrations with defining features, preferably full-body or half-body. For example, cat must have pointed ears, whiskers, paws, and tail; dog should have floppy ears or dog snout; rabbit should have long ears. Do not use a generic round face as the final animal cue.
- For final animal cards, prefer high-quality children's-book illustrations or a stable asset library. Script-drawn animal icons are only acceptable for low-fidelity previews.
- Keep animal illustrations smaller than the text area: about 25%-30% of portrait card height, placed in the upper third with clean space below for final text.
- Food: use clean fruit, bread, cup, bowl, and lunchbox cues.
- Classroom: use actual book, pencil, backpack, ruler, desk, chair, block, and star cues.
- Cleaning: use actual rag, broom, floor, bucket, and soap bubble cues.
- Family: use home, photo frame, people silhouettes, hearts.
- Weather: use sun, cloud, rain, rainbow, wind lines.
- Park: use trees, kite, bench, path, flowers.

## Visual Cue Fallback

- First choice: draw or place a concrete icon matching the English word.
- Second choice: draw a theme-level icon, such as classroom object, food, weather, or home.
- Last choice: use a neutral concept cue, such as a light bulb for abstract words.
- Never show a misleading decorative object for a vocabulary word.
- Never use a fruit-like generic icon unless the word is actually fruit or color-related.

## Beginner-Friendly Output Rules

- If the user does not know what to choose, use automatic counts and a common theme for the requested stage.
- If the card is for children under 7, make the visual cue easy to recognize within one second.
- For word cards, keep the picture in the upper third and use the remaining space for English, IPA, Chinese, and one short example.
- For sentence cards, use a small scene only when it reinforces the sentence; otherwise prioritize readable text.
- For lesson pages, split into multiple pages when sentence pairs exceed the comfortable row count.
- For Chinese-speaking viewers, do not show English helper labels such as `Review`, `Say it!`, or internal theme keys.

## Playful Card Consistency

For mission, question, matching, circle-the-answer, or reward cards, define a binding table before drawing:

| option | english | meaning | visual |
| --- | --- | --- | --- |
| A | book | 书 | open book |
| B | cat | 猫 | cat |
| C | apple | 苹果 | apple |

Rules:

- The target word, Chinese meaning, visual cue, and correct option must refer to the same item.
- Distractor options must also be visually correct; a wrong answer can be wrong for the question, but its own picture cannot be misleading.
- Do not use generic circles, fruit-like placeholders, or reused icons for unrelated words.
- If a concrete visual cue is unavailable, replace the word with one that can be represented reliably.
- Add a quality check row for every playful card: target, correct option, option labels, and visual cue names.

## Readability Checks

- English should be the darkest and most prominent text.
- IPA should be smaller than English but still legible.
- Chinese should sit close to the matching English text.
- Do not place text over busy illustrations.
- Ensure long English lines wrap cleanly without touching the edges.
- For formal cards, check `visual-audit.csv`: asset path must be present, image height ratio should usually stay between 0.18 and 0.31, and status should be `pass`.

## Manifest Tags

When exporting batches, keep enough metadata for quick filtering later:

- `system`: domestic, international, or auto.
- `level`: domestic-grade-1-2, pre-a1, a1, a2, or blank when only a stage is used.
- `stage`: bundled stage key actually used.
- `theme`: normalized topic.
- `skill`: word, sentence, combo, or lesson.
- `difficulty`: starter, easy, medium, or upper-primary.
