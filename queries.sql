/*markdown
# Wiwino data analysis
*/

/*markdown
### We want to highlight 10 wines to increase our sales. Which ones should we choose and why?
*/

UPDATE wines
SET price_per_rating = (
    SELECT AVG(CAST(ratings_average AS float) / CAST(vintages.price_euros AS float)) * 100
    FROM vintages 
    WHERE vintages.wine_id = wines.id
)
WHERE ratings_average > 0;


SELECT vintages.name, wines.is_natural, vintages.ratings_average, vintages.ratings_count, 
        ROUND(price_per_rating,2) AS rating_per_price, price_euros, bottle_volume_ml FROM wines
JOIN vintages ON wines.id = vintages.wine_id
WHERE vintages.ratings_count > 0 AND vintages.ratings_average > 0
ORDER BY price_per_rating DESC
LIMIT 10;

/*markdown

In the realm of great value wines, Château Voigny Sauternes 2019 leads with its balanced rating and affordable price. Following closely are Cignomoro Primitivo di Manduria 2021 and Luccarelli Old Vines Primitivo di Manduria 2019, both offering high quality at reasonable prices. 

Puglia Pop Triglia Negroamaro Rosato 2022 stands out for its exceptional rating and modest cost. Farnese Cinque Autoctoni Collection Limited Release 2020 also impresses with its remarkable value proposition. 

These wines showcase that exceptional taste can be found without breaking the bank, delighting wine enthusiasts with both flavor and affordability.
*/

/*markdown
### We have a limited marketing budget for this year. Which country should we prioritise and why?
*/

UPDATE countries
SET wineries_user_ratio = ROUND(CAST(wineries_count AS float) / CAST(users_count AS float) * 100,2)
WHERE users_count > 0;

SELECT * FROM countries
ORDER BY wineries_user_ratio DESC
LIMIT 10;

/*markdown
Focusing marketing efforts on countries with high wineries to user ratios is advantageous because it indicates a strong demand for wine within those regions relative to the available wineries. 

Moldova, with a wineries to user ratio of 3.08, stands out as a prime market for marketing efforts due to its high ratio, suggesting a potentially underserved market with ample room for growth and engagement. 

Similarly, countries like Hungary, Chile, South Africa, and Croatia also exhibit promising ratios, implying significant potential for market penetration and customer engagement within their respective wine industries.
*/

/*markdown
### We would like to give awards to the best wineries. Come up with 3 relevant ones. Which wineries should we choose and why?
*/

/*markdown
#### category 1: rating per winery
*/

SELECT name, winery_id, ratings_average, ratings_count FROM wines 
ORDER BY ratings_average DESC, ratings_count DESC
LIMIT 3;



/*markdown
The price for The best wine is Cabernet Sauvignon by winery with id 14919. It's tied with Amarone della Valpolicella Classico Riserva by winery id 11601 and Fratini Bolgheri Superiore	by winery id 277785. All participants have an average rating of 4.8 but Cabernet Sauvignon is ranked 1 by the amount of reviews tiebreaker.

*/

/*markdown
#### Category 2: Best winery with natural wine
*/

SELECT name, winery_id, ratings_average, ratings_count, is_natural FROM wines 
WHERE is_natural IS TRUE
ORDER BY ratings_average DESC, ratings_count DESC

LIMIT 3;

/*markdown
The award for Best Natural Wine celebrates craftsmanship and terroir expression. Bassolino di Sopra Brunello di Montalcino shines with a 4.6 rating and 174 endorsements, embodying natural winemaking's artistry. Les Poyeux Saumur Champigny, rated 4.5 with 2005 admirers, and Le Bourg Saumur Champigny, with 1264 devotees, also excel.
*/

/*markdown
#### Category 3: Best winery with wine under 50 euros
*/

