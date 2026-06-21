# Batch English Learning Card Maker

**English | [简体中文](README.zh-CN.md) | [Language Switch Page](index.html)**

Batch English Learning Card Maker is a Codex Skill for generating children's English learning packs. It creates downloadable portrait PNG cards, lesson pages, interactive HTML pages, parent guides, review plans, quality reports, and ZIP bundles.

The Skill is designed for Chinese-speaking parents, teachers, and creators who want to produce English learning cards for preschool, kindergarten, primary school, CEFR Pre-A1/A1/A2, or Cambridge-style children's English.

## What It Can Generate

- English vocabulary cards with IPA and Chinese meanings
- English short sentence cards with IPA and Chinese meanings
- Word + sentence combo cards
- Multi-sentence lesson pages
- Today learning sheet for parents
- Interactive child learning page
- Parent dashboard
- Review plan
- A4 print layout
- Share copy for social posts
- Quality, visual coverage, and content gap reports
- Parent-use ZIP and full inspection ZIP

## Repository Layout

```text
skills/batch-english-learning-card-maker/
  SKILL.md
  scripts/
  references/
  assets/

releases/
  batch-english-learning-card-maker-portable-20260621-functional.zip
```

## Quick Start

Run from the Skill folder:

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -Preset grade1-weather -OutputDir .\output\grade1-weather-pack
```

Common prompt:

```text
Use batch-english-learning-card-maker to generate a Grade 1 animal-themed English learning pack with vocabulary cards, short sentence cards, lesson pages, a parent guide, and a downloadable ZIP.
```

## Recommended Output Entry

After generation, open:

```text
download.html
```

For parents, share:

```text
parent-use-pack.zip
```

For creators or reviewers, inspect:

```text
qa-dashboard.html
content-gap-report.csv
creator-next-actions.txt
quality-report.csv
visual-coverage.csv
```

## Notes

- Final card text is rendered locally by script, not by image-generation models.
- Chinese CSV files are exported with UTF-8 BOM for Windows Excel compatibility.
- The parent-use ZIP excludes technical reports by default.
- Formal animal assets are checked through the bundled asset registry.

