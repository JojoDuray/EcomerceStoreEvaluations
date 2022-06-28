USE mavenfuzzyfactory;

-- 1. create a new table that contains the correct dates and the 2 landing pages with the paid search, nonbrand 
-- traffic. 
CREATE TEMPORARY TABLE test_sessions
SELECT 
	website_pageviews.website_session_id,
   MIN( website_pageviews.website_pageview_id) as min_pageview,
   COUNT(website_pageviews.website_pageview_id) as pageview_count
FROM website_pageviews
inner JOIN website_sessions
ON website_pageviews.website_session_id = website_sessions.website_session_id
AND website_sessions.created_at > '2012-06-01'
AND website_sessions.created_at < '2012-08-31'
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand'
GROUP BY website_pageviews.website_session_id
;
select * from test_sessions;
-- This temp table will join in the correct landing pages we want to check the bounce rate on

CREATE TEMPORARY TABLE test_sessions_landingpage
SELECT 
	test_sessions.website_session_id,
    test_sessions.min_pageview,
    test_sessions.pageview_count,
    website_pageviews.pageview_url AS landing_page,
    website_pageviews.created_at as session_created
FROM test_sessions
	LEFT JOIN website_pageviews
	ON 	test_sessions.min_pageview = website_pageviews.website_pageview_id
;

select
	MIN(DATE(session_created)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN pageview_count =1 THEN website_session_id ELSE NULL END)*1.0 / COUNT(DISTINCT website_session_id) as bounce_rate,
    COUNT(DISTINCT CASE WHEN landing_page = '/home' THEN website_session_id ELSE NULL END) AS home_sessions,
    COUNT(DISTINCT CASE WHEN landing_page = '/lander-1' THEN website_session_id ELSE NULL END) AS lander_sessions
FROM test_sessions_landingpage
GROUP BY 
	YEARWEEK(session_created);
