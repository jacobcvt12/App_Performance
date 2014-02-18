CREATE TABLE IF NOT EXISTS ratings_by_week (company TEXT, week_end TEXT, 
review_avg REAL, review_count INTEGER);

DELETE FROM ratings_by_week;

INSERT INTO ratings_by_week 
SELECT company,  week_end, avg(rating), count(rating)
FROM week_end_reviews
GROUP BY company, week_end
ORDER BY company, DATE(week_end) DESC;
