# Asset Library Rules

Use this reference when the user asks for formal output, accurate pictures, publishing-ready cards, or any batch with concrete objects such as animals, food, school items, weather, transport, body parts, or household objects.

## Core Rule

Formal cards must use stable, reusable assets. Do not rely on script-drawn placeholders for final children-facing output.

Preferred asset location:

```text
assets/illustrations/{english}.png
```

Acceptable image formats:

- `.png`
- `.jpg`
- `.jpeg`
- `.webp`

## Asset Manifest Fields

When building a reusable asset library, track assets with these fields:

```csv
english,meaning,category,asset,expected_visual,avoid,age_fit,status
cat,猫,animals,cat.png,orange or gray cat with ears whiskers paws and tail,dog bear round-face placeholder,3-8,ready
book,书,classroom,book.png,open or closed book,fruit circle decoration,3-10,ready
pencil,铅笔,classroom,pencil.png,clear pencil,random stationery,3-10,ready
apple,苹果,food,apple.png,red or green apple,orange peach generic circle,3-8,ready
sun,太阳,weather,sun.png,warm sun,flower yellow ball,3-8,ready
```

## Category Priority

Build assets in this order:

1. Animals: cat, dog, rabbit, bird, fish, duck, cow, pig, sheep, horse, bear, lion, tiger, monkey, panda.
2. Classroom: book, pencil, pen, bag, ruler, eraser, desk, chair, door, window, teacher, school.
3. Food: apple, banana, orange, pear, milk, water, bread, egg, rice, noodles, cake.
4. Family and people: mom, dad, baby, friend, teacher, boy, girl.
5. Weather and nature: sun, moon, star, cloud, rain, wind, snow, tree, flower.
6. Actions: read, write, run, jump, eat, drink, sleep, open, close, clean.

## Matching Rules

- The picture must be understandable without reading Chinese.
- The main subject should occupy about 25%-30% of portrait card height for word and combo cards.
- Use one clear subject, not a busy scene, for beginner word cards.
- Use a small scene only for sentence cards where the action matters.
- If an exact asset is missing, report it before formal generation.
- If an object is hard to draw accurately, replace it with a more concrete age-appropriate word.

## Quality Checks

For every formal batch:

- `visual-audit.csv` must include the actual asset path.
- Missing assets should be marked `needs-asset`.
- `missing-assets.csv` should include `required_filename`, `expected_visual`, and `asset_prompt` so the user knows exactly what image to add.
- `asset-prompt-pack.txt` or `missing-assets-prompts.txt` should turn missing asset rows into copy-paste prompt blocks for non-technical users.
- Asset height ratio should usually stay between `0.18` and `0.31`.
- Animal assets must include defining features.
- Classroom and food assets must not use generic circles or decorative blobs.

## Prompt Pack Format

When an asset is missing, include a readable prompt block:

```text
文件名：cat.png
英文：cat
中文：猫
分类：animals
应显示：小猫，必须有猫耳、胡须、尾巴
保存位置：assets/illustrations/cat.png

可复制给绘图工具的提示词：
watercolor children's flashcard asset, one clear orange tabby cat...
```

This reduces the most common user pain point: they know an image is missing, but do not know what exact file to create or where to put it.
