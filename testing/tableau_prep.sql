CREATE TABLE IF NOT EXISTS tableau_tbl(
company TEXT,
version TEXT,
rating INTEGER,
reviews INTEGER,
day TEXT);

DELETE FROM tableau_tbl;

INSERT INTO tableau_tbl
SELECT company, version, rating, count(rating), review_date
FROM Ratings
GROUP BY company, version, rating, review_date;
