-- Count of daily event 

SELECT 
    year,
    month,
    day,
    COUNT(*) as event_count,
    AVG(value) as avg_value,
    MIN(value) as min_value,
    MAX(value) as max_value
FROM ede_dev.validated_events
WHERE year = 2025 AND month = 1
GROUP BY year, month, day
ORDER BY year, month, day;

-- Events by hour 
SELECT 
    DATE_TRUNC('hour', CAST(ts AS TIMESTAMP)) as hour,
    COUNT(*) as event_count
FROM ede_dev.validated_events
WHERE year = 2025 AND month = 1 AND day = 27
GROUP BY DATE_TRUNC('hour', CAST(ts AS TIMESTAMP))
ORDER BY hour;

-- Find anomalies 
WITH stats AS (
    SELECT 
        AVG(value) as mean_value,
        STDDEV(value) as stddev_value
    FROM ede_dev.validated_events
    WHERE year = 2025
)
SELECT 
    e.id,
    e.ts,
    e.value,
    s.mean_value,
    s.stddev_value,
    ABS(e.value - s.mean_value) / s.stddev_value as z_score
FROM ede_dev.validated_events e
CROSS JOIN stats s
WHERE ABS(e.value - s.mean_value) > 2 * s.stddev_value
ORDER BY z_score DESC;

-- Data quality metrics
SELECT 
    year,
    month,
    day,
    COUNT(*) as total_records,
    COUNT(DISTINCT id) as unique_ids,
    COUNT(*) - COUNT(DISTINCT id) as duplicate_count,
    COUNT(CASE WHEN value IS NULL THEN 1 END) as null_count
FROM ede_dev.validated_events
WHERE year = 2025
GROUP BY year, month, day
ORDER BY year DESC, month DESC, day DESC;