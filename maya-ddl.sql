-- partie de maya 
--creation des tables : processeur , memoire_ram, carte_graphique, ecran
CREATE TABLE PROCESSEUR (
    id_processeur INT AUTO_INCREMENT,
    modele VARCHAR(100) NOT NULL,
    vitesse_ghz DECIMAL(4,2) NOT NULL,
    nb_coeurs INT NOT NULL,
    CONSTRAINT PK_PROCESSEUR PRIMARY KEY (id_processeur)
);
CREATE TABLE MEMOIRE_RAM (
    id_ram INT AUTO_INCREMENT,
    capacite_gb INT NOT NULL,
    CONSTRAINT PK_MEMOIRE_RAM PRIMARY KEY(id_ram)
);
CREATE TABLE CARTE_GRAPHIQUE (
    id_gpu INT AUTO_INCREMENT,
    modele VARCHAR(100) NOT NULL,
    CONSTRAINT PK_CARTE_GRAPHIQUE PRIMARY KEY(id_gpu)
);

CREATE TABLE ECRAN(
    id_ecran INT AUTO_INCREMENT,
    diagonale_pouces DECIMAL(4,1) NOT NULL,
    CONSTRAINT PK_ECRAN PRIMARY KEY(id_ecran)
);

--Les index:
-- filtrage par type de processeur
CREATE INDEX idx_processeur_modele 
ON PROCESSEUR(modele);
--filtrage par performance du processeur
CREATE INDEX idx_processeur_vitesse
ON PROCESSEUR(vitesse_ghz);
--(filtrage par memoire : 8GB , 16GB , 32GB )
CREATE INDEX idx_ram_capacite
ON MEMOIRE_RAM(capacite_gb);
--filtrage sur la carte graphique
CREATE INDEX idx_carte_graphique_modele
ON CARTE_GRAPHIQUE(modele);
--filtrage par taille d'ecran 
CREATE INDEX idx_ecran_diagonale
ON ECRAN(diagonale_pouces);

--les vues
-- VUE N°1 : Fiche technique complete d'un produit 
CREATE VIEW VUE_COMPOSANTS_PRODUIT AS
SELECT 
        p.id_produit,
        p.nom_commercial        AS nom_produit,
        p.marque,
        p.prix_vente,
        p.etat,
        pr.modele               AS processeur,
        pr.vitesse_ghz,
        pr.nb_coeurs,
        r.capacite_gb           AS ram_gb,
        cg.modele               AS carte_graphique,
        e.diagonale_pouces      AS ecran_pouce
FROM PRODUIT p 
JOIN PROCESSEUR pr      ON p.id_processeur = pr.id_processeur
JOIN MEMOIRE_RAM r      ON p.id_ram        = r.id_ram
JOIN CARTE_GRAPHIQUE cg ON p.id_gpu        = cg.id_gpu
JOIN ECRAN e            ON p.id_ecran      = e.id_ecran;

-- VUE N°2 : classement des produits du moins cher au plus cher
-- utile pour les clients qui ont un budget limité
CREATE VIEW VUE_PRODUITS_PAR_PRIX AS 
SELECT 
        p.id_produit,
        p.nom_commercial        AS nom_produit,
        p.marque,
        p.prix_vente,
        p.etat,
        pr.modele               AS processeur,
        pr.vitesse_ghz,
        pr.nb_coeurs,
        r.capacite_gb           AS ram_gb,
        cg.modele               AS carte_graphique,
        e.diagonale_pouces      AS ecran_pouce
FROM PRODUIT p 
JOIN PROCESSEUR pr      ON p.id_processeur = pr.id_processeur
JOIN MEMOIRE_RAM r      ON p.id_ram        = r.id_ram
JOIN CARTE_GRAPHIQUE cg ON p.id_gpu        = cg.id_gpu
JOIN ECRAN e            ON p.id_ecran      = e.id_ecran
WHERE p.disponibilite = 'en_stock'
ORDER BY p.prix_vente ASC;

--Triggers 
DELIMITER $$
-- Trigger 1 : check si vitesse et nb_coeurs > 0
CREATE TRIGGER TRG_VERIF_PROCESSEUR_INSERT
BEFORE INSERT ON PROCESSEUR 
FOR EACH ROW
BEGIN 
    IF NEW.vitesse_ghz <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERREUR : la vitesse du processeur doit etre superieure a 0GHz.';
    END IF;
    IF NEW.nb_coeurs <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : le nombre de coeurs doit etre superieur a 0';
    END IF;
END$$

--Trigger 2 : check la meme chose a la modification 
CREATE TRIGGER TRG_VERIF_PROCESSEUR_UPDATE
BEFORE UPDATE ON PROCESSEUR 
FOR EACH ROW
BEGIN 
    IF NEW.vitesse_ghz <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERREUR : la vitesse du processeur doit etre superieure a 0GHz.';
    END IF;
    IF NEW.nb_coeurs <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : le nombre de coeurs doit etre superieur a 0';
    END IF;
END$$

--Trigger 3 : verification de la diagonale de l'ecran celle ci 
-- devrait etre entre 10 et 20 pouces 
CREATE TRIGGER TRG_VERIF_ECRAN_INSERT
BEFORE INSERT ON ECRAN
FOR EACH ROW 
BEGIN 
    IF NEW.diagonale_pouces < 10 OR NEW.diagonale_pouces > 20 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : la diagonale doit etre entre 10 et 20 pouces.';
    END IF;
END$$

DELIMITER ;


-- Données de TEST
INSERT INTO PROCESSEUR (modele, vitesse_ghz, nb_coeurs) VALUES
    ('Intel Core i5-1235U',  1.30, 10),
    ('Intel Core i7-1355U',  1.70, 10),
    ('Intel Core Ultra 7',   2.20, 16),
    ('AMD Ryzen 7 7730U',    2.00,  8),
    ('AMD Ryzen 5 7530U',    2.00,  6),
    ('Apple M3',             3.70,  8),
    ('Apple M3 Pro',         3.70, 11);
INSERT INTO MEMOIRE_RAM (capacite_gb) VALUES 
    (8),
    (16),
    (32),
    (64);
INSERT INTO CARTE_GRAPHIQUE (modele) VALUES
    ('Intel Iris Xe Graphics'),
    ('AMD Radeon Graphics'),
    ('NVIDIA GeForce RTX 4060'),
    ('NVIDIA GeForce RTX 4070'),
    ('Apple M3 GPU');
INSERT INTO ECRAN (diagonale_pouces) VALUES 
    (13.3),
    (14.0),
    (15.6),
    (16.0),
    (17.3);
