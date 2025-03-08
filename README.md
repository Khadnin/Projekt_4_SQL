
# Projekt_3_Election_scraper

## Účel
Tento projekt slouží k zodpovězení těchto otázek z dostupných dat:
1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?

## Dostupné soubory a SQL sady

### Vstupní data

Pro následují soubory je vždy dostupná `*.csv` a `*.frm` + `*.idb` verze.
| Název             | Popis                                                                |
| ----------------- | ------------------------------------------------------------------ |
| countries | Všemožné informace o zemích na světě, například hlavní město, měna, národní jídlo nebo průměrná výška populace. |
| czechia_payroll | Informace o mzdách v různých odvětvích za několikaleté období. Datová sada pochází z Portálu otevřených dat ČR. |
| czechia_payroll_industry_branch | Číselník odvětví v tabulce mezd. |
| czechia_price | Informace o cenách vybraných potravin za několikaleté období. Datová sada pochází z Portálu otevřených dat ČR. |
| czechia_price_category | Číselník kategorií potravin, které se vyskytují v našem přehledu. |
| economies | HDP, GINI, daňová zátěž, atd. pro daný stát a rok. |
| t_ondrej_laskafeld_project_sql_primary_final | Tabulka s daty ohledně potravin a mezd/platů pro ČR. |
| t_ondrej_laskafeld_project_sql_secondary_final | Tabulka s daty ohledně HDP pro svět včetně ČR. |


### SQL sady
Následující soubory sql slouží k získání dat a odpovědí na otázky zmínění v "účelu".
| Název             | Popis                                                                |
| ----------------- | ------------------------------------------------------------------ |
| 0_projekt_4_SQL_1 | Souhrná SQL sada obsahující všechny potřebné příkazy s průběžným vypisováním výsledků pro jednotlívé otázky. |
| 1_create_primary_table | SQL sada pro tvorbu t_ondrej_laskafeld_project_sql_primary_final. |
| 2_create_secondary_table | SQL sada pro tvorbu t_ondrej_laskafeld_project_sql_secondary_final. |
| 3_task_1_payrolls | SQL sada pro odpovězení na 1. otázku ohledně růstu mezd/platů. |
| 4_task_2_bread_milk | SQL sada pro odpovězení na 2. otázku ohledně možnosti koupě chleba a mléka. |
| 5_task_3_food_change | SQL sada pro odpovězení na 3. otázku ohledně zdražování potravin. |
| 6_task_4_food_payroll_comparison | SQL sada pro odpovězení na 4. otázku ohledně porovnání růstu cen potravin a platů. |
| 7_task_5_GDP_food_payroll_link | SQL sada pro odpovězení na 5. otázku ohledně vlivu HDP na růst cen potravin a platů. |
| 8_project_4_SQL_2 | Souhrná SQL sada obsahující všechny potřebné příkazy s vypsáním výsledků až na konci sady. |

Pro správnou funkci SQL sad `3`-`7` je třeba mít dostupné `t_ondrej_laskafeld_project_sql_primary_final` a `t_ondrej_laskafeld_project_sql_secondary_final`. Tzn. je třeba nejdříve spustit sady `1` a `2` nebo použít postupně strukturované sady `0` a `8`.

## Použitý SW

Databáze/tabulky jsou generovány z MySQL/MariaDB `Server version: 11.5.2-MariaDB mariadb.org binary distribution`.

Odkaz s možností stáhnutí MariaDB [ZDE](https://mariadb.org).

Veškeré SQL sady jsou psané a funkčně ověřené v DBeaver `Version 25.0.0.202503021833`.

Odkaz s možností stáhnutí DBeaver [ZDE](https://dbeaver.com).

## Ukázka projektu

Vždy jsou možnosti nechat si ukázat výsledná data v tabulce nebo slovně popsaná.

Např. výsledky pro 2. otázku `Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?`:

- Po spuštění:
```
# Zobrazení výsledků průměrného množství koupitelného chleba a mléka v daných letech v podobě tabulky.
SELECT *
FROM w_bread_milk_avg;
```
Výsledná číselná data v tabulce po spuštění:
| year | avg_payroll | category_name | price_avg | price_value | price_unit | avg_amount |
| ---- | ----------- | ------------- | --------- |------------ | ---------- | ---------- |
| 2,006 | 19,252.53 | Chléb konzumní kmínový | 16.12 | 1 | kg | 1,194.33 |
| 2,006 | 19,252.53 | Mléko polotučné pasterované | 14.44 | 1 | l | 1,333.28 |
| 2,018 | 31,992.21 | Chléb konzumní kmínový | 24.24 | 1 | kg | 1,319.81 |
| 2,018 | 31,992.21 | Mléko polotučné pasterované | 19.82 | 1 | l | 1,614.14 |

- Po spuštění:
```
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
```
Výsledné slovní vyhodnocení po spuštění:
| Result_food |
| ----------- |
| Za rok 2006 bylo možné si koupit 1194.33 kg Chléb konzumní kmínový |
| Za rok 2018 bylo možné si koupit 1319.81 kg Chléb konzumní kmínový |
| Za rok 2006 bylo možné si koupit 1333.28 l Mléko polotučné pasterované |
| Za rok 2018 bylo možné si koupit 1614.14 l Mléko polotučné pasterované |
