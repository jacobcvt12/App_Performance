-- update_tables.sql is used to create/update tables based on the initial 
-- ratings table. The created tables will then be used by R for some plots
-- to compare performance over time of all companies
-- these queries were designed to run on a sqlite database and may not be 
-- portable to all other database types

-- week_end_reviews contains all fields from ratings table
-- plus calculated week_end (week ending) field
-- could consider turning this query into an update query
-- on ratings
CREATE TABLE IF NOT EXISTS week_end_reviews (company TEXT, rating INTEGER, review_date TEXT, week_end TEXT);

DELETE FROM week_end_reviews;

INSERT INTO week_end_reviews
SELECT company, rating, review_date, 
DATE(JULIANDAY(review_date) + (6-STRFTIME('%w', review_date))) AS week_end
FROM Ratings;

-- ratings_by_week uses the week_end_reviews
-- to summarize on company and week ending
-- and calculate the average rating in a week
-- as well as count the number of ratings in a week
CREATE TABLE IF NOT EXISTS ratings_by_week (company TEXT, week_end TEXT, 
review_avg REAL, review_count INTEGER);

DELETE FROM ratings_by_week;

INSERT INTO ratings_by_week 
SELECT company,  week_end, avg(rating), count(rating)
FROM week_end_reviews
GROUP BY company, week_end
ORDER BY company, DATE(week_end) DESC;

-- last_week is a table that will be used to show
-- (by day) the average review for each company
CREATE TABLE IF NOT EXISTS last_week (company TEXT, review_date TEXT, 
rating_avg, rating_count);

DELETE FROM last_week;

INSERT INTO last_week 
SELECT company, review_date, avg(rating), count(rating)
FROM Ratings
WHERE JULIANDAY(DATE('now')) - JULIANDAY(review_date) < 7
GROUP BY company, review_date
ORDER BY company, DATE(review_date) DESC;

DELETE FROM tableau_tbl;

INSERT INTO tableau_tbl
SELECT company, version, review_date, rating, count(rating)
FROM Ratings
GROUP BY company, version, DATE(review_date), rating;
