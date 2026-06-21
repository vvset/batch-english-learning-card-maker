# Install

This repository ships one Skill folder that can be used in Codex and in Claude / Claude Code environments that support custom Skills.

## Skill Folder

Use this folder:

```text
skills/batch-english-learning-card-maker
```

## Install For Codex

1. Download this repository or the release ZIP.
2. Copy the Skill folder:

```text
skills/batch-english-learning-card-maker
```

3. Place it in your Codex skills directory. Common local locations include:

```text
Windows: C:\Users\<you>\.codex\skills\batch-english-learning-card-maker
macOS/Linux: ~/.codex/skills/batch-english-learning-card-maker
```

4. Restart Codex if needed.
5. Ask Codex:

```text
Use batch-english-learning-card-maker to generate a Grade 1 weather-themed English learning pack.
```

## Install For Claude / Claude Code

1. Download this repository or the release ZIP.
2. Use the same Skill folder:

```text
skills/batch-english-learning-card-maker
```

3. Import or copy it into the custom Skills location used by your Claude / Claude Code setup.
4. Restart or reload Claude if your environment requires it.
5. Ask Claude:

```text
Use batch-english-learning-card-maker to generate a preschool animal-themed English learning pack.
```

If your Claude environment asks for a ZIP instead of a folder, compress the `batch-english-learning-card-maker` folder and upload/import that ZIP as a custom Skill.

## Direct Script Use

You can also run the generator without installing it as a Skill:

```powershell
cd .\skills\batch-english-learning-card-maker
pwsh -ExecutionPolicy Bypass -File .\scripts\generate_cards.ps1 -Preset grade1-weather -OutputDir .\output\grade1-weather-pack
```

