
#######################################################################################
#VYTVOŘENÍ PRIMÁRNÍ TABULKY s daty z tabulek czechia_payroll, czechia_payroll_industry_branch, czechia_price a czechia_price_category.

# Vytvoření (případně nahrazení) prázdné tabulky "primary_final" se sloupci potřebnými pro další vyhodnocování.
CREATE OR REPLACE TABLE t_Ondrej_Laskafeld_project_SQL_primary_final (
id INT AUTO_INCREMENT PRIMARY KEY,		# unikátní ID
year INT,					# Rok
industry_branch_code VARCHAR(255),		# Odvětví kód
industry_branch_name VARCHAR(255),     		# Odvětví popis
payroll_value DECIMAL(10, 2),           	# Mzdy
category_code DECIMAL(10, 2),           	# Kód kategorie z czechia_price
category_name VARCHAR(255),             	# Název kategorie z czechia_price_category
price_avg DECIMAL(10, 2),               	# Průměrná cena
price_value DECIMAL(10, 2),             	# Hodnota ceny
price_unit VARCHAR(50)                  	# Jednotka ceny
);

# Vložení hodnot z "cp" do "primary_final" tabulky - rok, hodnoty mzdy, kód odvětví a z tabulky "cpib" přes JOIN na kód průmyslu vloženo jméno odvětní.
# Pouze však hodnoty mzdy kde není "NULL", calculation_code = 100 tzn "fyzický" a unit_code = 200 tzn "Kč".
# Seřazeno podle roku a kódu odvětví.
INSERT INTO t_Ondrej_Laskafeld_project_SQL_primary_final (year, payroll_value, industry_branch_code, industry_branch_name)
SELECT cp.payroll_year, cp.value, cp.industry_branch_code, cpib.name
FROM czechia_payroll cp
JOIN czechia_payroll_industry_branch cpib ON cp.industry_branch_code = cpib.code
WHERE value IS NOT NULL AND calculation_code = "100" AND unit_code = "200"
GROUP BY
	cp.payroll_year,
	cp.industry_branch_code;

# Vložení hodnot z cpprice do "primary_final" tabulky - rok, kód potraviny, název potraviny, průměrná cena (v daném roce za všechny oblasti/kraje), množství a jednotky.
# Seřazeno podle roku a kódu potraviny.
INSERT INTO t_Ondrej_Laskafeld_project_SQL_primary_final (year, category_code, category_name, price_avg, price_value, price_unit)
SELECT YEAR(cpprice.date_from), cpprice.category_code, cpcat.name, AVG(cpprice.value), cpcat.price_value, cpcat.price_unit
FROM czechia_price cpprice
JOIN czechia_price_category cpcat ON cpprice.category_code = cpcat.code
GROUP BY 
    YEAR(cpprice.date_from),
    cpprice.category_code;
#######################################################################################
