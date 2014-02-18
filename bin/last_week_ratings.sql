-- CREATE TABLE IF NOT EXISTS last_week AS
SELECT company, rating, review_date, DATE('now'), JULIANDAY(DATE('now')), JULIANDAY(review_date)
FROM Ratings
--GROUP BY company, review_date
WHERE JULIANDAY(DATE('now')) - JULIANDAY(review_date) < 7
ORDER BY company, DATE(review_date) DESC;
