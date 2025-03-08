
# Pro tuto část příkazů je třeba tabulka "t_Ondrej_Laskafeld_project_SQL_primary_final"
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