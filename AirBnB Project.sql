/*

2019 AirBnB Data Exploration.

Based on the data provided, this would be great information to help hosts 
improve the number of reviews they receive, 
which hopefully comes from an increased booking rate.

The data could also be beneficial for internal stakeholders
to decide where to spend limited resources.
Who, in what neighborhood, with what type of place, charging how much, is the main
driver(s) of our business?

*/

-- Just ran to get a feel for the dataset and any potential cleaning issues to address
SELECT *
FROM dbo.AB_NYC_2019$

/* Noticed there are a fair amount of NULLs in the last_review column.
Want to see if I can spot any patterns in the data where last_review column is NULL
*/

SELECT *
FROM dbo.AB_NYC_2019$
WHERE last_review IS NULL;

/* Looks like where last_review is NULL, there have been 0 reviews for that listing.
Double checking my thought. 
*/

SELECT COUNT(*) -- Total count is 0. Thought confirmed.
FROM dbo.AB_NYC_2019$
WHERE last_review IS NULL
AND number_of_reviews > 0;

/* Using number_of_reviews as the north star KPI since it's the closest metric this dataset provides to a booking rate.
Booking places to stay is the problem AirBnB solves.
Want to get a range of the number of reviews
*/

SELECT MIN(number_of_reviews), -- Range is between 0 and 629.
	MAX(number_of_reviews)
FROM dbo.AB_NYC_2019$;

-- Range of prices

SELECT MIN(price), -- Price range between 0 and 10,000. Give me the 10,000 dollar room please.
	MAX(price)
FROM dbo.AB_NYC_2019$;

/* Why would any lsting have a booking price of $0 unless it's unavailable?
Potentially a sale, but that wouldn't be included in the initial listing price, would it?
Would have to speak to an internal stakeholder - Google failed me
*/

SELECT * -- Only 3/11 listings are unavailable for booking. 
FROM dbo.AB_NYC_2019$
WHERE price = 0;

/* Going to omit the 8 records where price = 0 and availability_365 > 0
According to the data origination source, price = 0 and availability_365 > 0
suggests an inactive listing that has not been removed. On the other hand,
records where price = 0 and availability_365 = 0 suggests that the listing
has been manually deactivated temporarily.
*/

DELETE FROM dbo.AB_NYC_2019$
WHERE price = 0
AND availability_365 != 0;

/* Breaking down number_of_reviews column into quartiles
See if I can find some commonalities between the groups and do
some more exploratory analysis.
*/

SELECT neighbourhood,
neighbourhood_group,
number_of_reviews,
NTILE(4) OVER (ORDER BY number_of_reviews DESC) AS quartile_group
FROM dbo.AB_NYC_2019$;

/* Seems that most listings have less than 100 reviews.
Want to run some numbers to see what the distribution/count of number of reviews looks like
*/

SELECT COUNT(*) -- 45,843 listings have less than 100 reviews
FROM dbo.AB_NYC_2019$
WHERE number_of_reviews < 100;

SELECT COUNT(*) -- 2,995 listings have more than 100 reviews. Why?
FROM dbo.AB_NYC_2019$
WHERE number_of_reviews > 100;

SELECT COUNT(*) -- 10,052 listings have 0 reviews. Why? Should I get rid of any of these? Why?
FROM dbo.AB_NYC_2019$
WHERE number_of_reviews = 0;

/* According to the data provider, availability_365 = 0
is a good indicator that the listing was manually deactivated temporarily.
Therefore, I will include results where number_of_reviews = 0 and 
availability_365 = 0.
*/

SELECT COUNT(*) -- 4,845 listings have no reviews and were likely deactivated temporarily.
FROM dbo.AB_NYC_2019$
WHERE number_of_reviews = 0
AND availability_365 = 0;

/* However, are there any other results I should exclude from analysis?
This would need to be answered by a domain expert, but my best guess is
any listing that has no reviews and has gone unbooked for 105 days (the split between 90 days
and 120 days) or greater should be excluded from analysis.
*/

