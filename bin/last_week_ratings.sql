CREATE TABLE IF NOT EXISTS last_week (company TEXT, review_date TEXT, 
rating_avg, rating_count);

DELETE FROM last_week;

INSERT INTO last_week 
SELECT company, review_date, avg(rating), count(rating)
FROM Ratings
WHERE JULIANDAY(DATE('now')) - JULIANDAY(review_date) < 7
GROUP BY company, review_date
ORDER BY company, DATE(review_date) DESC;
