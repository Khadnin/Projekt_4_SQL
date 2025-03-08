
# Pro tuto část příkazů je třeba tabulka "t_Ondrej_Laskafeld_project_SQL_primary_final"
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