# 内容审计与个性化复习

当用户提出“检查内容是否准确”“孩子每天学什么”“根据掌握情况复习”“制定学习路径”时，使用：

- `scripts/build_adaptive_learning_plan.ps1`

## 能做什么

脚本读取已生成卡包中的 `manifest.csv`，可选读取 `learning-record.csv`，输出：

- `content-audit.csv`：检查英文、音标格式、中文意思、正式配图来源、音标来源、句子长度和重复内容。
- `review-queue.csv`：按照“半会、到期复习、已掌握”排列复习优先级。
- `personalized-learning-plan.csv`：按年龄、每日时长和计划天数安排学习顺序。
- `learner-summary.txt`：给中文家长看的简单摘要。

## 使用方法

生成卡包后运行：

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\build_adaptive_learning_plan.ps1 -PackDir .\output\english-learning-cards -Age 7 -DailyMinutes 15 -Days 7
```

如果家长已经填写学习记录：

```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\build_adaptive_learning_plan.ps1 -PackDir .\output\english-learning-cards -LearningRecordPath .\output\english-learning-cards\learning-record.csv -Age 7 -DailyMinutes 15 -Days 7
```

正式发布前要求发现关键内容问题就停止：

```powershell
-StrictContent
```

## 学习记录填写规则

`learning-record.csv` 的 `status` 只填写以下一种：

- `未学`
- `半会`
- `已会`

`review_date` 使用 `YYYY-MM-DD`。脚本优先安排“半会”和已经到复习日期的内容；新学内容会在第 1 天和第 3 天后再次安排复习。

## 功能边界

内容审计是确定性检查，可以发现字段缺失、格式异常、内容过长、来源不可靠和重复项，但不能替代专业教师对翻译自然度、口音差异或复杂语法的最终判断。存在 `review` 项时应人工复核，存在 `blocked` 项时不应用于正式学习。
