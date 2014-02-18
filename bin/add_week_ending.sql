DELETE FROM week_end_reviews;

INSERT INTO week_end_reviews
SELECT company, rating, review_date, 
DATE(JULIANDAY(review_date) + (6-STRFTIME('%w', review_date))) AS week_end
FROM Ratings;
