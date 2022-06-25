USE mavenfuzzyfactory

	--find the main source of traffic for the website.
SELECT 
utm_source,
utm_campaign,
http_referer,
COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at < "2012-12-04" 
GROUP BY 
utm_source,
utm_campaign,
http_referer
ORDER BY count(DISTINCT website_session_id) DESC;

	--determine the conversion rate for the main sources of traffic.
SELECT 
 COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
 COUNT(DISTINCT orders.order_id ) AS orders,
 COUNT(DISTINCT orders.order_id ) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate
FROM website_sessions
LEFT JOIN orders
ON orders.website_session_id = website_sessions.website_session_id 
WHERE website_sessions.created_at < "2012-04-14"
	AND utm_source = "gsearch"
    AND utm_campaign = "nonbrand"
;

	--how many customers bought 1 or 2 items using a pivot table
SELECT 
	primary_product_id,
    COUNT(DISTINCT CASE WHEN items_purchased = 1 THEN order_id ELSE NULL END) AS orders_w_1_item,
    COUNT(DISTINCT CASE WHEN items_purchased =2 THEN order_id ELSE NULL END) AS orders_w_2_items,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY 1 ;

	--Traffic source trending. Finding what happened after the bid was lowered on gsearch nonbrand
SELECT 
created_at AS week_start_date,
COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at < "2012-05-10"
	AND utm_source = "gsearch" 
    AND utm_campaign = "nonbrand"
GROUP BY 
WEEK(created_at)
;

	--Traffic source bid optimization. Between mobile and desktop
SELECT 
website_sessions.device_type AS device_type,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate
FROM website_sessions
LEFT JOIN orders
ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < "2012-05-11"
GROUP BY website_sessions.device_type
;

	--sessions by desktop and mobile before and after adjusting bids.
SELECT 
created_at AS week_start,
COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS desktop,
COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile
FROM website_sessions
WHERE created_at > "2012-04-15" AND created_at < "2012-06-09"
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at)	
;

--creating a temp table to look at which pages hd the most views
CREATE TEMPORARY TABLE first_pageview
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS min_pv_id
FROM website_pageviews
GROUP BY website_session_id ;

SELECT * FROM first_pageview ;

SELECT 
	website_pageviews.pageview_url AS landing_page,
    COUNT(DISTINCT first_pageview.website_session_id) AS sessions
FROM first_pageview
	LEFT JOIN website_pageviews
		ON  first_pageview.min_pv_id = website_pageviews.website_pageview_id
GROUP BY  website_pageviews.pageview_url ;

--Finding top website pages

SELECT 
pageview_url,
COUNT(DISTINCT website_session_id) AS sessions
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY pageview_url
ORDER BY 2 DESC
;

CREATE TEMPORARY TABLE first_landing_page
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS min_pv
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY website_session_id
;

SELECT * FROM first_landing_page ;

SELECT 
website_pageviews.pageview_url AS landing_page,
COUNT(DISTINCT first_landing_page.website_session_id) AS sessions
FROM first_landing_page
	LEFT JOIN website_pageviews
		ON first_landing_page.min_pv = website_pageviews.website_pageview_id
GROUP BY  1
;

--Testing for bounce rate and how to improve the website
CREATE TEMPORARY TABLE first_pageview_bounce
SELECT 
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
	INNER JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
        AND website_sessions.created_at > '2012-06-14'
GROUP BY website_pageviews.website_session_id ;


CREATE TEMPORARY TABLE sessions_w_landing_page
SELECT 
	first_pageview_bounce.website_session_id,
    website_pageviews.pageview_url AS landing_page
FROM first_pageview_bounce
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = first_pageview_bounce.min_pageview_id
;
select* FROM sessions_w_landing_page ;

CREATE TEMPORARY TABLE bounced_sessions
SELECT 
	sessions_w_landing_page.website_session_id,
    sessions_w_landing_page.landing_page,
    COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM sessions_w_landing_page
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = sessions_w_landing_page.website_session_id
GROUP BY sessions_w_landing_page.website_session_id,
    sessions_w_landing_page.landing_page 
    
HAVING 
COUNT(website_pageviews.website_pageview_id) = 1;

select * from bounced_sessions;

SELECT 
	sessions_w_landing_page.landing_page,
    COUNT(DISTINCT sessions_w_landing_page.website_session_id) AS sessions,
    COUNT(DISTINCT bounced_sessions.website_session_id) AS bounced_session,
    COUNT(DISTINCT bounced_sessions.website_session_id) / COUNT(DISTINCT sessions_w_landing_page.website_session_id) AS bounced_rate
FROM sessions_w_landing_page
	LEFT JOIN bounced_sessions
		ON sessions_w_landing_page.website_session_id = bounced_sessions.website_session_id
WHERE sessions_w_landing_page.landing_page = '/home'
GROUP BY sessions_w_landing_page.landing_page
ORDER BY 
	sessions_w_landing_page.website_session_id
    ;



