# Initial CivArchive Metadata Analysis

## Data source

This repository contains an initial analysis of a community-maintained CivArchive metadata SQLite snapshot.

I obtained the underlying SQLite database (`CivArchive.sqlite`) from the **"Civ Archive"** Discord server (https://discord.gg/JDH32JuB). I downloaded it on **May 3, 2026** from a pinned post by **VioletViolence [CMFY]**. The metadata collection started on **May 8, 2025**, with periodic full scans of CivArchive over time. The database snapshot I used corresponds to the provider's update from **November 22, 2025**. According to VioletViolence, the SQLite database was built from repeated scans of the CivitAI public API, starting on May 8, 2025. The data is stored across model, version, and file tables. VioletViolence noted that their scraping used the CivitAI `/api/v1/models` endpoint with parameters such as `sort=Newest`, `period=AllTime`, and `nsfw=true`, with a delay between API calls. I did not run this scraping process myself; I used the shared SQLite snapshot from the CivArchive Discord.

I did not directly crawl CivArchive or CivArchive myself. Based on the Discord discussion, large crawling to rebuild the full database appeared unnecessary, so I treated the SQLite file as a local archival metadata snapshot.

The large raw data export is stored  separately here: https://drive.google.com/drive/folders/1dbwpX5MfXhaZu-B3Y5fefwjt7tsdntQE

## Database structure

| Table                  | Level                 | Important fields                                                                           |
| ---------------------- | --------------------- | ------------------------------------------------------------------------------------------ |
| `models`               | model-level           | `id`, `name`, `type`, `username`, `data`, `created_at`, `updated_at`                       |
| `model_versions`       | version-level         | `id`, `model_id`, `name`, `base_model`, `published_at`, `data`, `created_at`, `updated_at` |
| `model_files`          | file-level            | `id`, `model_id`, `version_id`, `type`, `sha256`, `data`, `created_at`, `updated_at`       |
| `archived_model_files` | archived file mapping | `file_id`, `model_id`, `version_id`                                                        |

## NSFW definition

I defined NSFW status at the model level using:

```sql
json_extract(models.data, '$.nsfw') = 1
```

Records where this field is `0` or `NULL` are grouped as `non-NSFW/unknown`.

The master export query includes:

* `model_nsfw`
* `model_nsfwLevel`
* `category`

where `category` is derived as:

* `NSFW`
* `non-NSFW/unknown`

## Dataset overview

| Metric                  |               Value |
| ----------------------- | ------------------: |
| Total models            |             605,909 |
| Total versions          |             786,245 |
| Total files             |             825,659 |
| Files with SHA256       |             824,981 |
| Earliest `published_at` | 2022-11-04 17:29:42 |
| Latest `published_at`   | 2025-11-24 01:37:16 |

Source file: `summaries/01_dataset_overview.csv`

## NSFW vs non-NSFW

| Category         |  Models | Versions |   Files | Files with SHA256 |
| ---------------- | ------: | -------: | ------: | ----------------: |
| NSFW             | 149,098 |  195,526 | 209,250 |           209,104 |
| non-NSFW/unknown | 456,811 |  590,719 | 616,409 |           615,877 |

Source file: `summaries/02_nsfw_vs_non_nsfw_counts.csv`

## Data quality / missingness

| Field             | Missing count | Missing percent |
| ----------------- | ------------: | --------------: |
| `username`        |        26,570 |           4.39% |
| `published_at`    |         8,285 |           1.05% |
| `sha256`          |           678 |           0.08% |
| `model_nsfwLevel` |        35,925 |           5.93% |

Source file: `summaries/03_missingness_overall.csv`

## Headline findings initial pass

These are initial descriptive findings from the metadata snapshot. I included them as quick checks that may be useful for later analysis.

* **Foundation distribution within NSFW models is heavily concentrated.** Illustrious (48.0%), Pony (34.8%), and SD 1.5 (12.0%) together account for about 95% of NSFW models with a declared base model. Source: `summaries/09_nsfw_base_models.csv`

* **The NSFW ecosystem is LoRA-saturated.** 95.2% of NSFW models are LoRAs (141,890 of 149,098), compared to 89.5% for non-NSFW/unknown. Checkpoints account for only 2.4% of NSFW models. Source: `summaries/05_model_type_by_category.csv`

* **Creator concentration is high.** The top 10 NSFW creators account for around 13K NSFW models combined. This could be useful for follow-up work on production-side concentration. Source: `summaries/15_nsfw_top_creators.csv`

* **`nsfwLevel` is multi-modal, not binary.** Within `nsfw = 1`, level 60 dominates (about 82%), with level 28 as the secondary level (about 12.8%). A small set of `nsfw = 0` models also have non-trivial `nsfwLevel` values, which may be useful to inspect later as potential edge cases. Sources: `summaries/06_nsfw_level_distribution.csv`, `summaries/07_nsfw_level_filter_check.csv`

## Included summary outputs

| File                                                | Description                                                    |
| --------------------------------------------------- | -------------------------------------------------------------- |
| `summaries/01_dataset_overview.csv`                 | Overall model, version, file, SHA256, and time coverage counts |
| `summaries/02_nsfw_vs_non_nsfw_counts.csv`          | Counts by NSFW category                                        |
| `summaries/03_missingness_overall.csv`              | Missingness summary for key fields                             |
| `summaries/04_missingness_by_category.csv`          | Missingness split by NSFW vs non-NSFW/unknown                  |
| `summaries/05_model_type_by_category.csv`           | Model type distribution by NSFW category                       |
| `summaries/06_nsfw_level_distribution.csv`          | Distribution of model-level `nsfwLevel` by category            |
| `summaries/07_nsfw_level_filter_check.csv`          | Cross-tab/check between `nsfw` and `nsfwLevel`                 |
| `summaries/09_nsfw_base_models.csv`                 | Base model distribution within the NSFW subset                 |
| `summaries/10_versions_files_by_category.csv`       | Version and file counts by category                            |
| `summaries/11_nsfw_versions_files.csv`              | Version and file summary for NSFW models                       |
| `summaries/12_models_without_versions_or_files.csv` | Models or versions with missing relational records             |
| `summaries/13_archived_model_files_by_category.csv` | Archived file mapping summary by category                      |
| `summaries/14_model_source_breakdown.csv`           | Source/provenance breakdown if available in JSON               |
| `summaries/15_nsfw_top_creators.csv`                | Top creators by NSFW model count                               |

## Main output not included in GitHub

The full joined model-version-file export is intentionally excluded from GitHub:

```text
all_models_full_metadata.csv
```

Reason: this file is large and exceeded the GitHub Enterprise file size limit.

## Notes and limitations

* This dataset is a local metadata snapshot, not a live scrape.
* `created_at` and `updated_at` refer to when records were collected or added to the database, not necessarily the original CivArchive publication date.
* `published_at` from `model_versions` is used as the closest available model-version publication timestamp.
* NSFW status appears to be available at the model level. Version-level `nsfw` was mostly `NULL` in initial checks, while version-level `nsfwLevel` is available.
* The full joined export contains one row per model-version-file combination, so models with multiple versions or files appear multiple times.
* `non-NSFW/unknown` combines records where `$.nsfw = 0` and records where the field is missing/NULL.