SELECT wines.name, winery_id, wines.ratings_average, wines.ratings_count, vintages.price_euros FROM wines 
JOIN vintages ON wines.id = vintages.wine_id
WHERE vintages.price_euros < 50
ORDER BY wines.ratings_average DESC, wines.ratings_count DESC
LIMIT 3;

/*markdown
The best winery with wine under 50 euros is Lupi Rezerva, with a rating average of 4.5 and a price of 36.55 euros. Despite its slightly higher price compared to others in this category, its high ratings and quality make it a standout choice among wine enthusiasts seeking value.
*/

/*markdown
### We detected that a big cluster of customers likes a specific combination of tastes. We identified a few keywords that match these tastes: _coffee_, _toast_, _green apple_, _cream_, and _citrus_ (note that these keywords are case sensitive ⚠️). We would like you to find all the wines that are related to these keywords. Check that **at least 10 users confirm those keywords**, to ensure the accuracy of the selection. Additionally, identify an appropriate group name for this cluster.
*/

SELECT wines.name AS wine_name, keywords_wine.*, keywords.name AS keyword_name
FROM wines
JOIN keywords_wine ON wines.id = keywords_wine.wine_id
JOIN keywords ON keywords_wine.keyword_id = keywords.id
WHERE keywords.name IN ('coffee', 'toast', 'green apple', 'cream', 'citrus')
    AND keywords_wine.count >= 10
GROUP BY wine_name
HAVING COUNT(DISTINCT keyword_name) = 5;

/*markdown
Based on the data provided, several wines are associated with the specified keywords: toast, green apple, citrus, and coffee. These include various Champagne selections like Blanc des Millénaires and La Grande Dame for toast, Belle Epoque Brut Champagne for green apple, Le Mesnil Blanc de Blancs (Cuvée S) Brut Champagne for citrus, and MV along with Trebbiano d'Abruzzo for coffee, each confirmed by at least 10 users.
*/

/*markdown
### We would like to select wines that are easy to find all over the world. 
**Find the top 3 most common grapes all over the world** and **for each grape, give us the the 5 best rated wines**.
*/

SELECT grapes.name, SUM(wines_count) AS total_wines_count
FROM most_used_grapes_per_country
JOIN grapes ON most_used_grapes_per_country.grape_id = grapes.id
GROUP BY grapes.name
ORDER BY total_wines_count DESC
LIMIT 3;

/*markdown
The top three most common grape varieties worldwide are Cabernet Sauvignon, Chardonnay, and Merlot. 
*/

SELECT
    grape_name,
    wine_name,
    wine_rating,
    ratings_count,
    price_euros
FROM (
    SELECT
        grapes.name AS grape_name,
        wines.name AS wine_name,
        wines.ratings_average AS wine_rating,
        wines.ratings_count,
        vintages.price_euros,
        ROW_NUMBER() OVER (PARTITION BY grapes.name ORDER BY wines.ratings_average DESC) AS rank
    FROM
        wines
    INNER JOIN
        regions ON wines.region_id = regions.id
    INNER JOIN
        vintages ON wines.id = vintages.wine_id
    INNER JOIN
        countries ON regions.country_code = countries.code
    INNER JOIN
        most_used_grapes_per_country ON countries.code = most_used_grapes_per_country.country_code
    INNER JOIN
        grapes ON most_used_grapes_per_country.grape_id = grapes.id
    WHERE
        grapes.name IN ('Merlot', 'Chardonnay', 'Cabernet Sauvignon')
) AS ranked_wines
WHERE
    rank <= 5
ORDER BY
    grape_name, wine_rating DESC;


/*markdown
The top 3 most common grapes worldwide are Cabernet Sauvignon, Chardonnay, and Merlot. Among these, the top-rated wines include "Cabernet Sauvignon" (rating: 4.8, ratings count: 2941, price: 1558.75 euros), "Amarone della Valpolicella Classico Riserva" (rating: 4.8, ratings count: 587, price: 1046.25 euros), and "Fratini Bolgheri Superiore" (rating: 4.8, ratings count: 153, price: 262.6 euros).

*/

