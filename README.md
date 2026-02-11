Goal

Create a dashboard for analyzing revenue (MRR) and paid user behavior that displays key product and financial metrics, including:

•	MRR

•	Count of Paid Users

•	New Users / New MRR

•	Churned Users / Churned MRR

•	Churn Rate (Users / Revenue)


•	Expansion / Contraction MRR

•	ARPPU

•	LT

•	LTV

•	NRR

The goal is to provide product managers and analysts with a tool for monitoring revenue performance and identifying the factors behind changes in monthly MRR dynamics.

Data

•	games_payments — [User Transactions](./games_payments.csv/)

•	games_paid_users — [User Attributes](./games_paid_users.csv/)

Work Done

Transform raw transaction data into a structured dataset:

•	monthly revenue aggregation per user

•	detection of new paid users (New MRR)

•	churn identification (Churned MRR)

•	calculation of Expansion, Contraction, and Back-from-Churn

Calculated key product and financial metrics:

•	ARPPU

•	LT (lifetime)

•	LTV

•	NRR

Built an interactive Tableau dashboard with filters:

•	user language

•	user age

Result

An interactive Tableau dashboard for full MRR analysis that:

•	shows monthly dynamics of all key metrics

•	displays the structure of MRR (new users, churn, expansion, contraction)

•	helps quickly identify the drivers of revenue growth or decline

•	provides segmentation analysis by user age and language

Tools
SQL, Tableau

Links
- [Tableau Dashboard](https://public.tableau.com/views/GamesMRRAnalysis/MRRAnalysisbyMonths)
- [SQL Code](./sql_script)

![Dashboard Preview](./png_dashboard.png)
