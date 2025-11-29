-- Aggregates monthly revenue per user (base layer for MRR calculations)

WITH revenue_by_user_month AS (
    	SELECT
        	user_id,
        	DATE_TRUNC('month', payment_date::timestamp) AS payment_month,
        	SUM(revenue_amount_usd) AS mrr
    	FROM games_payments
    	GROUP BY 2,1),
  
-- Detecting churned users and storing their MRR value
  
new_users_mrr AS (
    	SELECT
    		user_id,
    		payment_month,
    		mrr,
    		LAG(mrr) OVER (PARTITION BY user_id ORDER BY payment_month) AS prev_mrr,
        CASE 
        	WHEN LAG(mrr) OVER (PARTITION BY user_id ORDER BY payment_month) IS NULL
			THEN 1
			ELSE 0
        END AS new_user,
        CASE 
        	WHEN  LAG(mrr) OVER (PARTITION BY user_id ORDER BY payment_month) IS NULL
        	THEN mrr
        END AS new_mrr
        FROM revenue_by_user_month),

-- Identifying churned users and calculating their Churned MRR
  
churned AS (
        SELECT 
        	user_id,
       	 	payment_month,
        	mrr,
       		payment_month + INTERVAL '1 month' AS churn_month,
			LEAD(payment_month) OVER(PARTITION BY user_id ORDER BY payment_month) AS next_paid_month,
		CASE 
			WHEN LEAD(payment_month) OVER(PARTITION BY user_id ORDER BY payment_month) IS NULL
       		OR LEAD(payment_month) OVER(PARTITION BY user_id ORDER BY payment_month) != payment_month + INTERVAL '1 month'
       		THEN 1
       		ELSE 0
		END AS churned_users,
		CASE 
			WHEN LEAD(payment_month) OVER(PARTITION BY user_id ORDER BY payment_month) IS NULL
       		OR LEAD(payment_month) OVER(PARTITION BY user_id ORDER BY payment_month) != payment_month + INTERVAL '1 month'
       		THEN mrr
		END churned_mrr
		FROM revenue_by_user_month
		),

-- Identifying users whose MRR increased (Expansion) and those whose MRR decreased (Contraction)
  
change_mrr_detailed AS (
    	SELECT 
        	user_id,
        	payment_month,
       		mrr,
         	LAG(payment_month) OVER ( PARTITION BY user_id ORDER BY payment_month) AS prev_paid_month,
        	LAG(mrr) OVER (PARTITION BY user_id ORDER BY payment_month) AS prev_revenue, 
        	(payment_month - INTERVAL '1 month')::date AS prev_calendar_month,
         CASE 
         	WHEN LAG(payment_month) OVER ( PARTITION BY user_id ORDER BY payment_month) =
         	 (payment_month - INTERVAL '1 month')::date
         	 AND mrr >  LAG(mrr) OVER (PARTITION BY user_id ORDER BY payment_month)
         	 THEN mrr - LAG(mrr) OVER (PARTITION BY user_id ORDER BY payment_month)
         	 ELSE 0
         END AS expansion_mrr,
         CASE
         	 WHEN LAG(payment_month) OVER ( PARTITION BY user_id ORDER BY payment_month) =
         	 (payment_month - INTERVAL '1 month')::date
         	 AND mrr <  LAG(mrr) OVER (PARTITION BY user_id ORDER BY payment_month)
         	 THEN LAG(mrr) OVER (PARTITION BY user_id ORDER BY payment_month) - mrr
         	 ELSE 0
         END AS contraction_mrr
         FROM revenue_by_user_month)

-- Final select with combining the calculated metrics, adding user attributes from the second table, and identifying returning users along with their Returned MR
  
         SELECT 
        	 rbum.user_id,
        	 rbum.payment_month,
        	 rbum.mrr,
        	 num.prev_mrr,
        	 num.new_user,
        	 num.new_mrr,
        	 ch.churned_users,
        	 ch.churned_mrr,
        	 cmd.expansion_mrr,
        	 cmd.contraction_mrr,
         CASE 
         	WHEN num.new_user = 0 
         	AND  rbum.mrr > 0
         	AND cmd.prev_paid_month is null or cmd.prev_paid_month < cmd.prev_calendar_month
         	THEN 1
         	ELSE 0
         	END AS back_from_churn_users,
          CASE
         	WHEN num.new_user = 0 
         	AND cmd.prev_paid_month is null or cmd.prev_paid_month < cmd.prev_calendar_month
         	AND  rbum.mrr > 0
         	THEN rbum.mrr
         	ELSE 0
         END AS back_from_churn_mrr,
         	 gpu.age,
        	 gpu.game_name,
    		 gpu.language,
        	 gpu.has_older_device_model
         FROM revenue_by_user_month rbum
        	LEFT JOIN new_users_mrr num
  		 		ON rbum.user_id = num.user_id
        		AND rbum.payment_month = num.payment_month
       		LEFT JOIN churned ch
    	 		ON rbum.user_id = ch.user_id
    			AND rbum.payment_month = ch.payment_month
        	LEFT JOIN change_mrr_detailed cmd
        		ON  rbum.user_id = cmd.user_id
         		AND rbum.payment_month = cmd.payment_month
         	LEFT JOIN games_paid_users gpu 
         		ON rbum.user_id = gpu.user_id
         ORDER BY 2;

		
