USE mavenfuzzyfactory;

select pageview_url
from website_pageviews
group by pageview_url;

SELECT 
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at AS pageview_created_at
    , CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS landing_page
    , CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS product_page
     , CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page
     ,CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page
     ,CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page
     ,CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions
	LEFT JOIN website_pageviews
    ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-08-05' AND '2012-09-05'
	AND website_pageviews.pageview_url IN ('/lander-1','/products' , '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
ORDER BY
	website_sessions.website_session_id,
    website_pageviews.created_at
    ;
 
 CREATE TEMPORARY TABLE session_level
 SELECT 
	website_session_id,
    MAX(landing_page) AS landing_made_it,
    MAX(product_page) AS product_made_it,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM (
 SELECT 
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at AS pageview_created_at
    , CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS landing_page
    , CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS product_page
     , CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page
     ,CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page
     ,CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page
     ,CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions
	LEFT JOIN website_pageviews
    ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-08-05' AND '2012-09-05'
	AND website_pageviews.pageview_url IN ('/lander-1','/products' , '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
ORDER BY
	website_sessions.website_session_id,
    website_pageviews.created_at
     ) AS pageview_level

GROUP BY 
website_session_id
;

SELECT 
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN landing_made_it =1 THEN website_session_id ELSE NULL END) AS to_landing,
	COUNT(DISTINCT CASE WHEN product_made_it =1 THEN website_session_id ELSE NULL END) AS to_product,
    COUNT(DISTINCT CASE WHEN cart_made_it =1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_made_it =1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_made_it =1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_made_it =1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_level ;


SELECT 
	COUNT(DISTINCT website_session_id) AS sessions,
	COUNT(DISTINCT CASE WHEN product_made_it =1 THEN website_session_id ELSE NULL END) 
    / COUNT(DISTINCT website_session_id) AS cr_product,
    COUNT(DISTINCT CASE WHEN cart_made_it =1 THEN website_session_id ELSE NULL END) 
    / COUNT(DISTINCT CASE WHEN product_made_it =1 THEN website_session_id ELSE NULL END) AS cr_cart,
    COUNT(DISTINCT CASE WHEN shipping_made_it =1 THEN website_session_id ELSE NULL END) 
    / COUNT(DISTINCT CASE WHEN cart_made_it =1 THEN website_session_id ELSE NULL END) AS cr_shipping,
    COUNT(DISTINCT CASE WHEN billing_made_it =1 THEN website_session_id ELSE NULL END) 
    / COUNT(DISTINCT CASE WHEN shipping_made_it =1 THEN website_session_id ELSE NULL END)  AS cr_billing,
    COUNT(DISTINCT CASE WHEN thankyou_made_it =1 THEN website_session_id ELSE NULL END) 
    /  COUNT(DISTINCT CASE WHEN billing_made_it =1 THEN website_session_id ELSE NULL END) AS cr_thankyou
FROM session_level ;

-- This section is looking at an A/B split test between 2 billing pages to see which one has a better conversion rate. 

SELECT 
website_pageview_id,
MIN(created_at ),
pageview_url
FROM website_pageviews
WHERE pageview_url = '/billing-2'
group by created_at;
-- 53550 first billing-2


SELECT 
	website_pageviews.website_session_id,
    website_pageviews.pageview_url AS version_seen,
    orders.order_id
FROM website_pageviews
LEFT JOIN orders 
	ON orders.website_session_id = website_pageviews.website_session_id
WHERE 
	website_pageviews.website_pageview_id >= 53550
    AND website_pageviews.created_at < '2012-11-10'
    AND website_pageviews.pageview_url IN ('/billing', '/billing-2') ;
    

SELECT 
version_seen,
COUNT(DISTINCT website_session_id) AS sessions,
COUNT(DISTINCT order_id) AS orders,
COUNT(DISTINCT order_id) /  COUNT(DISTINCT website_session_id) AS billing_order_rate
FROM 
(
  SELECT 
	website_pageviews.website_session_id,
    website_pageviews.pageview_url AS version_seen,
    orders.order_id
FROM website_pageviews
LEFT JOIN orders 
	ON orders.website_session_id = website_pageviews.website_session_id
WHERE 
	website_pageviews.website_pageview_id >= 53550
    AND website_pageviews.created_at < '2012-11-10'
    AND website_pageviews.pageview_url IN ('/billing', '/billing-2') ) AS billing_session_w_order
GROUP BY version_seen ;


