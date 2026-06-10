-- Civarchive Analysis Queries
-- Database file: civitai.sqlite

-- 01_all_models_full_metadata

SELECT
  CASE
    WHEN json_extract(m.data, '$.nsfw') = 1 THEN 'NSFW'
    ELSE 'non-NSFW/unknown'
  END AS category,

  m.id AS model_id,
  m.name AS model_name,
  m.type AS model_type,
  m.username AS creator,
  json_extract(m.data, '$.nsfw') AS model_nsfw,
  json_extract(m.data, '$.nsfwLevel') AS model_nsfwLevel,
  m.created_at AS model_created_at,
  m.updated_at AS model_updated_at,

  v.id AS version_id,
  v.name AS version_name,
  v.position AS version_position,
  v.base_model,
  v.published_at,
  json_extract(v.data, '$.nsfwLevel') AS version_nsfwLevel,
  v.created_at AS version_created_at,
  v.updated_at AS version_updated_at,

  f.id AS file_id,
  f.type AS file_type,
  f.sha256,
  f.created_at AS file_created_at,
  f.updated_at AS file_updated_at,

  m.data AS model_json,
  v.data AS version_json,
  f.data AS file_json

FROM models m
LEFT JOIN model_versions v
  ON m.id = v.model_id
LEFT JOIN model_files f
  ON v.id = f.version_id;


-- 02_dataset_overview

SELECT
  COUNT(DISTINCT m.id) AS total_models,
  COUNT(DISTINCT v.id) AS total_versions,
  COUNT(DISTINCT f.id) AS total_files,
  COUNT(DISTINCT CASE WHEN f.sha256 IS NOT NULL AND f.sha256 != '' THEN f.id END) AS files_with_sha256,
  datetime(MIN(v.published_at), 'unixepoch') AS earliest_published_at,
  datetime(MAX(v.published_at), 'unixepoch') AS latest_published_at
FROM models m
LEFT JOIN model_versions v
  ON m.id = v.model_id
LEFT JOIN model_files f
  ON v.id = f.version_id;


-- 03_nsfw_vs_non_nsfw_counts

SELECT
  CASE
    WHEN json_extract(m.data, '$.nsfw') = 1 THEN 'NSFW'
    ELSE 'non-NSFW/unknown'
  END AS category,

  COUNT(DISTINCT m.id) AS models,
  COUNT(DISTINCT v.id) AS versions,
  COUNT(DISTINCT f.id) AS files,
  COUNT(DISTINCT CASE WHEN f.sha256 IS NOT NULL AND f.sha256 != '' THEN f.id END) AS files_with_sha256

FROM models m
LEFT JOIN model_versions v
  ON m.id = v.model_id
LEFT JOIN model_files f
  ON v.id = f.version_id

GROUP BY category
ORDER BY category;


-- 04_missingness_summary

WITH totals AS (
  SELECT
    COUNT(DISTINCT m.id) AS total_models,
    COUNT(DISTINCT v.id) AS total_versions,
    COUNT(DISTINCT f.id) AS total_files
  FROM models m
  LEFT JOIN model_versions v
    ON m.id = v.model_id
  LEFT JOIN model_files f
    ON v.id = f.version_id
)

SELECT
  'username' AS field,
  COUNT(DISTINCT CASE WHEN m.username IS NULL OR m.username = '' THEN m.id END) AS missing_count,
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN m.username IS NULL OR m.username = '' THEN m.id END)
    / (SELECT total_models FROM totals),
    2
  ) AS missing_percent
FROM models m

UNION ALL

SELECT
  'published_at' AS field,
  COUNT(DISTINCT CASE WHEN v.published_at IS NULL THEN v.id END) AS missing_count,
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN v.published_at IS NULL THEN v.id END)
    / (SELECT total_versions FROM totals),
    2
  ) AS missing_percent
FROM model_versions v

UNION ALL

SELECT
  'sha256' AS field,
  COUNT(DISTINCT CASE WHEN f.sha256 IS NULL OR f.sha256 = '' THEN f.id END) AS missing_count,
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN f.sha256 IS NULL OR f.sha256 = '' THEN f.id END)
    / (SELECT total_files FROM totals),
    2
  ) AS missing_percent
FROM model_files f

UNION ALL