SELECT
    grape_name,
    wine_name,
    wine_rating,
    ratings_count,
    price_euros
FROM (
    SELECT
        grapes.name AS grape_name,
        vintages.name AS wine_name,
        vintages.ratings_average AS wine_rating,
        vintages.ratings_count,
        vintages.price_euros,
        ROW_NUMBER() OVER (PARTITION BY grapes.name ORDER BY wines.ratings_average DESC) AS rank
    FROM
        wines
    INNER JOIN
        regions ON wines.region_id = regions.id
    INNER JOIN
        vintages ON wines.id = vintages.wine_id
    INNER JOIN
        countries ON regions.country_code = countries.code
    INNER JOIN
        most_used_grapes_per_country ON countries.code = most_used_grapes_per_country.country_code
    INNER JOIN
        grapes ON most_used_grapes_per_country.grape_id = grapes.id
    WHERE
        grapes.name IN ('Merlot', 'Chardonnay', 'Cabernet Sauvignon') AND vintages.ratings_count > 0 
        AND vintages.ratings_average > 0
) AS ranked_wines
WHERE
    rank <= 5
ORDER BY
    grape_name, wine_rating DESC;

/*markdown
Running the query on the vintages table instead of wine table generates slightly different results
*/

/*markdown
### We would like to create a country leaderboard. Come up with a visual that shows the **average wine rating for each `country`**. Do the same for the `vintages`.
*/

CREATE TABLE wine_ratings AS
    SELECT
        countries.name,
        ROUND(AVG(wines.ratings_average),2) AS average_rating
    FROM 
        wines
    INNER JOIN
        regions ON wines.region_id = regions.id
    INNER JOIN
        countries ON regions.country_code = countries.code
    GROUP BY
        countries.name;




CREATE TABLE vintage_ratings AS
    SELECT
        countries.name,
        ROUND(AVG(vintages.ratings_average),2) AS average_rating
    FROM 
        wines
    INNER JOIN
        regions ON wines.region_id = regions.id
    INNER JOIN
        countries ON regions.country_code = countries.code
    INNER JOIN
        vintages ON wines.id = vintages.wine_id
    GROUP BY
        countries.name;

/*markdown
Graphs in graphs.ipynb
*/

/*markdown
### One of our VIP clients likes _Cabernet Sauvignon_ and would like our top 5 recommendations. Which wines would you recommend to him?
*/

SELECT
       grapes.name AS grape_name,
       wines.name AS wine_name,
       wines.ratings_average AS wine_rating,
       wines.ratings_count,
       vintages.price_euros,vintages.bottle_volume_ml, vintages.year, wines.is_natural
       
       
FROM
       wines
INNER JOIN
       regions ON wines.region_id = regions.id
INNER JOIN
       vintages ON wines.id = vintages.wine_id
INNER JOIN
       countries ON regions.country_code = countries.code
INNER JOIN
       most_used_grapes_per_country ON countries.code = most_used_grapes_per_country.country_code
INNER JOIN
       grapes ON most_used_grapes_per_country.grape_id = grapes.id
WHERE
       grapes.name = 'Cabernet Sauvignon'
ORDER BY wine_rating DESC
LIMIT 5;

/*markdown
These are the overall best wines made from Cabernet Sauvignon grapes.
*/

SELECT
       grapes.name AS grape_name,
       wines.name AS wine_name,
       wines.ratings_average AS wine_rating,
       wines.ratings_count,
       vintages.price_euros,vintages.bottle_volume_ml, vintages.year, wines.is_natural
       
       
FROM
       wines
INNER JOIN
       regions ON wines.region_id = regions.id
INNER JOIN
       vintages ON wines.id = vintages.wine_id
INNER JOIN
       countries ON regions.country_code = countries.code
INNER JOIN
       most_used_grapes_per_country ON countries.code = most_used_grapes_per_country.country_code
INNER JOIN
       grapes ON most_used_grapes_per_country.grape_id = grapes.id
