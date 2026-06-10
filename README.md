# Initial CivitAI Metadata Analysis

## Data source

This repository contains an initial analysis of a community-maintained CivitAI metadata SQLite snapshot.

The analysis uses a local SQLite database file named `civitai.sqlite`. I did **not** directly crawl CivArchive. Based on the Discord discussion, large-scale crawling to build a full database appears discouraged, so this analysis treats the SQLite file as a local archival metadata snapshot.

Large raw data exports such as `all_models_full_metadata.csv` are **not included in this GitHub repository** because they exceed GitHub Enterprise's file size limit. They should be stored/shared separately, for example through OneDrive or Georgia Tech storage.

## Database structure

| Table | Level | Important fields |
|---|---|---|
| `models` | model-level | `id`, `name`, `type`, `username`, `data`, `created_at`, `updated_at` |
| `model_versions` | version-level | `id`, `model_id`, `name`, `base_model`, `published_at`, `data`, `created_at`, `updated_at` |
| `model_files` | file-level | `id`, `model_id`, `version_id`, `type`, `sha256`, `data`, `created_at`, `updated_at` |
| `archived_model_files` | archived file mapping | `file_id`, `model_id`, `version_id` |

## NSFW definition

NSFW status is defined at the model level using:

```sql
json_extract(models.data, '$.nsfw') = 1
```

Records where this field is `0` or `NULL` are grouped as `non-NSFW/unknown`.

The master export query includes:

- `model_nsfw`
- `model_nsfwLevel`
- `category`

where `category` is derived as:

- `NSFW`
- `non-NSFW/unknown`

## Dataset overview

| Metric | Value |
|---|---:|
| Total models | 605,909 |
| Total versions | 786,245 |
| Total files | 825,659 |
| Files with SHA256 | 824,981 |
| Earliest `published_at` | 2022-11-04 17:29:42 |
| Latest `published_at` | 2025-11-24 01:37:16 |

Source file: `summaries/dataset_overview.csv`

## NSFW vs non-NSFW

| Category | Models | Versions | Files | Files with SHA256 |
|---|---:|---:|---:|---:|
| NSFW | 149,098 | 195,526 | 209,250 | 209,104 |
| non-NSFW/unknown | 456,811 | 590,719 | 616,409 | 615,877 |

Source file: `summaries/nsfw_vs_non_nsfw_counts.csv`

## Data quality / missingness

| Field | Missing count | Missing percent |
|---|---:|---:|
| `username` | 26,570 | 4.39% |
| `published_at` | 8,285 | 1.05% |
| `sha256` | 678 | 0.08% |
| `model_nsfwLevel` | 35,925 | 5.93% |

Source file: `summaries/missingness_summary.csv`

## Included summary outputs

| File | Description |
|---|---|
| `summaries/dataset_overview.csv` | Overall model, version, file, SHA256, and time coverage counts |
| `summaries/nsfw_vs_non_nsfw_counts.csv` | Counts by NSFW category |
| `summaries/missingness_summary.csv` | Missingness summary for key fields |
| `summaries/model_type_by_category.csv` | Model type distribution by NSFW category |
| `summaries/nsfw_level_distribution.csv` | Distribution of model-level `nsfwLevel` by category |

## Main output not included in GitHub

The full joined model-version-file export is intentionally excluded from GitHub:

```text
all_models_full_metadata.csv
```

Reason: this file is large and exceeded the GitHub Enterprise file size limit.

## Notes and limitations

- This dataset is a local metadata snapshot, not a live scrape.
- `created_at` and `updated_at` refer to when records were collected or added to the database, not necessarily the original CivitAI publication date.
- `published_at` from `model_versions` is used as the closest available model-version publication timestamp.
- NSFW status appears to be available at the model level. Version-level `nsfw` was mostly `NULL` in initial checks, while version-level `nsfwLevel` is available.
- The full joined export contains one row per model-version-file combination, so models with multiple versions or files appear multiple times.
- `non-NSFW/unknown` combines records where `$.nsfw = 0` and records where the field is missing/NULL.
