-- 1. OUTLIER REMOVAL: Remove micro-budget anomalies (< $10,000)
DELETE FROM fact_movies 
WHERE budget < 10000;

-- 2. RUNTIME FILTERING: Remove short films (< 40 mins), invalid runtimes, and extreme outliers (> 300 mins)
DELETE FROM fact_movies 
WHERE runtime < 40 
   OR runtime > 300 
   OR runtime IS NULL;

-- 3. DATE RESTRICTION: Restrict dataset strictly to 100 Years of Cinema (1923-2023)
-- Step A: Remove movies from fact table outside the 1923-2023 range
DELETE FROM fact_movies 
WHERE date_key IN (
    SELECT date_key 
    FROM dim_date 
    WHERE year < 1923 OR year > 2023
);

-- Step B: Clean dim_date table for years outside 1923-2023
DELETE FROM dim_date 
WHERE year < 1923 OR year > 2023;

-- 4. ORPHAN CLEANUP: Remove directors/actors/genres not linked to any remaining movies
DELETE FROM dim_directors 
WHERE director_id NOT IN (SELECT DISTINCT director_id FROM movie_directors);

DELETE FROM dim_actors 
WHERE actor_id NOT IN (SELECT DISTINCT actor_id FROM movie_actors);

DELETE FROM dim_genres 
WHERE genre_id NOT IN (SELECT DISTINCT genre_id FROM movie_genres);