WHERE
       grapes.name = 'Cabernet Sauvignon' AND is_natural IS TRUE
ORDER BY wine_rating DESC
LIMIT 5;

/*markdown
These are the best natural Cabernet Sauvignon wines
*/

SELECT
       grapes.name AS grape_name,
       wines.name AS wine_name,
       wines.ratings_average AS wine_rating,
       wines.ratings_count,
       vintages.price_euros,vintages.bottle_volume_ml, vintages.year, wines.is_natural
       
       
FROM
       wines
INNER JOIN
       regions ON wines.region_id = regions.id
INNER JOIN
       vintages ON wines.id = vintages.wine_id
INNER JOIN
       countries ON regions.country_code = countries.code
INNER JOIN
       most_used_grapes_per_country ON countries.code = most_used_grapes_per_country.country_code
INNER JOIN
       grapes ON most_used_grapes_per_country.grape_id = grapes.id
WHERE
       grapes.name = 'Cabernet Sauvignon' AND bottle_volume_ml > 750
ORDER BY wine_rating DESC
LIMIT 5;

/*markdown
These are the best magnum size bottles with wine made from Cabernet Sauvignon grapes
*/

SELECT
       grapes.name AS grape_name,
       wines.name AS wine_name,
       wines.ratings_average AS wine_rating,
       wines.ratings_count,
       vintages.price_euros,vintages.bottle_volume_ml, vintages.year, wines.is_natural
       
       
FROM
       wines
INNER JOIN
       regions ON wines.region_id = regions.id
INNER JOIN
       vintages ON wines.id = vintages.wine_id
INNER JOIN
       countries ON regions.country_code = countries.code
INNER JOIN
       most_used_grapes_per_country ON countries.code = most_used_grapes_per_country.country_code
INNER JOIN
       grapes ON most_used_grapes_per_country.grape_id = grapes.id
WHERE
       grapes.name = 'Cabernet Sauvignon' AND price_euros < 200
ORDER BY wine_rating DESC
LIMIT 5;

/*markdown
These are the best midrange priced (< 200 EUR) bottles of Cabernet Sauvignon wine
*/

SELECT
       grapes.name AS grape_name,
       wines.name AS wine_name,
       wines.ratings_average AS wine_rating,
       wines.ratings_count,
       vintages.price_euros,vintages.bottle_volume_ml, vintages.year, wines.is_natural
       
       
FROM
       wines
INNER JOIN
       regions ON wines.region_id = regions.id
INNER JOIN
       vintages ON wines.id = vintages.wine_id
INNER JOIN
       countries ON regions.country_code = countries.code
INNER JOIN
       most_used_grapes_per_country ON countries.code = most_used_grapes_per_country.country_code
INNER JOIN
       grapes ON most_used_grapes_per_country.grape_id = grapes.id
WHERE
       grapes.name = 'Cabernet Sauvignon' AND price_euros < 50
ORDER BY wine_rating DESC
LIMIT 5;

/*markdown
These are the best budget (< 50 EUR) bottles of Cabernet Sauvignon wine
*/

SELECT 
    vintages.name, 
    vintages.ratings_average, 
    vintages.year, 
    vintages.price_euros, 
    vintages.bottle_volume_ml, 
    toplists.name AS toplist_name, 
    vintage_toplists_rankings.rank
FROM 
    vintages
JOIN 
    vintage_toplists_rankings ON vintages.id = vintage_toplists_rankings.vintage_id
JOIN 
    toplists ON vintage_toplists_rankings.top_list_id = toplists.id
JOIN 
    most_used_grapes_per_country ON most_used_grapes_per_country.country_code = toplists.country_code
JOIN 
    grapes ON most_used_grapes_per_country.grape_id = grapes.id
WHERE 
    grapes.name = 'Cabernet Sauvignon' 
ORDER BY 
    vintage_toplists_rankings.rank
LIMIT 5;