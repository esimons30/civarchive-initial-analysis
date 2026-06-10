-- Initial CivitAI Metadata Analysis Queries
-- Database file: civitai.sqlite

-- 01_all_models_full_metadata
-- Full joined model-version-file metadata export.
-- Note: this output can be very large and should usually NOT be committed to GitHub.

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
