BEGIN TRANSACTION;

-- 1. Safely empty target (retaining partition, cluster, and option properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.editions`;

-- 2. Extract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.editions` (
  id,
  created_at,
  updated_at,
  document_id,
  state,
  type,
  major_change_published_at,
  first_published_at,
  force_published,
  public_timestamp,
  scheduled_publication,
  access_limited,
  opening_at,
  closing_at,
  political,
  primary_locale,
  auth_bypass_id,
  government_id,
  slug
)
SELECT
  id,
  created_at,
  updated_at,
  document_id,
  state,
  type,
  major_change_published_at,
  -- 1. Convert STRING format to proper TIMESTAMPS safely 
  SAFE_CAST(first_published_at AS TIMESTAMP) AS first_published_at,
  
  -- 2. Convert INT64 or STRING safely to BOOLEAN (0/'0' -> FALSE, non-zero/'1'/'true' -> TRUE)
  CASE 
    WHEN force_published IS NULL THEN FALSE
    WHEN SAFE_CAST(force_published AS INT64) = 0 THEN FALSE
    WHEN SAFE_CAST(force_published AS INT64) > 0 THEN TRUE
    WHEN LOWER(TRIM(CAST(force_published AS STRING))) IN ('true', '1', 'yes') THEN TRUE
    ELSE FALSE
  END AS force_published,
  
  -- 3. Convert STRING to TIMESTAMP safely
  SAFE_CAST(public_timestamp AS TIMESTAMP) AS public_timestamp,
  scheduled_publication,
  
  -- 4. Convert access_limiting (enum string) to BOOLEAN safely
  -- If access_limiting is NULL or 'none', it is not limited (FALSE). Any other value means it is limited (TRUE).
  CASE 
    WHEN access_limiting IS NULL OR TRIM(LOWER(CAST(access_limiting AS STRING))) = 'none' THEN FALSE
    ELSE TRUE
  END AS access_limited,
  
  opening_at,
  closing_at,
  
  -- 5. Convert FLOAT64 to BOOLEAN.
  -- (Since BigQuery cannot cast FLOAT64 directly to BOOL, a CASE statement is the safest method)
  CASE 
    WHEN political IS NULL THEN NULL
    WHEN political = 0.0 THEN FALSE
    ELSE TRUE 
  END AS political,
  
  primary_locale,
  auth_bypass_id,
  government_id,
  slug
FROM `{project_id}.{raw_dataset}.editions`;

COMMIT TRANSACTION;