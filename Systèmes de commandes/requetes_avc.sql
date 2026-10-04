USE systeme_de_commandes

SHOW COLUMNS FROM client;

SHOW COLUMNS FROM commande;

SHOW COLUMNS FROM commande_ligne;

/* Obtenir l’utilisateur ayant le prénom « Muriel » et le mot de passe « test11 », 
sachant que l’encodage du mot de passe est effectué avec l’algorithme Sha1. */
-- #region 1.
SELECT prenom, password
FROM client
WHERE prenom = 'MURIEL'
AND password = SHA1('test11');
-- #endregion


-- Obtenir la liste de tous les produits qui sont présent sur plusieurs commandes.
-- #region 2.
SELECT nom, COUNT(nom) as nbr_item
FROM commande_ligne
GROUP BY nom
HAVING nbr_item > 1;
-- #endregion


/* Obtenir la liste de tous les produits qui sont présent sur plusieurs commandes et y 
ajouter une colonne qui liste les identifiants des commandes associées. */
-- #region 3.
SELECT cl.id, cl.nom
FROM commande_ligne cl
INNER JOIN (
    SELECT nom
    FROM commande_ligne
    GROUP BY nom
    HAVING COUNT(nom) > 1
) cl_temp ON cl.nom = cl_temp.nom;

/*
-- meme requete + ajout de la colonne
SELECT nom, COUNT(*) AS nbr_items , GROUP_CONCAT(`commande_id`) AS liste_commandes
FROM `commande_ligne` 
GROUP BY nom 
HAVING nbr_items > 1
ORDER BY nbr_items DESC
*/
-- #endregion


/* Enregistrer le prix total à l’intérieur de chaque ligne des commandes, en fonction 
du prix unitaire et de la quantité */
-- #region 4.
UPDATE commande_ligne
SET prix_total = quantite * prix_unitaire
WHERE prix_total = 0;
-- verification
SELECT id, prix_total
FROM commande_ligne
WHERE prix_total != 0;
-- #endregion


/* Obtenir le montant total pour chaque commande et y voir facilement la date associée 
à cette commande ainsi que le prénom et nom du client associé */
-- #region 5.
SELECT SUM(coml.prix_total) as mtt_total, c.date_achat, cl.prenom, cl.nom
FROM commande c
LEFT JOIN client cl ON c.client_id = cl.id
LEFT JOIN commande_ligne coml ON c.id = coml.commande_id
GROUP BY c.date_achat, cl.prenom, cl.nom;
/*
SELECT client.prenom, client.nom, commande.date_achat, commande_id, SUM(prix_total) AS prix_commande 
FROM `commande_ligne` 
LEFT JOIN commande ON commande.id = commande_ligne.commande_id
LEFT JOIN client ON client.id = commande.client_id
GROUP BY `commande_id`
*/
-- #endregion


/* (difficulté très haute) Enregistrer le montant total de chaque commande dans le champ intitulé 
« cache_prix_total » */
-- #region 6.
UPDATE commande c
JOIN (
    SELECT SUM(prix_total) as total_calcule, commande_id
    FROM commande_ligne
    GROUP BY commande_id
) c_temp ON c.id = c_temp.commande_id
SET cache_prix_total = c_temp.total_calcule
-- WHERE cache_prix_total = 0
;
-- Verifier
SELECT *
FROM commande;
-- #endregion


-- Obtenir le montant global de toutes les commandes, pour chaque mois
-- #region 7.
SELECT 
    SUM(cache_prix_total) as mtt_global, 
    DATE_FORMAT(date_achat, '%Y-%m') as mois
FROM commande
GROUP BY DATE_FORMAT(date_achat, '%Y-%m')
ORDER BY mois;
-- #endregion


/* Obtenir la liste des 10 clients qui ont effectué le plus grand montant de commandes, 
et obtenir ce montant total pour chaque client. */
-- #region 8.
SELECT prenom, nom, COUNT(client_id) as nbr_cmd, SUM(cache_prix_total) as mtt_total
FROM client cl
LEFT JOIN commande c ON cl.id = c.client_id
GROUP BY prenom, nom
ORDER BY nbr_cmd DESC
LIMIT 10;
-- #endregion


-- Obtenir le montant total des commandes pour chaque date
-- #region 9.
SELECT date_achat, SUM(cache_prix_total) as mtt_total
FROM commande
GROUP BY date_achat;
-- #endregion


