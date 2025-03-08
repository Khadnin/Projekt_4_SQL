
#######################################################################################
#VYTVOŘENÍ PRIMÁRNÍ TABULKY s daty z tabulek czechia_payroll, czechia_payroll_industry_branch, czechia_price a czechia_price_category

# Vytvoření (případně nahrazení) prázdné tabulky "primary_final" se sloupci potřebnými pro další vyhodnocování
CREATE OR REPLACE TABLE t_Ondrej_Laskafeld_project_SQL_primary_final (
id INT AUTO_INCREMENT PRIMARY KEY,		# unikátní ID
year INT,								# Rok
industry_branch_code VARCHAR(255),		# Odvětví kód
industry_branch_name VARCHAR(255),      # Odvětví popis
payroll_value DECIMAL(10, 2),           # Mzdy
category_code DECIMAL(10, 2),           # Kód kategorie z czechia_price
category_name VARCHAR(255),             # Název kategorie z czechia_price_category
price_avg DECIMAL(10, 2),               # Průměrná cena
price_value DECIMAL(10, 2),             # Hodnota ceny
price_unit VARCHAR(50)                  # Jednotka ceny
);

# Vložení hodnot z "cp" do "primary_final" tabulky - rok, hodnoty mzdy, kód odvětví a z tabulky "cpib" přes JOIN na kód průmyslu vloženo jméno odvětní
# Pouze však hodnoty mzdy kde není "NULL", calculation_code = 100 tzn "fyzický" a unit_code = 200 tzn "Kč"
# Seřazeno podle roku a kódu odvětví
INSERT INTO t_Ondrej_Laskafeld_project_SQL_primary_final (YEAR, payroll_value, industry_branch_code, industry_branch_name)
SELECT cp.payroll_year, cp.value, cp.industry_branch_code, cpib.name
FROM czechia_payroll cp
JOIN czechia_payroll_industry_branch cpib ON cp.industry_branch_code = cpib.code
WHERE value IS NOT NULL AND calculation_code = "100" AND unit_code = "200"
GROUP BY
	cp.payroll_year,
	cp.industry_branch_code;

# Vložení hodnot z cpprice do "primary_final" tabulky - rok, kód potraviny, název potraviny, průměrná cena (v daném roce za všechny oblasti/kraje), množství a jednotky
# Seřazeno podle roku a kódu potraviny
INSERT INTO t_Ondrej_Laskafeld_project_SQL_primary_final (YEAR, category_code, category_name, price_avg, price_value, price_unit)
SELECT YEAR(cpprice.date_from), cpprice.category_code, cpcat.name, AVG(cpprice.value), cpcat.price_value, cpcat.price_unit
FROM czechia_price cpprice
JOIN czechia_price_category cpcat ON cpprice.category_code = cpcat.code
GROUP BY 
    YEAR(cpprice.date_from),
    cpprice.category_code;
#######################################################################################

# Vytvoří view kde dopočítá absolutní změnu "payroll_value", procentuální změnu a vytvoří sloupec (payroll_change) se slovním vyhodnocením změny mezd/platů.
CREATE OR REPLACE VIEW w_payroll_change AS
SELECT 
    year, 
    industry_branch_name, 
    payroll_value, 
    payroll_value - LAG(payroll_value) OVER (PARTITION BY industry_branch_name ORDER BY year) AS difference_payroll,
  	ROUND((100.0 * (payroll_value - LAG(payroll_value) OVER (PARTITION BY industry_branch_name ORDER BY year)) / LAG(payroll_value) OVER (PARTITION BY industry_branch_name ORDER BY year)), 2) AS percentage,
    CASE
        WHEN payroll_value - LAG(payroll_value) OVER (PARTITION BY industry_branch_name ORDER BY year) < 0 THEN "POKLES"
        WHEN payroll_value - LAG(payroll_value) OVER (PARTITION BY industry_branch_name ORDER BY year) > 0 THEN "Nárůst"
        ELSE "Bez změny"
    END AS payroll_change
FROM t_Ondrej_Laskafeld_project_SQL_primary_final
WHERE industry_branch_name IS NOT NULL;

# Vytvoří view jen s lety kde je pokles mezd/platů.
CREATE OR REPLACE VIEW w_payroll_result AS
SELECT *
FROM w_payroll_change 
WHERE payroll_change  = "POKLES";

