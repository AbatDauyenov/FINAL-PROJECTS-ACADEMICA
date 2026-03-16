-- Финальный проект по SQL
-- Начало работы

SELECT * FROM transactions;
SELECT * FROM customers;

-- 1.	список клиентов с непрерывной историей за год, то есть каждый месяц на регулярной основе без пропусков за указанный годовой период, средний чек 
-- за период с 01.06.2015 по 01.06.2016, средняя сумма покупок за месяц, количество всех операций по клиенту за период;
SET @number_of_unique_months := (
	SELECT COUNT(DISTINCT date_new)
	FROM transactions
);
WITH right_client_id
	AS (
		SELECT
			ID_client
		FROM transactions
		GROUP BY ID_client
		HAVING COUNT(DISTINCT date_new) = @number_of_unique_months
    ), query_1
    AS (
		SELECT
			ID_client,
			SUM(Sum_payment) / COUNT(ID_check) AS AOV,
			COUNT(ID_check) AS total_transactions
		FROM transactions
			JOIN right_client_id USING(ID_client)
		GROUP BY ID_client
    ), query_2
    AS (
		SELECT 
			ID_client, 
			AVG(sum) AS average_monthly_purchase
		FROM (
			SELECT 
				date_new,
				ID_client,
				SUM(Sum_payment) AS sum
			FROM transactions
				JOIN right_client_id USING(ID_client)
			GROUP BY date_new, ID_client ) AS query_in
		GROUP BY ID_client
    )
SELECT
	q1.ID_client,
    ROUND(q1.AOV, 1) AS AOV,
    ROUND(q2.average_monthly_purchase, 1) AS average_monthly_purchase,
    q1.total_transactions
FROM query_1 q1
	JOIN query_2 q2 USING(ID_client)
ORDER BY q1.ID_client;



-- 2.	информацию в разрезе месяцев:
-- a)	средняя сумма чека в месяц;
-- b)	среднее количество операций в месяц;
-- c)	среднее количество клиентов, которые совершали операции;
-- d)	долю от общего количества операций за год и долю в месяц от общей суммы операций;
-- e)	вывести % соотношение M/F/NA в каждом месяце с их долей затрат;
SELECT
	date_new,
	ROUND(SUM(Sum_payment) / COUNT(Id_check),1) AS AOV,
    COUNT(Id_check) AS number_of_transactions,
    COUNT(DISTINCT ID_client) AS number_of_clients,
    CONCAT(ROUND(COUNT(Id_check) / (SELECT COUNT(ID_check) FROM transactions) * 100,1), " %") AS transactions_share,
    CONCAT(ROUND(SUM(Sum_payment) / (SELECT SUM(Sum_payment) FROM transactions) * 100,1), " %") AS payments_share,
    ROUND(SUM(IF(Gender = "F", Sum_payment, 0)) / SUM(Sum_payment) * 100, 1) AS F,
    ROUND(SUM(IF(Gender = "M", Sum_payment, 0)) / SUM(Sum_payment) * 100, 1) AS M,
    ROUND(SUM(IF(Gender IS NULL, Sum_payment, 0)) / SUM(Sum_payment) * 100, 1) AS NA
FROM transactions t
	JOIN customers c USING(ID_client)
GROUP BY date_new
ORDER BY date_new;



-- 3.	возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации, с параметрами сумма и 
-- количество операций за весь период, и поквартально - средние показатели и %.
SELECT
	CASE
		WHEN c.Age < 10 THEN "1-9"
        WHEN c.Age < 20 THEN "10-19"
        WHEN c.Age < 30 THEN "20-29"
        WHEN c.Age < 40 THEN "30-39"
        WHEN c.Age < 50 THEN "40-49"
        WHEN c.Age < 60 THEN "50-59"
        WHEN c.Age < 70 THEN "60-69"
        WHEN c.Age < 80 THEN "70-79"
        WHEN c.Age < 90 THEN "80-89"
        ELSE "NA"
	END AS Ages,
    CONCAT("Q", QUARTER(date_new)) AS Quarter,
    SUM(Sum_payment) AS total_of_revenue,
    COUNT(Id_check) AS number_of_transactions,
    SUM(Sum_payment) / COUNT(Id_check) AS AOV,
    ROUND(SUM(Sum_payment) / (SELECT SUM(Sum_payment) FROM transactions) * 100, 1) AS "%"
FROM customers c
	JOIN transactions t USING(ID_client)
GROUP BY Ages, Quarter
ORDER BY Ages, Quarter;
