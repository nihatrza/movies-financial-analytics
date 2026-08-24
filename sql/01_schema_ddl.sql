-- 1. DIMENSION TABLES
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    release_date DATE NOT NULL,
    year INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter INT NOT NULL,
    day INT NOT NULL
);

CREATE TABLE dim_genres (
    genre_id INT PRIMARY KEY,
    genre_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE dim_directors (
    director_id INT PRIMARY KEY,
    director_name VARCHAR(150) NOT NULL
);

CREATE TABLE dim_actors (
    actor_id INT PRIMARY KEY,
    actor_name VARCHAR(150) NOT NULL
);

-- 2. FACT TABLE
CREATE TABLE fact_movies (
    movie_id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    date_key INT REFERENCES dim_date(date_key) ON DELETE CASCADE,
    budget NUMERIC(15, 2) DEFAULT 0,
    revenue NUMERIC(15, 2) DEFAULT 0,
    profit NUMERIC(15, 2) GENERATED ALWAYS AS (revenue - budget) STORED,
    runtime INT,
    average_rating NUMERIC(3, 1),
    original_language VARCHAR(10),
    imdb_url VARCHAR(255)
);

-- 3. JUNCTION / BRIDGE TABLES (Many-to-Many Relationships)
CREATE TABLE movie_genres (
    movie_id VARCHAR(50) REFERENCES fact_movies(movie_id) ON DELETE CASCADE,
    genre_id INT REFERENCES dim_genres(genre_id) ON DELETE CASCADE,
    PRIMARY KEY (movie_id, genre_id)
);

CREATE TABLE movie_directors (
    movie_id VARCHAR(50) REFERENCES fact_movies(movie_id) ON DELETE CASCADE,
    director_id INT REFERENCES dim_directors(director_id) ON DELETE CASCADE,
    PRIMARY KEY (movie_id, director_id)
);

CREATE TABLE movie_actors (
    movie_id VARCHAR(50) REFERENCES fact_movies(movie_id) ON DELETE CASCADE,
    actor_id INT REFERENCES dim_actors(actor_id) ON DELETE CASCADE,
    PRIMARY KEY (movie_id, actor_id)
);