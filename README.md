# Initial CivArchive Metadata Analysis

## Data source

This repository contains an initial analysis of a community-maintained CivArchive-hosted CivitAI metadata SQLite snapshot.

I obtained the underlying SQLite database (`CivArchive.sqlite`) from the **"Civ Archive"** Discord server (https://discord.gg/JDH32JuB). I downloaded it on **May 3, 2026** from a pinned post by **VioletViolence [CMFY]**. The database snapshot I used corresponds to their update from **November 22, 2025**.

According to VioletViolence, the SQLite database was built from repeated scans of the CivitAI public API, starting on **May 8, 2025**, with periodic full scans over time. The data is stored across model, version, and file tables. VioletViolence noted that their scraping used the CivitAI `/api/v1/models` endpoint with parameters such as `sort=Newest`, `period=AllTime`, and `nsfw=true`, with a delay between API calls.

I did **not** run this scraping process myself. I used the shared SQLite snapshot from the CivArchive Discord and treated it as a local archival metadata snapshot.

I also checked platform provenance in the version-level `downloadUrl` field. Almost all versions point to `civitai.com`, so I describe the dataset as a CivArchive-hosted CivitAI metadata snapshot rather than a live CivitAI scrape.

The large raw data export is stored separately here: https://drive.google.com/drive/folders/1dbwpX5MfXhaZu-B3Y5fefwjt7tsdntQE

## Headline findings initial pass

These findings are based on the broad metadata snapshot of **605,909 models**, not on a pre-filtered NSFW-only subset. This is useful because many foundations are dual-use and appear across both NSFW and non-NSFW/unknown categories.

1. **Dual-use foundations are visible in the metadata**
   Source: `summaries/17_base_model_overlap_nsfw_nonnsfw.csv`

   Pony and Illustrious both appear in NSFW and non-NSFW/unknown models. Illustrious has 71,557 NSFW models and 136,698 non-NSFW/unknown models, while Pony has 51,936 NSFW models and 113,160 non-NSFW/unknown models. SD 1.5 is more heavily represented in the non-NSFW/unknown population. This supports treating these foundations as dual-use rather than NSFW-only.

2. **Several smaller or newer foundations are more NSFW-skewed**
   Source: `summaries/19_base_models_30plus_lora_derivatives.csv`

   Among base models with at least 30 LoRA derivatives and at least 30 NSFW LoRA derivatives, some smaller or emerging foundations have a higher NSFW share than larger mainstream foundations. Examples include Wan Video 14B i2v 480p, Wan Video 2.2 I2V-A14B, Chroma, and Wan Video 2.2 T2V-A14B. These may be worth inspecting further as potentially high-NSFW-concentration foundation families.

3. **Pony to Illustrious shift is visible at the broader metadata level**
   Source: `summaries/20_foundation_shift_over_time.csv`

   Monthly counts of NSFW LoRA models by foundation show Pony dominating earlier in the observation window, with Illustrious becoming more prominent later. This provides broader metadata-level support for the foundation-shift pattern.

4. **The NSFW subset is extremely LoRA-heavy**
   Sources: `summaries/16_checkpoint_vs_lora_by_category.csv`, `summaries/21_creator_concentration_nsfw_loras.csv`

   141,890 of 149,098 NSFW models are LoRAs, or about 95.2%. Checkpoints account for only about 2.4% of the NSFW subset. The non-NSFW/unknown category is also LoRA-heavy at about 89.5%, but the NSFW subset is even more skewed toward LoRAs.

   Creator-side concentration is also visible among NSFW LoRAs. The ranked creator table can be used to calculate concentration metrics such as top-k shares or a creator-side Gini coefficient.

5. **`nsfwLevel` is multi-modal, not binary**
   Sources: `summaries/06_nsfw_level_distribution.csv`, `summaries/07_nsfw_level_filter_check.csv`

   Within `nsfw = 1`, level 60 dominates with 122,960 models, followed by level 28 with 19,013 models. A small set of models have `nsfw = 0` but non-trivial `nsfwLevel` values. These cases may be worth inspecting later as metadata-label edge cases or possible declared-vs-platform-side disagreement.

## Methodological note: foundation-family vs. specific-checkpoint granularity

The `base_model` field in this snapshot captures a **foundation-family level** value, such as `Illustrious`, `Pony`, or `SDXL 1.0`. It does not always identify specific checkpoint releases such as `WAI-NSFW-Illustrious-v140` or `CyberRealistic Pony`.

Aggregates reported here therefore describe foundation-family associations rather than exact lineage or specific named child checkpoints. For finer-grained lineage analysis, additional resolution against fields such as `civitai_resources`, `parent_checkpoints`, gallery metadata, or external API mappings would be needed.

A model can also have multiple versions with different `base_model` values. For this reason, base-model tables should be interpreted as **declared base-model associations**, not perfectly disjoint model categories.

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

## Included summary outputs

### Overview and data quality

| File                                                | Description                                                    |
| --------------------------------------------------- | -------------------------------------------------------------- |
| `summaries/01_dataset_overview.csv`                 | Overall model, version, file, SHA256, and time coverage counts |
| `summaries/02_nsfw_vs_non_nsfw_counts.csv`          | Counts by NSFW category                                        |
| `summaries/03_missingness_overall.csv`              | Missingness summary for key fields                             |
| `summaries/04_missingness_by_category.csv`          | Missingness split by NSFW vs non-NSFW/unknown                  |
| `summaries/12_models_without_versions_or_files.csv` | Records with no versions or no files                           |
| `summaries/13_archived_model_files_by_category.csv` | Archived file mapping coverage                                 |
| `summaries/14_model_source_breakdown.csv`           | Source/provenance field check                                  |

### Composition and ecosystem structure

| File                                                   | Description                                                             |
| ------------------------------------------------------ | ----------------------------------------------------------------------- |
| `summaries/05_model_type_by_category.csv`              | Model type distribution by NSFW category                                |
| `summaries/09_nsfw_base_models.csv`                    | Base model distribution within NSFW                                     |
| `summaries/16_checkpoint_vs_lora_by_category.csv`      | Checkpoint vs. LoRA shares by NSFW category                             |
| `summaries/17_base_model_overlap_nsfw_nonnsfw.csv`     | Declared base-model overlap across NSFW and non-NSFW/unknown categories |
| `summaries/18_nsfw_loras_by_base_model.csv`            | Declared base-model distribution within NSFW LoRAs                      |
| `summaries/19_base_models_30plus_lora_derivatives.csv` | NSFW share of LoRA derivatives per foundation family                    |
| `summaries/22_key_foundation_families_by_category.csv` | Foundation-family counts by category and model type                     |

### Temporal and production-side dynamics

| File                                                | Description                                                              |
| --------------------------------------------------- | ------------------------------------------------------------------------ |
| `summaries/20_foundation_shift_over_time.csv`       | Monthly NSFW LoRA counts for Pony, Illustrious, and WAI-NSFW-Illustrious |
| `summaries/21_creator_concentration_nsfw_loras.csv` | NSFW LoRA creators ranked with cumulative share                          |
| `summaries/15_nsfw_top_creators.csv`                | Top NSFW creators by model count                                         |
| `summaries/10_versions_files_by_category.csv`       | Version and file counts by NSFW category                                 |
| `summaries/11_nsfw_versions_files.csv`              | Version and file summary for NSFW models                                 |

### Stratification of NSFW signals

| File                                       | Description                                |
| ------------------------------------------ | ------------------------------------------ |
| `summaries/06_nsfw_level_distribution.csv` | `nsfwLevel` distribution by category       |
| `summaries/07_nsfw_level_filter_check.csv` | Cross-tab of binary `nsfw` and `nsfwLevel` |

## Main output not included in GitHub

The full joined model-version-file export is intentionally excluded from GitHub:

```text
all_models_full_metadata.csv
```

Reason: this file is large and exceeded the GitHub Enterprise file size limit.

## Notes and limitations

* This dataset is a local metadata snapshot, not a live scrape.
* I did not collect the data myself. I analyzed a shared SQLite snapshot from the CivArchive Discord.
* The underlying collection appears to be based on repeated CivitAI API scans, but the snapshot should not be treated as a live CivitAI scrape.
* `created_at` and `updated_at` refer to when records were collected or added to the database, not necessarily the original CivitAI publication date.
* `published_at` from `model_versions` is used as the closest available model-version publication timestamp.
* NSFW status appears to be available at the model level. Version-level `nsfw` was mostly `NULL` in initial checks, while version-level `nsfwLevel` is available.
* The full joined export contains one row per model-version-file combination, so models with multiple versions or files appear multiple times.
* Base-model tables use version-level `base_model`. A model with multiple versions can appear under multiple declared base-model values.
* `non-NSFW/unknown` combines records where `$.nsfw = 0` and records where the field is missing/NULL.