# 1.
#######################################################################################
# Zobrazení výsledků odvětví a let kde klesaly mzdy/platy v podobě tabulky.
SELECT *
FROM w_payroll_result;

# Zobrazení textové podoby výsledků odvětví a let kde klesaly mzdy/platy v podobě tabulky.
SELECT 
	Concat(
	"V roce ", 
	year, 
	" byl v ", 
	industry_branch_name, 
	" plat ", 
	payroll_value, 
	" Kč, což je pokles o ", 
	difference_payroll, 
	"Kč a to je ",
	percentage, 
	"% - tzn. ", 
	payroll_change, 
	" oproti předchozímu roku."
	) AS Result_payroll
FROM w_payroll_result;
#######################################################################################

# Vytvoří view kde se spočítá průměrný plat napříč odvětvími v roce kdy jsou první a poslední data pro "chleba" a "mléko".
CREATE OR REPLACE VIEW w_avg_payroll AS
SELECT
	year AS year_payroll,
	ROUND(AVG(payroll_value), 2) AS avg_payroll
FROM t_Ondrej_Laskafeld_project_SQL_primary_final
WHERE 
	year = (SELECT MIN(year) FROM t_Ondrej_Laskafeld_project_SQL_primary_final
	WHERE category_name = "Chléb konzumní kmínový" 
		OR category_name = "Mléko polotučné pasterované") 
	OR year = (SELECT MAX(year) FROM t_Ondrej_Laskafeld_project_SQL_primary_final
	WHERE category_name = "Chléb konzumní kmínový" 
		OR category_name = "Mléko polotučné pasterované")
GROUP BY YEAR;

# Vytvoří view kde jsou roky, jméno produktu, cena v daném roce, a jednotky v kterých je věc prodávána. Následně vyfiltruje ceny jen pro "Chléb konzumní kmínový" a "Mléko polotučné pasterované",
# ale jen pro maximální a minimální roky kde se objevily ceny chlebu a mléka.
CREATE OR REPLACE VIEW w_bread_milk AS
SELECT
	year,
	category_name,
	price_avg,
	price_value,
	price_unit
FROM t_Ondrej_Laskafeld_project_SQL_primary_final
WHERE 
	(category_name = "Chléb konzumní kmínový" 
	OR category_name = "Mléko polotučné pasterované") 
	AND
	(year = (SELECT MIN(year) FROM t_Ondrej_Laskafeld_project_SQL_primary_final
	WHERE category_name = "Chléb konzumní kmínový" 
		OR category_name = "Mléko polotučné pasterované") 
	OR year = (SELECT MAX(year) FROM t_Ondrej_Laskafeld_project_SQL_primary_final
	WHERE category_name = "Chléb konzumní kmínový" 
		OR category_name = "Mléko polotučné pasterované"))
ORDER BY category_name;

# Vytvoří view kde jsou spojeny data "avg_payroll - průměrný plat" a ceny "chleba" a "mléka" za dané roky.
CREATE OR REPLACE VIEW w_bread_milk_per_year AS 
SELECT
	year,
	avg_payroll,
	category_name,
	price_avg,
	price_value,
	price_unit
FROM w_avg_payroll
INNER JOIN w_bread_milk ON w_avg_payroll.year_payroll = w_bread_milk.year;

# Vytvoří view kde je dopočítané množství "chleba" a "mléka", které bylo možné si koupit za průměrný plat v daném roce ("avg_amount").
CREATE OR REPLACE VIEW w_bread_milk_avg AS 
SELECT
	year,
	avg_payroll,
	category_name,
	price_avg,
	price_value,
	price_unit,
	ROUND((avg_payroll / price_avg), 2) AS avg_amount
FROM w_bread_milk_per_year;


# 2.
#######################################################################################
# Zobrazení výsledků průměrného množství koupitelného chleba a mléka v daných letech v podobě tabulky.
SELECT *
FROM w_bread_milk_avg;

# Zobrazení textové podoby výsledků průměrného množství koupitelného chleba a mléka v daných letech v podobě tabulky.
SELECT Concat(
		"Za rok ",
		year,
		" bylo možné si koupit ",
		avg_amount,
		" ",
		price_unit,
		" ",
		category_name
		) AS Result_food
