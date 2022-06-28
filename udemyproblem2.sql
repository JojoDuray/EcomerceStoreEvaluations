use mavenfuzzyfactory;

 SELECT 
	MIN(created_at) as first_created_at,
    MIN(website_pageview_id) as first_pageview_id
FROM website_pageviews
where pageview_url = '/lander-1'
	and created_at IS NOT NULL;

CREATE TEMPORARY TABLE first_test_pageviews
SELECT 
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
	INNER JOIN website_sessions
    ON website_sessions.website_session_id = website_pageviews.website_session_id
    AND website_sessions.created_at < '2012-07-28'
    AND website_pageviews.website_pageview_id > 23504
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY  website_pageviews.website_session_id;

SELECT * FROM first_test_pageviews;

create temporary table nonbrand_test_sessions_w_landing_page
select
	first_test_pageviews.website_session_id,
    website_pageviews.pageview_url as landing_page
from first_test_pageviews
	LEFT JOIN website_pageviews
    ON website_pageviews.website_pageview_id = first_test_pageviews.min_pageview_id
WHERE website_pageviews.pageview_url IN ('/home' , '/lander-1');

CREATE TEMPORARY TABLE nonbrand_test_bounced_sessions
SELECT 
	nonbrand_test_sessions_w_landing_page.website_session_id,
    nonbrand_test_sessions_w_landing_page.landing_page,
    COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM nonbrand_test_sessions_w_landing_page
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id = nonbrand_test_sessions_w_landing_page.website_session_id
GROUP BY 
nonbrand_test_sessions_w_landing_page.website_session_id,
nonbrand_test_sessions_w_landing_page.landing_page
HAVING COUNT(website_pageviews.website_pageview_id) =1;

SELECT 
	nonbrand_test_sessions_w_landing_page.landing_page,
    nonbrand_test_sessions_w_landing_page.website_session_id,
    nonbrand_test_bounced_sessions.website_session_id AS bounced_website_session_id
FROM nonbrand_test_sessions_w_landing_page
	LEFT JOIN nonbrand_test_bounced_sessions
    ON   nonbrand_test_sessions_w_landing_page.website_session_id = nonbrand_test_bounced_sessions.website_session_id
ORDER BY  nonbrand_test_sessions_w_landing_page.website_session_id;

SELECT 
	nonbrand_test_sessions_w_landing_page.landing_page,
    COUNT(DISTINCT nonbrand_test_sessions_w_landing_page.website_session_id) as sessions,
    COUNT(DISTINCT nonbrand_test_bounced_sessions.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT nonbrand_test_bounced_sessions.website_session_id) / COUNT(DISTINCT nonbrand_test_sessions_w_landing_page.website_session_id) as bounce_rate

FROM nonbrand_test_sessions_w_landing_page
	LEFT JOIN nonbrand_test_bounced_sessions
    ON  nonbrand_test_sessions_w_landing_page.website_session_id = nonbrand_test_bounced_sessions.website_session_id
GROUP BY 	nonbrand_test_sessions_w_landing_page.landing_page;