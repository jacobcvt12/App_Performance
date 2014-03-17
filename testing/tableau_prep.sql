CREATE TABLE IF NOT EXISTS tableau_tbl(
company TEXT,
rating INTEGER,
reviews INTEGER,
day TEXT);

DELETE FROM tableau_tbl;

INSERT INTO tableau_tbl
SELECT company, rating, count(rating), review_date
FROM Ratings
GROUP BY company, rating, review_date;