FROM w_bread_milk_avg
ORDER BY category_name;
#######################################################################################


# Vytvoří view kde je vypočtena změna ceny pro jednotlivé potraviny mezi "minimálním" rokem a "maximálním" rokem v procentech.
CREATE OR REPLACE VIEW w_food_prices AS
SELECT
	id,
	year,
	category_name,
	price_avg,
	price_value,
	price_unit,
	ROUND((100.0 * (price_avg - LAG(price_avg) OVER (PARTITION BY category_name ORDER BY year)) / LAG(price_avg) OVER (PARTITION BY category_name ORDER BY year)), 2) AS food_percentage
FROM t_Ondrej_Laskafeld_project_SQL_primary_final
WHERE 
	category_name IS NOT NULL
	AND 
	YEAR IN (
	(SELECT MIN(year) FROM t_Ondrej_Laskafeld_project_SQL_primary_final 
	WHERE category_name IS NOT NULL), 
	(SELECT MAX(year) FROM t_Ondrej_Laskafeld_project_SQL_primary_final
	WHERE category_name IS NOT NULL )
	)
ORDER BY food_percentage;

# Vytvoří view kde doplní do každého řádku minimální a maximální rok, pro který jsou data dostupná.
CREATE OR REPLACE VIEW w_food_percentage_data AS
SELECT
	category_name,
	food_percentage,
	min(year) OVER () AS min_year,
	max(year) OVER () AS max_year
FROM w_food_prices;

# Vytvoří view kde jsou jen potraviny s největší zápornou změnou ceny (zlevnění) a nejnižší kladnou změnou ceny (nejmenší zdražení).
CREATE OR REPLACE VIEW w_food_percentage_results AS
SELECT *
FROM w_food_percentage_data
WHERE 
	food_percentage IS NOT NULL
	AND 
	(food_percentage < 0 AND food_percentage = (SELECT min(food_percentage) FROM w_food_percentage_data WHERE food_percentage < 0))
	OR 
	(food_percentage > 0 AND food_percentage = (SELECT min(food_percentage) FROM w_food_percentage_data WHERE food_percentage > 0))
ORDER BY food_percentage;

# 3.
#######################################################################################
# Zobrazení výsledků potravin s největším zlevněním a nejmenším zdražením.
SELECT *
FROM w_food_percentage_results;

# Zobrazení textové podoby výsledků potravin s největším zlevněním a nejmenším zdražením.
SELECT Concat(
		"Mezi roky ",
		min_year,
		" a ",
		max_year,
		CASE 
			WHEN food_percentage < 0 THEN " byl největší pokles ceny u "
			WHEN food_percentage > 0 THEN " byl nejmenší nárůst ceny u "
		END,
		category_name,
		" a to ",
		food_percentage,
		"%."
		) AS result_change
FROM w_food_percentage_results;
#######################################################################################


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
    SELECT MAX(diff_food_payroll_percent) as max_diff
    FROM w_food_payroll_dif_per_year)
SELECT "V žádném sledovaném roce nebylo zdražení průměrné ceny sledovaných potravin o 10% více než průměrná změna mezd/platů v daném roce." as message
FROM max_value
WHERE max_diff < 10
UNION ALL
SELECT Concat("V roce ", YEAR, " bylo průměrné zdražení potravin o ", diff_food_payroll_percent, "% více než průměrný nárůst mezd/platů.") 
FROM w_food_payroll_dif_per_year
WHERE diff_food_payroll_percent >= 10;
#######################################################################################

#######################################################################################
#VYTVOŘENÍ SEKUNDÁRNÍ TABULKY s daty z tabulek countries a economies.

# Vytvoření (případně nahrazení) prázdné tabulky "secondary_final" se sloupci potřebnými pro další vyhodnocování
CREATE OR REPLACE TABLE t_Ondrej_Laskafeld_project_SQL_secondary_final (
id INT AUTO_INCREMENT PRIMARY KEY,		# unikátní ID
country VARCHAR(255),					# Země/Stát
iso3 VARCHAR(5),						# ISO3 označení země
continent VARCHAR(50),                 	# Kontinent
population DECIMAL(15, 2),          	# Populace
population_density DECIMAL(15, 2),		# Hustota osídlení
surface_area DECIMAL(15, 2),			# Plocha
currency_name VARCHAR(50),				# Měna
currency_code VARCHAR(50),				# Kód měny
year INT,								# Rok
GDP DECIMAL(50, 2),           			# GDP
gini DECIMAL(10, 2),             		# Gini index
taxes DECIMAL(10, 2)              		# Daně
);

