
# Pro tuto část příkazů je třeba tabulka "t_Ondrej_Laskafeld_project_SQL_primary_final"
# Vytvoření view s průměrnou cenou všech potravin dohromady v daném roce.
CREATE OR REPLACE VIEW w_food_prices_all AS
SELECT
	year,
	ROUND(AVG(price_avg), 2) AS avg_price_all
FROM t_Ondrej_Laskafeld_project_SQL_primary_final
WHERE 
	category_name IS NOT NULL
GROUP BY year;

# Vytvoření view s průměrnou mzdou/platem dohromady v daném roce.
CREATE OR REPLACE VIEW w_payroll_change_avg AS
SELECT 
    	year, 
    	ROUND(AVG(payroll_value), 2) AS avg_payroll_year
FROM t_Ondrej_Laskafeld_project_SQL_primary_final
WHERE industry_branch_name IS NOT NULL
GROUP BY year;

# Spojení w_food_prices_all a w_payroll_change_avg podle roků.
CREATE OR REPLACE VIEW w_food_payroll_per_year AS
SELECT
	w_food_prices_all.year,
	avg_price_all,
	avg_payroll_year
FROM w_food_prices_all
INNER JOIN w_payroll_change_avg ON w_payroll_change_avg.YEAR = w_food_prices_all.year;

# Vytvoření view s výpočtem změny mezi jednotlivími roky (po sobě jdoucími) cen potravin a mezd/platů v procentech. 
CREATE OR REPLACE VIEW w_food_payroll_per_year_percent AS
SELECT 
	year,
	avg_price_all,
	avg_payroll_year,
	ROUND((100.0 * (avg_price_all - LAG(avg_price_all) OVER (ORDER BY year)) / LAG(avg_price_all) OVER (ORDER BY year)), 2) AS avg_food_change,
	ROUND((100.0 * (avg_payroll_year - LAG(avg_payroll_year) OVER (ORDER BY year)) / LAG(avg_payroll_year) OVER (ORDER BY year)), 2) AS avg_payroll_change
FROM w_food_payroll_per_year;

# Vytvoření view s výpočtem rozdílu mezi změnou cen potravin a mezd/platů - porovnání zda nějaký rok byl nárůst cen potravin o 10% více než růst mezd/platů.
CREATE OR REPLACE VIEW w_food_payroll_dif_per_year AS
SELECT 
	year,
	avg_price_all,
	avg_payroll_year,
	avg_food_change,
	avg_payroll_change,
	(avg_food_change - avg_payroll_change) AS diff_food_payroll_percent
FROM w_food_payroll_per_year_percent;

# 4.
#######################################################################################
# Zobrazení výsledků zda v nějakém roce rostly ceny potravin o 10 nebo více % ve srovnání s růstem mezd/platů.
SELECT *
FROM w_food_payroll_dif_per_year;

# Zobrazení textové podoby výsledků zda v nějakém roce rostly ceny potravin o 10 nebo více % ve srovnání s růstem mezd/platů.
WITH max_value AS (
    SELECT MAX(diff_food_payroll_percent) AS max_diff
    FROM w_food_payroll_dif_per_year)
SELECT "V žádném sledovaném roce nebylo zdražení průměrné ceny sledovaných potravin o 10% více než průměrná změna mezd/platů v daném roce." as message
FROM max_value
WHERE max_diff < 10
UNION ALL
SELECT Concat("V roce ", YEAR, " bylo průměrné zdražení potravin o ", diff_food_payroll_percent, "% více než průměrný nárůst mezd/platů.") 
FROM w_food_payroll_dif_per_year
WHERE diff_food_payroll_percent >= 10;
#######################################################################################
