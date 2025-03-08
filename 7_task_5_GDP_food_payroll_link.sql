
# Pro tuto část příkazů je třeba tabulka "t_Ondrej_Laskafeld_project_SQL_secondary_final"
# Vytvoření view "w_cze_eco" s ekonomickými ukazateli pouze pro ČR. 
CREATE OR REPLACE VIEW w_cze_eco AS 
SELECT *
FROM t_Ondrej_Laskafeld_project_SQL_secondary_final
WHERE country = "Czech Republic" AND GDP IS NOT NULL
ORDER BY year;

# Vytvoření view "w_cze_gdp_change" s dopočtenou změnou HDP (GDP) absolutně i procentuálně.
CREATE OR REPLACE VIEW w_cze_gdp_change AS 
SELECT
	id,
    country,
    year,
    GDP,
	ROUND((GDP - LAG(GDP) OVER (ORDER BY year)), 2) AS GDP_change,
	ROUND((100.0 * (GDP - LAG(GDP) OVER (ORDER BY year)) / LAG(GDP) OVER (ORDER BY year)), 2) AS GDP_change_percent
FROM w_cze_eco;

# Vytvoření view "w_GDP_food_payroll" s procentuální změnou HDP (GDP), cen potravin a mezd/platů.
CREATE OR REPLACE VIEW w_GDP_food_payroll AS
SELECT 
	w_cze_gdp_change.YEAR,
	w_cze_gdp_change.country,
	w_cze_gdp_change.GDP_change_percent,
	w_food_payroll_dif_per_year.avg_food_change,
	w_food_payroll_dif_per_year.avg_payroll_change
FROM w_cze_gdp_change
RIGHT JOIN w_food_payroll_dif_per_year
ON w_food_payroll_dif_per_year.YEAR = w_cze_gdp_change.YEAR;

# Vytvoření view "w_GDP_food_payroll_diff" s dopočítanými rozdíly mezi HDP (GDP), cenami potravin a mezdami/platy jak ve stejném roce tak v roce následujícím.
CREATE OR REPLACE VIEW w_GDP_food_payroll_diff AS
SELECT
	*,
	ROUND((GDP_change_percent - avg_food_change), 2) AS GDP_food,
	ROUND((GDP_change_percent - avg_payroll_change), 2) AS GDP_payroll,
	ROUND((LAG(GDP_change_percent) OVER (ORDER BY year) - avg_food_change), 2) AS GDP_food_previous_year,
	ROUND((LAG(GDP_change_percent) OVER (ORDER BY year) - avg_payroll_change), 2) AS GDP_payroll_previous_year
FROM w_GDP_food_payroll;

# Vytvoření view "w_percentages_diff" s dopočítanými kumulativními změnami HDP (GDP), cenami potravin a mezdami/platy za sledované roky.
CREATE OR REPLACE VIEW w_percentages_diff AS
SELECT 
	w_GDP_food_payroll_diff.YEAR,
	w_GDP_food_payroll_diff.GDP_change_percent,
	w_GDP_food_payroll_diff.avg_food_change,
	w_GDP_food_payroll_diff.avg_payroll_change,
	w_GDP_food_payroll_diff.GDP_food,
	w_GDP_food_payroll_diff.GDP_payroll,
	w_GDP_food_payroll_diff.GDP_food_previous_year,
	w_GDP_food_payroll_diff.GDP_payroll_previous_year,
	ROUND((100 * EXP(SUM(LOG(1 + GDP_change_percent / 100)) OVER (ORDER BY year)) - 100), 2) AS GDP_cumulative,
	ROUND((100 * EXP(SUM(LOG(1 + avg_food_change / 100)) OVER (ORDER BY year)) - 100), 2) AS food_cumulative,
	ROUND((100 * EXP(SUM(LOG(1 + avg_payroll_change / 100)) OVER (ORDER BY year)) - 100), 2) AS payroll_cumulative
FROM w_GDP_food_payroll_diff;

# Vytvoření view "w_percentages_avg" s dopočítanými průměrnými změnami HDP (GDP), cenami potravin a mezdami/platy za sledované roky.
CREATE OR REPLACE VIEW w_percentages_avg AS
SELECT 
	w_GDP_food_payroll_diff.YEAR,
	w_GDP_food_payroll_diff.GDP_change_percent,
	w_GDP_food_payroll_diff.avg_food_change,
	w_GDP_food_payroll_diff.avg_payroll_change,
	w_GDP_food_payroll_diff.GDP_food,
	w_GDP_food_payroll_diff.GDP_payroll,
	w_GDP_food_payroll_diff.GDP_food_previous_year,
	w_GDP_food_payroll_diff.GDP_payroll_previous_year
FROM w_GDP_food_payroll_diff
UNION ALL
SELECT
  "average" AS year,
  ROUND(AVG(GDP_change_percent), 2) AS GDP_change_percent,
  ROUND(AVG(avg_food_change), 2) AS avg_food_change,
  ROUND(AVG(avg_payroll_change), 2) AS avg_payroll_change,
  ROUND(AVG(GDP_food), 2) AS GDP_food,
  ROUND(AVG(GDP_payroll), 2) AS GDP_payroll,
  ROUND(AVG(GDP_food_previous_year), 2) AS GDP_food_previous_year,
  ROUND(AVG(GDP_payroll_previous_year), 2) AS GDP_payroll_previous_year
FROM w_GDP_food_payroll_diff;

# 5.
#######################################################################################
# Zobrazení výsledku jaká byla průměrná změna HDP (GDP), cen potravin a mezd/platů. Zároveň i rozdíl mezi jednotlivými ukazateli ve stejném i následném roce
# pro ukázání provázaností ukazatelů.
SELECT *
FROM w_percentages_avg;

# Zobrazení výsledku jaká byla kumulativní změna HDP (GDP), cen potravin a mezd/platů.
SELECT
	YEAR,
	GDP_cumulative,
	food_cumulative,
	payroll_cumulative
FROM w_percentages_diff;

# Zobrazení textové podoby výsledků - jak průměrné změny tak kumulativní.
SELECT "Při porovnání meziročního růstu HDP (GDP), cen potravin a platů není patrná provázanost ať již porovnáváme hodnoty ze stejných let, nebo potraviny a platy s ročním spožděním." AS message
UNION ALL
SELECT "Když však porovnáme kumulativní změnu hodnoty pro HDP (GDP) (36,81%) a cen potravin (38,98%) mezi lety 2006 až 2018 zjistíme, že se mění velmi podobně." 
UNION ALL
SELECT "Naopak kumulativní změna platů byla za dané období 66,18%. Lze tedy říci, že platy rostou 1,8x tychleji než HDP (GDP) a ceny potravin";

#######################################################################################