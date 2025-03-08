
# Pro tuto část příkazů je třeba tabulka "t_Ondrej_Laskafeld_project_SQL_primary_final"
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