-- -----------------------------------------------------------------------------
-- QUERY 1: Yearly Revenue Trend, YoY Growth %, and Cumulative Profit
-- Window functions: LAG() and SUM() OVER()
-- -----------------------------------------------------------------------------
WITH YearlyFinancials AS (
    SELECT 
        d.year,
        COUNT(f.movie_id) AS total_movies,
        SUM(f.budget) AS total_budget,
        SUM(f.revenue) AS total_revenue,
        SUM(f.revenue - f.budget) AS total_profit
    FROM fact_movies f
    JOIN dim_date d ON f.date_key = d.date_key
    GROUP BY d.year
)
SELECT 
    year,
    total_movies,
    ROUND(total_revenue / 1000000, 2) AS revenue_million_usd,
    ROUND(
        ((total_revenue - LAG(total_revenue) OVER (ORDER BY year)) / 
        NULLIF(LAG(total_revenue) OVER (ORDER BY year), 0)) * 100, 2
    ) AS yoy_revenue_growth_pct,
    ROUND(SUM(total_profit) OVER (ORDER BY year) / 1000000, 2) AS cumulative_profit_million_usd
FROM YearlyFinancials
ORDER BY year DESC;

-- -----------------------------------------------------------------------------
-- QUERY 2: Top 10 Directors by ROI % (Minimum 3 Movies)
-- Aggregation and HAVING filtering
-- -----------------------------------------------------------------------------
WITH DirectorStats AS (
    SELECT 
        d.director_name,
        COUNT(f.movie_id) AS movie_count,
        SUM(f.budget) AS total_budget,
        SUM(f.revenue) AS total_revenue,
        SUM(f.revenue - f.budget) AS total_profit
    FROM fact_movies f
    JOIN bridge_movie_directors bd ON f.movie_id = bd.movie_id
    JOIN dim_directors d ON bd.director_id = d.director_id
    GROUP BY d.director_name
    HAVING COUNT(f.movie_id) >= 3 AND SUM(f.budget) > 0
)
SELECT 
    director_name,
    movie_count,
    ROUND(total_budget / 1000000, 2) AS budget_mil_usd,
    ROUND(total_revenue / 1000000, 2) AS revenue_mil_usd,
    ROUND((total_profit / total_budget) * 100, 2) AS avg_roi_pct
FROM DirectorStats
ORDER BY avg_roi_pct DESC
LIMIT 10;

-- -----------------------------------------------------------------------------
-- QUERY 3: Genre Profit Margin & Profitability Ranking
-- Window function: DENSE_RANK()
-- -----------------------------------------------------------------------------
WITH GenrePerformance AS (
    SELECT 
        g.genre_name,
        COUNT(f.movie_id) AS movie_count,
        SUM(f.budget) AS total_budget,
        SUM(f.revenue) AS total_revenue,
        SUM(f.revenue - f.budget) AS total_profit,
        AVG(f.average_rating) AS avg_imdb_rating
    FROM fact_movies f
    JOIN bridge_movie_genres bg ON f.movie_id = bg.movie_id
    JOIN dim_genres g ON bg.genre_id = g.genre_id
    GROUP BY g.genre_name
)
SELECT 
    genre_name,
    movie_count,
    ROUND(total_revenue / 1000000, 2) AS revenue_mil_usd,
    ROUND((total_profit / NULLIF(total_revenue, 0)) * 100, 2) AS profit_margin_pct,
    ROUND(avg_imdb_rating, 2) AS avg_rating,
    DENSE_RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM GenrePerformance
ORDER BY profit_rank;

-- -----------------------------------------------------------------------------
-- QUERY 4: Actor "Star Power" & Box Office Impact (Minimum 5 Movies)
-- Joining bridge cast tables with aggregation
-- -----------------------------------------------------------------------------
SELECT 
    a.actor_name,
    COUNT(f.movie_id) AS total_movies,
    ROUND(AVG(f.revenue) / 1000000, 2) AS avg_revenue_per_movie_mil,
    ROUND(SUM(f.revenue) / 1000000, 2) AS cumulative_box_office_mil,
    ROUND(AVG(f.average_rating), 2) AS avg_imdb_rating
FROM fact_movies f
JOIN bridge_movie_cast bc ON f.movie_id = bc.movie_id
JOIN dim_cast a ON bc.actor_id = a.actor_id
GROUP BY a.actor_name
HAVING COUNT(f.movie_id) >= 5
ORDER BY avg_revenue_per_movie_mil DESC
LIMIT 10;

-- -----------------------------------------------------------------------------
-- QUERY 5: Seasonality & Monthly Box Office Performance
-- Time-based seasonality analysis
-- -----------------------------------------------------------------------------
SELECT 
    d.month,
    d.month_name,
    COUNT(f.movie_id) AS released_movies,
    ROUND(AVG(f.budget) / 1000000, 2) AS avg_budget_mil,
    ROUND(AVG(f.revenue) / 1000000, 2) AS avg_revenue_mil,
    ROUND((AVG(f.revenue) - AVG(f.budget)) / NULLIF(AVG(f.budget), 0) * 100, 2) AS avg_monthly_roi_pct
FROM fact_movies f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.month, d.month_name
ORDER BY d.month;