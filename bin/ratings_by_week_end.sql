CREATE TABLE IF NOT EXISTS week_end_reviews AS
SELECT company, rating, review_date, 
DATE(JULIANDAY(review_date) + (6-STRFTIME('%w', review_date))) AS week_end
FROM Ratings;

SELECT company,  week_end, avg(rating) as rating_avg
FROM week_end_reviews
GROUP BY company, week_end
ORDER BY company, DATE(week_end) DESC;

DROP TABLE week_end_reviews;