/* Ajouter une colonne intitulée « category » à la table contenant les commandes. Cette colonne 
contiendra une valeur numérique
Enregistrer la valeur de la catégorie, en suivant les règles suivantes :
« 1 » pour les commandes de moins de 200€
« 2 » pour les commandes entre 200€ et 500€
« 3 » pour les commandes entre 500€ et 1.000€
« 4 » pour les commandes supérieures à 1.000€
*/
-- #region 10.
ALTER TABLE commande
ADD category TINYINT UNSIGNED;

-- Rechercher pour mieux verifier avant
SELECT category
FROM commande
WHERE category IS NULL;

UPDATE commande c
JOIN (
    SELECT id,
    CASE
        WHEN cache_prix_total < 200 THEN 1
        WHEN cache_prix_total >= 200 AND cache_prix_total < 500 THEN 2
        WHEN cache_prix_total >= 500 AND cache_prix_total < 1000 THEN 3
        ELSE 4
    END AS cat
    FROM commande
) c_temp ON c.id = c_temp.id
SET c.category = c_temp.cat
WHERE c.category IS NULL;

-- Plus epure
UPDATE `commande` 
SET `category` = (
  CASE 
     WHEN cache_prix_total<200 THEN 1
     WHEN cache_prix_total<500 THEN 2
     WHEN cache_prix_total<1000 THEN 3
     ELSE 4
  END )

-- Verifier
SELECT id, cache_prix_total, category
FROM commande
ORDER BY cache_prix_total;
-- #endregion


-- Créer une table intitulée « commande_category » qui contiendra le descriptif de ces catégories
-- #region 11.
ALTER TABLE commande
ADD commande_category VARCHAR(255); -- descriptif phrase d'accroche
-- Rechercher a verifier avant changement
SELECT commande_category
FROM commande;
-- #endregion


-- Insérer les 4 descriptifs de chaque catégorie au sein de la table précédemment créée
-- #region 12.
UPDATE commande c
JOIN (
    SELECT id,
    CASE 
        WHEN  category = 1 THEN  'commandes de moins de 200€'
        WHEN  category = 2 THEN  'commandes entre 200€ et 500€'
        WHEN  category = 3 THEN  'commandes entre 500€ et 1.000€'
        ELSE  'commandes supérieures à 1.000€'
    END as cat_desc
    FROM commande
) c_temp ON c.id = c_temp.id
SET c.commande_category = c_temp.cat_desc
WHERE c.commande_category IS NULL;

SELECT id, cache_prix_total, category, commande_category
FROM commande;

/* -- l'exercice demandait ça

CREATE TABLE `commande_category` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nom` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


INSERT INTO `commande_category` (`id`, `nom`) VALUES (1, 'commandes de moins de 200€');
INSERT INTO `commande_category` (`id`, `nom`) VALUES (2, 'commandes entre 200€ et 500€');
INSERT INTO `commande_category` (`id`, `nom`) VALUES (3, 'commandes entre 500€ et 1.000€');
INSERT INTO `commande_category` (`id`, `nom`) VALUES (4, 'commandes supérieures à 1.000€');
*/
-- #endregion


/* Supprimer toutes les commandes (et les lignes des commandes) inférieur au 1er février 2019. 
Cela doit être effectué en 2 requêtes maximum */
-- #region 13.
-- commande_ligne.id = (request)

-- Verifier les changements avant
SELECT COUNT('id') as combien
FROM commande
WHERE date_achat < '2019-02-01'; --24

SELECT SUM(coml.id) as combien
FROM commande_ligne coml
LEFT JOIN commande c ON coml.commande_id = c.id
WHERE c.date_achat < '2019-02-01'; --1711

DELETE coml
FROM commande_ligne coml
LEFT JOIN commande c ON coml.commande_id = c.id
WHERE c.date_achat < '2019-02-01';

DELETE FROM commande
WHERE date_achat < '2019-02-01';

/* --plus court
DELETE FROM `commande_ligne` 
WHERE `commande_id` IN ( SELECT id FROM commande WHERE date_achat < '2019-02-01' );
DELETE FROM `commande` WHERE date_achat < '2019-02-01';
*/

-- verifier la suppression commande
SELECT COUNT('id') as combien
FROM commande
WHERE date_achat < '2019-02-01'; --0

SELECT COUNT('id') as combien
FROM commande
WHERE date_achat >= '2019-02-01'; --24

-- Verifie suppression commande_ligne
SELECT SUM(coml.id) as combien
FROM commande_ligne coml
LEFT JOIN commande c ON coml.commande_id = c.id
WHERE c.date_achat < '2019-02-01';

SELECT SUM(coml.id) as combien
FROM commande_ligne coml
LEFT JOIN commande c ON coml.commande_id = c.id
WHERE c.date_achat <= '2019-02-01';
-- #endregion