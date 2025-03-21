
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

# Vloží do tabulky "secondary_final" data z tabulky countires (id je NULL kvůli CROSS JOINT) a pomocí CROSS JOINT vytvoří řádky
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
