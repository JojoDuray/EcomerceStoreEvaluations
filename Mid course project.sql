USE mavenfuzzyfactory;

-- gsearch seems to be the biggest driver to the business. 
-- Pull monthly trends for gsearch sessions and orders to show the growth

SELECT 
	website_sessions.created_at,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE 
	website_sessions.utm_source = 'gsearch'
    AND website_sessions.created_at < '2012-11-27'
GROUP BY month(website_sessions.created_at) ;

-- Looking at trends for gsearch and spliting it by brand and nonbrand campaigns and looking at it by month

SELECT 
	YEAR(website_sessions.created_at) AS yr,
    MONTH(website_sessions.created_at) AS mo,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS nonbrand_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS nonbrand_order,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_session,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) AS brand_order
FROM website_sessions
	LEFT JOIN orders
    ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
AND website_sessions.utm_source = 'gsearch'
GROUP BY 1,2 ;

-- Now we will look at gsearch orders from nonbrand by device type
SELECT 
	YEAR(website_sessions.created_at) AS yr,
    MONTH(website_sessions.created_at) AS mo,
    COUNT(DISTINCT CASE WHEN device_type ='mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mobile_session,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) AS desktop_session,
     COUNT(DISTINCT CASE WHEN device_type ='mobile' THEN orders.order_id ELSE NULL END) AS mobile_order,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN orders.order_id ELSE NULL END) AS desktop_order
FROM website_sessions
	LEFT JOIN orders
     ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
AND website_sessions.utm_source = 'gsearch'
AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY 1,2 ;

-- Next we will look at all sources of traffic monthly compared with gsearch

select utm_source from website_sessions group by utm_source;
-- gsearch, bsearch

SELECT 
YEAR(website_sessions.created_at) AS yr,
MONTH(website_sessions.created_at) AS mo,
COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch,
COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch,
COUNT(DISTINCT CASE WHEN utm_source  IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_search,
COUNT(DISTINCT CASE WHEN utm_source  IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_search
FROM website_sessions
LEFT JOIN orders
     ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY 1,2;

-- session to order conversion rates by month 

SELECT 
YEAR(website_sessions.created_at) AS yr,
MONTH(website_sessions.created_at) AS mo,
COUNT(DISTINCT website_sessions.website_session_id) as sessions,
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate
FROM website_sessions
LEFT JOIN orders
 ON orders.website_session_id = website_sessions.website_session_id
 WHERE website_sessions.created_at < '2012-11-27' 
 GROUP BY 1,2
 ;
 
 -- For gsearch lander test, estimate the revenue that test earned.
 
 SELECT 
 MIN(website_pageview_id) AS first_pv
 FROM website_pageviews
 WHERE pageview_url = '/lander-1' ;
 -- 23504
CREATE TEMPORARY TABLE first_test_pv 
 SELECT 
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
INNER JOIN website_sessions
ON website_sessions.website_session_id = website_pageviews.website_session_id
AND website_sessions.created_at < '2012-07-28'
AND website_pageviews.website_pageview_id >= 23504
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand'
GROUP BY 
website_pageviews.website_session_id ;

CREATE TEMPORARY TABLE nonbrand_test_sessions_w_landingpage
SELECT 
	first_test_pv.website_session_id,
    website_pageviews.pageview_url AS landing_page
FROM first_test_pv
LEFT JOIN website_pageviews
ON website_pageviews.website_pageview_id = first_test_pv.min_pageview_id
WHERE website_pageviews.pageview_url IN ('/home', '/lander-1');

CREATE TEMPORARY TABLE nonbrand_test_sessions_w_orders
SELECT 
	nonbrand_test_sessions_w_landingpage.website_session_id,
    nonbrand_test_sessions_w_landingpage.landing_page,
    orders.order_id AS order_id
FROM nonbrand_test_sessions_w_landingpage
LEFT JOIN orders
ON orders.website_session_id = nonbrand_test_sessions_w_landingpage.website_session_id ;

SELECT 
	landing_page,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id) AS conv_rate
FROM nonbrand_test_sessions_w_orders
GROUP BY 1 ;

-- Finding the most recent pageview for gsearch nonbrand where the traffic was sent to home 

SELECT 
MAX(website_sessions.website_session_id) AS most_recent_gsearch_nonbrand_pv
FROM website_sessions
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE utm_source = 'gsearch'
AND utm_campaign = 'nonbrand'
AND pageview_url = '/home'
AND website_sessions.created_at < '2012-11-27' ;

-- max website session id = 17145

SELECT 
	COUNT(website_session_id) AS sessions_since_test
FROM website_sessions
WHERE created_at < '2012-11-27'
AND website_session_id > 17145
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand' ;

-- 22,972 sessions since the test
-- X .0087 incremental conversio = 202 incremental orders since 7/29
-- roughly 4 months, so about 50 orders more per month

-- quantify the impact of the billing page test in terms of revenue
-- per billing page session

SELECT 
	billing_version_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    SUM(price_usd) / COUNT(DISTINCT website_session_id) As revenue_per_billing_page 
FROM
( 
SELECT 
website_pageviews.website_session_id,
website_pageviews.pageview_url AS billing_version_seen,
orders.order_id,
orders.price_usd
FROM website_pageviews
	LEFT JOIN orders
    ON orders.website_session_id =website_pageviews.website_session_id
WHERE website_pageviews.created_at > '2012-09-10'
AND website_pageviews.created_at < '2012-11-10'
AND website_pageviews.pageview_url IN ('/billing', '/billing-2') ) AS billing_pageviews_and_order_data
GROUP BY 1;

