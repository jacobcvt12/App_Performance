CREATE TABLE IF NOT EXISTS tableau_tbl(
company TEXT,
version TEXT,
date TEXT,
rating INTEGER,
count INTEGER);

DELETE FROM tableau_tbl;

INSERT INTO tableau_tbl
SELECT company, version, review_date, rating, count(rating)
FROM Ratings
GROUP BY company, DATE(review_date), version, rating
ORDER BY company, DATE(review_date), version, rating;