# Vloží do tabulky "secondary_final" data z tabulky countires (id je NULL kvůli CROSS JOINT) a pomocí cross joint vytvoří řádky
# s jednotlivými roky a ekonomickými ukazateli za dané roky. JOIN je udělaný podle názvů zemí.
INSERT INTO t_Ondrej_Laskafeld_project_SQL_secondary_final
SELECT 
    NULL,
    cn.country,
    cn.iso3,
    cn.continent,
    cn.population,
    cn.population_density,
    cn.surface_area,
    cn.currency_name,
    cn.currency_code,
    ec.year,
    ec.GDP,
    ec.gini,
    ec.taxes
FROM countries cn
CROSS JOIN economies ec
WHERE cn.country = ec.country;
#######################################################################################

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


# VÝSLEDKY
# 1.
#######################################################################################
# Zobrazení výsledků odvětví a let kde klesaly mzdy/platy v podobě tabulky.
SELECT *
FROM w_payroll_result;

# Zobrazení textové podoby výsledků odvětví a let kde klesaly mzdy/platy v podobě tabulky.
SELECT 
	Concat(
	"V roce ", 
	year, 
	" byl v ", 
	industry_branch_name, 
	" plat ", 
	payroll_value, 
	" Kč, což je pokles o ", 
	difference_payroll, 
	"Kč a to je ",
	percentage, 
	"% - tzn. ", 
	payroll_change, 
	" oproti předchozímu roku."
	) AS Result_payroll
FROM w_payroll_result;
#######################################################################################

# 2.
#######################################################################################
# Zobrazení výsledků průměrného množství koupitelného chleba a mléka v daných letech v podobě tabulky.
SELECT *
FROM w_bread_milk_avg;

# Zobrazení textové podoby výsledků průměrného množství koupitelného chleba a mléka v daných letech v podobě tabulky.
SELECT Concat(
		"Za rok ",
		year,
		" bylo možné si koupit ",
		avg_amount,
		" ",
		price_unit,
		" ",
		category_name
		) AS Result_food
FROM w_bread_milk_avg
ORDER BY category_name;
#######################################################################################

# 3.
#######################################################################################
# Zobrazení výsledků potravin s největším zlevněním a nejmenším zdražením.
SELECT *
FROM w_food_percentage_results;

# Zobrazení textové podoby výsledků potravin s největším zlevněním a nejmenším zdražením.
SELECT Concat(
		"Mezi roky ",
		min_year,
		" a ",
		max_year,
		CASE 
			WHEN food_percentage < 0 THEN " byl největší pokles ceny u "
			WHEN food_percentage > 0 THEN " byl nejmenší nárůst ceny u "
		END,
		category_name,
		" a to ",
		food_percentage,
		"%."
		) AS result_change
FROM w_food_percentage_results;
#######################################################################################

# 4.
#######################################################################################
# Zobrazení výsledků zda v nějakém roce rostly ceny potravin o 10 nebo více % ve srovnání s růstem mezd/platů.
SELECT *
FROM w_food_payroll_dif_per_year;

# Zobrazení textové podoby výsledků zda v nějakém roce rostly ceny potravin o 10 nebo více % ve srovnání s růstem mezd/platů.
WITH max_value AS (
    SELECT MAX(diff_food_payroll_percent) as max_diff
    FROM w_food_payroll_dif_per_year)
SELECT "V žádném sledovaném roce nebylo zdražení průměrné ceny sledovaných potravin o 10% více než průměrná změna mezd/platů v daném roce." as message
FROM max_value
WHERE max_diff < 10
UNION ALL
SELECT Concat("V roce ", YEAR, " bylo průměrné zdražení potravin o ", diff_food_payroll_percent, "% více než průměrný nárůst mezd/platů.") 
FROM w_food_payroll_dif_per_year
WHERE diff_food_payroll_percent >= 10;
#######################################################################################

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