SELECT COUNT(*) -- 3,385 listings have no reviews and have been available for 105 days or greater.
FROM dbo.AB_NYC_2019$
WHERE number_of_reviews = 0
AND availability_365 >= 105;

/* Drilling back up, will exclude the 3,385 listings (that have no reviews and
have been available for 105 days or greater) from the 45,843 listings that have less than 100 reviews.
Deciding to include results with 0 reviews and have been available for 104 days or earlier because
these could be active listings that have received no reviews, and may tell us something.
*/

DELETE FROM dbo.AB_NYC_2019$
WHERE number_of_reviews = 0
AND availability_365 >= 105;

SELECT id, -- Ensuring I have no duplicates before I visualize the data to look for more insights
COUNT(id)
FROM dbo.AB_NYC_2019$
GROUP BY id
HAVING COUNT(id) > 1;

-- Date range

SELECT MIN(last_review), -- March 28, 2011 to July 8, 2019
MAX(last_Review)
FROM dbo.AB_NYC_2019$;


/* Ensuring enough data is recent enough for the dataset to be relevant.
2011: 7 records. 2012: 25 records. 2013: 48 records. 2014: 199 records
2015: 1,393 records. 2016: 2,707 records. 2017: 3,205 records
2018: 6,048 records 2019: 25,203 records. 6,667 records are NULL.
*/

SELECT COUNT(*)
FROM dbo.AB_NYC_2019$
WHERE last_review like '%2019%';

SELECT COUNT(*)
FROM dbo.AB_NYC_2019$
WHERE last_review IS NULL;

/* Price distribution by neighbourhood group or "borough". Ran this to get a look at prices.
Price = 0 here is okay because some listings are currently inactive.
*/

SELECT neighbourhood_group,
MIN(price) AS lowest_price,
MAX(CASE WHEN price_quartile = 1 THEN price END) AS first_price_quartile,
MAX(CASE WHEN price_quartile = 2 THEN price END) AS median,
MAX(CASE WHEN price_quartile =3 THEN price END) AS third_price_quartile,
MAX(price) AS highest_price,
COUNT(price) AS Price_Count
FROM (	
		SELECT neighbourhood_group, 
		price,
		NTILE (4) OVER (PARTITION BY neighbourhood_group ORDER BY price) AS price_quartile
		FROM dbo.AB_NYC_2019$
) AS Val
GROUP BY neighbourhood_group;

-- End goal, show # of reviews by price quartile and range

SELECT price, -- # of reviews by price - used to set up CTE Below
NTILE (4) OVER (ORDER BY price) AS price_quartile,
SUM(number_of_reviews) AS reviews_per_price_point
FROM dbo.AB_NYC_2019$
GROUP BY price
ORDER BY price_quartile;

-- Shows # of reviews by price quartiles and the price ranges in each quartile

WITH reviews_per_quartile AS (
		SELECT price, -- # of reviews by price (price quartile is included, but reviews are not added by quartile here)
		NTILE (4) OVER (ORDER BY price) AS price_quartile,
		SUM(number_of_reviews) AS reviews_per_price_point
		FROM dbo.AB_NYC_2019$
		GROUP BY price 
)
SELECT price_quartile,
SUM(reviews_per_price_point)AS total_quartile_reviews,
MIN(CASE WHEN price_quartile = 1 THEN price
	WHEN price_quartile = 2 THEN price
	WHEN price_quartile = 3 THEN price
	WHEN price_quartile = 4 THEN price END) AS minimum_quartile_price,
MAX(CASE WHEN price_quartile = 1 THEN price
	WHEN price_quartile = 2 THEN price
	WHEN price_quartile = 3 THEN price
	WHEN price_quartile = 4 THEN price END) AS maximum_quartile_price
FROM reviews_per_quartile
GROUP BY price_quartile
ORDER BY price_quartile;

-- Breaking down # of reviews by room type

SELECT DISTINCT room_type,
SUM(number_of_reviews) AS reviews
FROM dbo.AB_NYC_2019$
GROUP BY room_type;