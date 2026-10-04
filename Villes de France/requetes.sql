USE ville_de_france;

DESCRIBE villes_france_free;

SHOW COLUMNS from villes_france_free;

-- Obtenir la liste des 10 villes les plus peuplées en 2012
SELECT ville_id, ville_nom, ville_population_2012
FROM villes_france_free
ORDER BY ville_population_2012 DESC
LIMIT 10


-- Obtenir la liste des 50 villes ayant la plus faible superficie
SELECT ville_id, ville_nom, ville_surface
FROM villes_france_free
ORDER BY ville_surface
LIMIT 50


-- Obtenir la liste des départements d’outres-mer, c’est-à-dire ceux dont le numéro de département commencent par « 97 »
SELECT *
FROM departement
WHERE departement_code LIKE '97%'


-- Obtenir le nom des 10 villes les plus peuplées en 2012, ainsi que le nom du département associé
SELECT ville_id, ville_nom, departement_nom, ville_population_2012
FROM villes_france_free v
JOIN departement d on v.ville_departement = d.departement_code
ORDER BY ville_population_2012 DESC
LIMIT 10


/* Obtenir la liste du nom de chaque département, associé à son code et du nombre de commune au sein 
de ces département, en triant afin d’obtenir en priorité les départements qui possèdent le plus de 
communes */
SELECT d.departement_nom, v.ville_departement, COUNT(*) AS nbr_items 
FROM villes_france_free v
LEFT JOIN departement d ON d.departement_code = v.ville_departement
GROUP BY d.departement_nom, v.ville_departement
ORDER BY nbr_items DESC


-- Obtenir la liste des 10 plus grands départements, en terme de superficie
SELECT d.departement_nom, v.ville_departement, SUM(`ville_surface`) AS dpt_surface 
FROM villes_france_free v
LEFT JOIN departement d ON d.departement_code = v.ville_departement
GROUP BY d.departement_nom, v.ville_departement
ORDER BY dpt_surface DESC
LIMIT 10


-- Compter le nombre de villes dont le nom commence par « Saint »
SELECT COUNT(ville_nom)
FROM villes_france_free
WHERE ville_nom LIKE 'SAINT%'


/*Obtenir la liste des villes qui ont un nom existants plusieurs fois, et trier afin d’obtenir 
en premier celles dont le nom est le plus souvent utilisé par plusieurs communes */
SELECT ville_nom, COUNT(*) AS nbt_item 
FROM villes_france_free
GROUP BY ville_nom
ORDER BY nbt_item DESC


/* Obtenir en une seule requête SQL la liste des villes dont la superficie est supérieur à la 
superficie moyenne */
SELECT ville_nom, ville_surface
FROM villes_france_free
where ville_surface > (
    SELECT AVG(ville_surface)
    FROM villes_france_free
)


-- Obtenir la liste des départements qui possèdent plus de 2 millions d’habitants
SELECT ville_departement, SUM(ville_population_2012) AS population_2012
FROM villes_france_free
GROUP BY ville_departement
HAVING population_2012 > 2000000
ORDER BY population_2012 DESC


/* Remplacez les tirets par un espace vide, pour toutes les villes commençant par 
« SAINT- » (dans la colonne qui contient les noms en majuscule) */
UPDATE villes_france_free
SET ville_nom = REPLACE(ville_nom, '-', ' ') 
WHERE ville_nom LIKE 'SAINT-%'

SELECT *
FROM villes_france_free
WHERE ville_nom LIKE 'SAINT-%'