SELECT
  'model_nsfwLevel' AS field,
  COUNT(DISTINCT CASE WHEN json_extract(m.data, '$.nsfwLevel') IS NULL THEN m.id END) AS missing_count,
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN json_extract(m.data, '$.nsfwLevel') IS NULL THEN m.id END)
    / (SELECT total_models FROM totals),
    2
  ) AS missing_percent
FROM models m;


-- 05_model_type_by_category

SELECT
  CASE
    WHEN json_extract(m.data, '$.nsfw') = 1 THEN 'NSFW'
    ELSE 'non-NSFW/unknown'
  END AS category,
  m.type AS model_type,
  COUNT(DISTINCT m.id) AS models,
  COUNT(DISTINCT v.id) AS versions,
  COUNT(DISTINCT f.id) AS files
FROM models m
LEFT JOIN model_versions v
  ON m.id = v.model_id
LEFT JOIN model_files f
  ON v.id = f.version_id
GROUP BY category, m.type
ORDER BY category, models DESC;


-- 06_base_model_by_category

SELECT
  CASE
    WHEN json_extract(m.data, '$.nsfw') = 1 THEN 'NSFW'
    ELSE 'non-NSFW/unknown'
  END AS category,
  v.base_model,
  COUNT(DISTINCT m.id) AS models,
  COUNT(DISTINCT v.id) AS versions,
  COUNT(DISTINCT f.id) AS files
FROM models m
LEFT JOIN model_versions v
  ON m.id = v.model_id
LEFT JOIN model_files f
  ON v.id = f.version_id
GROUP BY category, v.base_model
ORDER BY category, models DESC;


-- 07_nsfw_level_distribution

SELECT
  CASE
    WHEN json_extract(m.data, '$.nsfw') = 1 THEN 'NSFW'
    ELSE 'non-NSFW/unknown'
  END AS category,
  json_extract(m.data, '$.nsfwLevel') AS model_nsfwLevel,
  COUNT(DISTINCT m.id) AS models
FROM models m
GROUP BY category, model_nsfwLevel
ORDER BY category, models DESC;


```sql
-- 08_nsfw_level_filter_check
-- Cross-check binary model-level nsfw flag against model-level nsfwLevel.

SELECT
  json_extract(m.data, '$.nsfw') AS model_nsfw,
  json_extract(m.data, '$.nsfwLevel') AS model_nsfwLevel,
  COUNT(DISTINCT m.id) AS models
FROM models m
GROUP BY model_nsfw, model_nsfwLevel
ORDER BY model_nsfw, models DESC;


-- 09_nsfw_base_models
-- Declared base_model distribution within NSFW models.
-- Note: base_model is version-level, so a model with versions under multiple base_model values
-- can appear in more than one base_model group.

WITH nsfw_base AS (
  SELECT DISTINCT
    m.id AS model_id,
    v.id AS version_id,
    f.id AS file_id,
    COALESCE(v.base_model, 'NULL/unknown') AS base_model
  FROM models m
  LEFT JOIN model_versions v
    ON m.id = v.model_id
  LEFT JOIN model_files f
    ON v.id = f.version_id
  WHERE json_extract(m.data, '$.nsfw') = 1
),

total AS (
  SELECT COUNT(DISTINCT model_id) AS total_nsfw_models
  FROM nsfw_base
)

SELECT
  base_model,
  COUNT(DISTINCT model_id) AS nsfw_models,
  COUNT(DISTINCT version_id) AS nsfw_versions,
  COUNT(DISTINCT file_id) AS nsfw_files,
  ROUND(
    100.0 * COUNT(DISTINCT model_id) / (SELECT total_nsfw_models FROM total),
    2
  ) AS percent_of_nsfw_models
FROM nsfw_base
GROUP BY base_model
ORDER BY nsfw_models DESC;


-- 10_versions_files_by_category
-- Version and file coverage by NSFW category.

SELECT
  CASE
    WHEN json_extract(m.data, '$.nsfw') = 1 THEN 'NSFW'
    ELSE 'non-NSFW/unknown'
  END AS category,

  COUNT(DISTINCT m.id) AS models,
  COUNT(DISTINCT v.id) AS versions,
  COUNT(DISTINCT f.id) AS files,
  COUNT(DISTINCT CASE WHEN f.sha256 IS NOT NULL AND f.sha256 != '' THEN f.id END) AS files_with_sha256,

  ROUND(
    1.0 * COUNT(DISTINCT v.id) / COUNT(DISTINCT m.id),
    3
  ) AS versions_per_model,

  ROUND(
    1.0 * COUNT(DISTINCT f.id) / COUNT(DISTINCT m.id),
    3
  ) AS files_per_model

FROM models m
LEFT JOIN model_versions v
  ON m.id = v.model_id
LEFT JOIN model_files f
  ON v.id = f.version_id
GROUP BY category
ORDER BY category;


-- 11_nsfw_versions_files
-- Version and file coverage within NSFW models, split by model type.

SELECT
  m.type AS model_type,

  COUNT(DISTINCT m.id) AS nsfw_models,
  COUNT(DISTINCT v.id) AS nsfw_versions,
  COUNT(DISTINCT f.id) AS nsfw_files,
  COUNT(DISTINCT CASE WHEN f.sha256 IS NOT NULL AND f.sha256 != '' THEN f.id END) AS nsfw_files_with_sha256,

  ROUND(
    1.0 * COUNT(DISTINCT v.id) / COUNT(DISTINCT m.id),
    3
  ) AS versions_per_model,

  ROUND(
    1.0 * COUNT(DISTINCT f.id) / COUNT(DISTINCT m.id),
    3
  ) AS files_per_model

FROM models m
LEFT JOIN model_versions v
  ON m.id = v.model_id
LEFT JOIN model_files f
  ON v.id = f.version_id
WHERE json_extract(m.data, '$.nsfw') = 1
GROUP BY m.type
ORDER BY nsfw_models DESC;


-- 12_models_without_versions_or_files
-- Relational data quality check: models without versions and versions without files.

WITH models_without_versions AS (
  SELECT
    m.id AS model_id,
    CASE
      WHEN json_extract(m.data, '$.nsfw') = 1 THEN 'NSFW'
      ELSE 'non-NSFW/unknown'
    END AS category
  FROM models m
  LEFT JOIN model_versions v
    ON m.id = v.model_id
  WHERE v.id IS NULL
),

versions_without_files AS (
  SELECT
    v.id AS version_id,
    m.id AS model_id,
    CASE
      WHEN json_extract(m.data, '$.nsfw') = 1 THEN 'NSFW'
      ELSE 'non-NSFW/unknown'
    END AS category
  FROM model_versions v
  LEFT JOIN models m
    ON m.id = v.model_id
  LEFT JOIN model_files f
    ON v.id = f.version_id
  WHERE f.id IS NULL
)

SELECT
  category,
  COUNT(DISTINCT model_id) AS models_without_versions,
  0 AS versions_without_files
FROM models_without_versions
GROUP BY category

UNION ALL

SELECT
  category,
  0 AS models_without_versions,
  COUNT(DISTINCT version_id) AS versions_without_files
FROM versions_without_files
GROUP BY category

ORDER BY category;


-- 13_archived_model_files_by_category
-- Archived file mappings by NSFW category.

SELECT
  CASE
    WHEN json_extract(m.data, '$.nsfw') = 1 THEN 'NSFW'
    ELSE 'non-NSFW/unknown'
  END AS category,

  COUNT(DISTINCT a.file_id) AS archived_file_ids,
  COUNT(DISTINCT a.model_id) AS archived_models,
  COUNT(DISTINCT a.version_id) AS archived_versions

FROM archived_model_files a
LEFT JOIN models m
  ON a.model_id = m.id
GROUP BY category
ORDER BY category;


-- 14_model_source_breakdown
-- Source/provenance diagnostics from possible _source/source fields.
-- This is mainly a data-quality check. Interpret cautiously.

SELECT
  COALESCE(
    json_extract(m.data, '$._source'),
    json_extract(m.data, '$.source'),
    json_extract(v.data, '$._source'),
    json_extract(v.data, '$.source'),
    json_extract(f.data, '$._source'),
    json_extract(f.data, '$.source'),
    'NULL/unknown'
  ) AS source_value,

  COUNT(DISTINCT m.id) AS models,
  COUNT(DISTINCT v.id) AS versions,
  COUNT(DISTINCT f.id) AS files

FROM models m
LEFT JOIN model_versions v
  ON m.id = v.model_id
LEFT JOIN model_files f
  ON v.id = f.version_id
GROUP BY source_value
ORDER BY models DESC;


-- 15_nsfw_top_creators
-- Top creators by NSFW model count.

WITH nsfw_models AS (
  SELECT DISTINCT
    m.id AS model_id,
    COALESCE(NULLIF(m.username, ''), 'NULL/unknown') AS creator
  FROM models m
  WHERE json_extract(m.data, '$.nsfw') = 1
),

total AS (
  SELECT COUNT(DISTINCT model_id) AS total_nsfw_models
  FROM nsfw_models
),

creator_counts AS (
  SELECT
    creator,
    COUNT(DISTINCT model_id) AS nsfw_models
  FROM nsfw_models
  GROUP BY creator
)

SELECT
  creator,
  nsfw_models,
  ROUND(
    100.0 * nsfw_models / (SELECT total_nsfw_models FROM total),
    4
  ) AS percent_of_nsfw_models
FROM creator_counts
ORDER BY nsfw_models DESC
LIMIT 100;


-- 16_checkpoint_vs_lora_by_category
-- Checkpoint vs LoRA split by NSFW category.

SELECT
  CASE
    WHEN json_extract(m.data, '$.nsfw') = 1 THEN 'NSFW'
    ELSE 'non-NSFW/unknown'
  END AS category,

  CASE
    WHEN LOWER(m.type) = 'checkpoint' THEN 'Checkpoint'
    WHEN LOWER(m.type) LIKE '%lora%' THEN 'LORA'
    ELSE 'Other'
  END AS model_type_group,

  COUNT(DISTINCT m.id) AS models,
  COUNT(DISTINCT v.id) AS versions,
  COUNT(DISTINCT f.id) AS files,
  COUNT(DISTINCT CASE WHEN f.sha256 IS NOT NULL AND f.sha256 != '' THEN f.id END) AS files_with_sha256

FROM models m
LEFT JOIN model_versions v
  ON m.id = v.model_id
LEFT JOIN model_files f
  ON v.id = f.version_id

WHERE LOWER(m.type) = 'checkpoint'
   OR LOWER(m.type) LIKE '%lora%'

GROUP BY category, model_type_group
ORDER BY category, models DESC;


-- 17_base_model_overlap_nsfw_nonnsfw
-- Declared base_model overlap between NSFW and non-NSFW/unknown.

WITH model_base_pairs AS (
  SELECT DISTINCT
    m.id AS model_id,
    COALESCE(v.base_model, 'NULL/unknown') AS base_model,
    CASE
      WHEN json_extract(m.data, '$.nsfw') = 1 THEN 'NSFW'
      ELSE 'non-NSFW/unknown'
    END AS category
  FROM models m
  LEFT JOIN model_versions v
    ON m.id = v.model_id
)

SELECT
  base_model,

  COUNT(DISTINCT CASE WHEN category = 'NSFW' THEN model_id END) AS nsfw_models,
  COUNT(DISTINCT CASE WHEN category = 'non-NSFW/unknown' THEN model_id END) AS non_nsfw_unknown_models,

  CASE
    WHEN COUNT(DISTINCT CASE WHEN category = 'NSFW' THEN model_id END) > 0
     AND COUNT(DISTINCT CASE WHEN category = 'non-NSFW/unknown' THEN model_id END) > 0
    THEN 1
    ELSE 0
  END AS appears_in_both_categories,

  COUNT(DISTINCT model_id) AS total_models

FROM model_base_pairs
GROUP BY base_model
ORDER BY appears_in_both_categories DESC, total_models DESC;


-- 18_nsfw_loras_by_base_model
-- NSFW LoRAs by declared base_model.

WITH nsfw_lora_base AS (
  SELECT DISTINCT
    m.id AS model_id,
    COALESCE(v.base_model, 'NULL/unknown') AS base_model
  FROM models m
  LEFT JOIN model_versions v
    ON m.id = v.model_id
  WHERE json_extract(m.data, '$.nsfw') = 1
    AND LOWER(m.type) LIKE '%lora%'
),

total AS (
  SELECT COUNT(DISTINCT model_id) AS total_nsfw_lora_models
  FROM nsfw_lora_base
)

SELECT
  base_model,
  COUNT(DISTINCT model_id) AS nsfw_lora_models,
  ROUND(
    100.0 * COUNT(DISTINCT model_id) / (SELECT total_nsfw_lora_models FROM total),
    2
  ) AS percent_of_nsfw_lora_models

FROM nsfw_lora_base
GROUP BY base_model
ORDER BY nsfw_lora_models DESC;


-- 19_base_models_30plus_lora_derivatives
-- Base models with at least 30 LoRA derivatives and at least 30 NSFW LoRA derivatives.

WITH lora_base AS (
  SELECT DISTINCT
    m.id AS model_id,
    COALESCE(v.base_model, 'NULL/unknown') AS base_model,
    CASE
      WHEN json_extract(m.data, '$.nsfw') = 1 THEN 'NSFW'
      ELSE 'non-NSFW/unknown'
    END AS category
  FROM models m
  LEFT JOIN model_versions v
    ON m.id = v.model_id
  WHERE LOWER(m.type) LIKE '%lora%'
)

SELECT
  base_model,

  COUNT(DISTINCT model_id) AS total_lora_derivatives,
  COUNT(DISTINCT CASE WHEN category = 'NSFW' THEN model_id END) AS nsfw_lora_derivatives,
  COUNT(DISTINCT CASE WHEN category = 'non-NSFW/unknown' THEN model_id END) AS non_nsfw_unknown_lora_derivatives,

  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN category = 'NSFW' THEN model_id END)
    / COUNT(DISTINCT model_id),
    2
  ) AS percent_lora_derivatives_nsfw

FROM lora_base
GROUP BY base_model
HAVING total_lora_derivatives >= 30
   AND nsfw_lora_derivatives >= 30
ORDER BY nsfw_lora_derivatives DESC;


-- 20_foundation_shift_over_time
-- Pony vs Illustrious / WAI-NSFW-Illustrious over time using published_at.
-- Month-level counts, NSFW LoRAs only.
-- This parser handles Unix seconds, Unix milliseconds, and ISO/text datetime values.

WITH nsfw_lora_versions AS (
  SELECT DISTINCT
    m.id AS model_id,
    v.id AS version_id,

    CASE
      WHEN v.published_at IS NULL THEN NULL

      -- Unix timestamp in milliseconds
      WHEN CAST(v.published_at AS TEXT) NOT GLOB '*[^0-9]*'
       AND LENGTH(CAST(v.published_at AS TEXT)) >= 13
      THEN datetime(CAST(v.published_at AS INTEGER) / 1000, 'unixepoch')

      -- Unix timestamp in seconds
      WHEN CAST(v.published_at AS TEXT) NOT GLOB '*[^0-9]*'
      THEN datetime(CAST(v.published_at AS INTEGER), 'unixepoch')

      -- ISO/text datetime
      ELSE datetime(
        REPLACE(
          REPLACE(CAST(v.published_at AS TEXT), 'T', ' '),
          'Z',
          ''
        )
      )
    END AS published_datetime,

    CASE
      WHEN LOWER(COALESCE(v.base_model, '') || ' ' || COALESCE(m.name, '') || ' ' || COALESCE(v.name, '')) LIKE '%wai%nsfw%illustrious%'
        THEN 'WAI-NSFW-Illustrious'
      WHEN LOWER(COALESCE(v.base_model, '') || ' ' || COALESCE(m.name, '') || ' ' || COALESCE(v.name, '')) LIKE '%illustrious%'
        THEN 'Illustrious'
      WHEN LOWER(COALESCE(v.base_model, '') || ' ' || COALESCE(m.name, '') || ' ' || COALESCE(v.name, '')) LIKE '%pony%'
        THEN 'Pony'
      ELSE 'Other'
    END AS foundation_family

  FROM models m
  LEFT JOIN model_versions v
    ON m.id = v.model_id
  WHERE json_extract(m.data, '$.nsfw') = 1
    AND LOWER(m.type) LIKE '%lora%'
    AND v.published_at IS NOT NULL
),

formatted AS (
  SELECT
    model_id,
    version_id,
    strftime('%Y-%m', published_datetime) AS published_month,
    foundation_family
  FROM nsfw_lora_versions
  WHERE published_datetime IS NOT NULL
)

SELECT
  published_month,
  foundation_family,
  COUNT(DISTINCT model_id) AS nsfw_lora_models,
  COUNT(DISTINCT version_id) AS nsfw_lora_versions

FROM formatted
WHERE foundation_family IN ('Pony', 'Illustrious', 'WAI-NSFW-Illustrious')
  AND published_month IS NOT NULL

GROUP BY published_month, foundation_family
ORDER BY published_month, foundation_family;


-- 21_creator_concentration_nsfw_loras
-- Creator concentration among NSFW LoRAs.

WITH nsfw_loras AS (
  SELECT DISTINCT
    m.id AS model_id,
    COALESCE(NULLIF(m.username, ''), 'NULL/unknown') AS creator
  FROM models m
  WHERE json_extract(m.data, '$.nsfw') = 1
    AND LOWER(m.type) LIKE '%lora%'
),

creator_counts AS (
  SELECT
    creator,
    COUNT(DISTINCT model_id) AS nsfw_lora_models
  FROM nsfw_loras
  GROUP BY creator
),

total AS (
  SELECT COUNT(DISTINCT model_id) AS total_nsfw_lora_models
  FROM nsfw_loras
),

ranked AS (
  SELECT
    creator,
    nsfw_lora_models,
    ROUND(100.0 * nsfw_lora_models / (SELECT total_nsfw_lora_models FROM total), 4) AS percent_of_nsfw_loras,
    ROW_NUMBER() OVER (ORDER BY nsfw_lora_models DESC) AS creator_rank,
    SUM(nsfw_lora_models) OVER (
      ORDER BY nsfw_lora_models DESC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_nsfw_lora_models
  FROM creator_counts
)

SELECT
  creator_rank,
  creator,
  nsfw_lora_models,
  percent_of_nsfw_loras,
  cumulative_nsfw_lora_models,
  ROUND(
    100.0 * cumulative_nsfw_lora_models / (SELECT total_nsfw_lora_models FROM total),
    2
  ) AS cumulative_percent_of_nsfw_loras

FROM ranked
ORDER BY creator_rank;


-- 22_key_foundation_families_by_category
-- Key foundation-family table for Pony, Illustrious, WAI, Juggernaut, SDXL, SD 1.5, and Flux.

WITH model_base_pairs AS (
  SELECT DISTINCT
    m.id AS model_id,
    m.type AS model_type,
    v.id AS version_id,
    COALESCE(v.base_model, 'NULL/unknown') AS base_model,

    CASE
      WHEN json_extract(m.data, '$.nsfw') = 1 THEN 'NSFW'
      ELSE 'non-NSFW/unknown'
    END AS category,

    CASE
      WHEN LOWER(COALESCE(v.base_model, '') || ' ' || COALESCE(m.name, '') || ' ' || COALESCE(v.name, '')) LIKE '%wai%nsfw%illustrious%'
        THEN 'WAI-NSFW-Illustrious'
      WHEN LOWER(COALESCE(v.base_model, '') || ' ' || COALESCE(m.name, '') || ' ' || COALESCE(v.name, '')) LIKE '%illustrious%'
        THEN 'Illustrious'
      WHEN LOWER(COALESCE(v.base_model, '') || ' ' || COALESCE(m.name, '') || ' ' || COALESCE(v.name, '')) LIKE '%pony%'
        THEN 'Pony'
      WHEN LOWER(COALESCE(v.base_model, '') || ' ' || COALESCE(m.name, '') || ' ' || COALESCE(v.name, '')) LIKE '%juggernaut%'
        THEN 'Juggernaut'
      WHEN LOWER(COALESCE(v.base_model, '') || ' ' || COALESCE(m.name, '') || ' ' || COALESCE(v.name, '')) LIKE '%sdxl%'
        THEN 'SDXL'
      WHEN LOWER(COALESCE(v.base_model, '')) LIKE '%sd 1.5%'
        OR LOWER(COALESCE(v.base_model, '')) LIKE '%sd1.5%'
        OR LOWER(COALESCE(v.base_model, '')) LIKE '%stable diffusion 1.5%'
        THEN 'SD 1.5'
      WHEN LOWER(COALESCE(v.base_model, '') || ' ' || COALESCE(m.name, '') || ' ' || COALESCE(v.name, '')) LIKE '%flux%'
        THEN 'Flux'
      ELSE 'Other'
    END AS foundation_family

  FROM models m
  LEFT JOIN model_versions v
    ON m.id = v.model_id
)

SELECT
  category,
  foundation_family,

  COUNT(DISTINCT model_id) AS models,
  COUNT(DISTINCT CASE WHEN LOWER(model_type) = 'checkpoint' THEN model_id END) AS checkpoint_models,
  COUNT(DISTINCT CASE WHEN LOWER(model_type) LIKE '%lora%' THEN model_id END) AS lora_models,
  COUNT(DISTINCT version_id) AS versions

FROM model_base_pairs
WHERE foundation_family != 'Other'
GROUP BY category, foundation_family
ORDER BY category, models DESC;
```
