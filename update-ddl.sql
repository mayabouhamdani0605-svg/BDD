# BDD
-- partie de maya 
--creation des tables : processeur , memoire_ram, carte_graphique, ecran
CREATE TABLE PROCESSEUR (
    idProcesseur INT AUTO_INCREMENT,
    modele VARCHAR(100) NOT NULL,
    vitesse_ghz DECIMAL(4,2) NOT NULL,
    nb_coeurs INT NOT NULL,
    CONSTRAINT PK_PROCESSEUR PRIMARY KEY (idProcesseur)
);
CREATE TABLE MEMOIRE_RAM (
    id_ram INT AUTO_INCREMENT,
    capacite_gb INT NOT NULL ,
    CONSTRAINT PK_MEMOIRE_RAM PRIMARY KEY(id_ram)
);
CREATE TABLE CARTE_GRAPHIQUE (
    idCarteGraphique INT AUTO_INCREMENT,
    modele VARCHAR(100) NOT NULL,
    CONSTRAINT PK_CARTE_GRAPHIQUE PRIMARY KEY(idCarteGraphique)
);

CREATE TABLE ECRAN(
    idEcran INT AUTO_INCREMENT,
    diagonale_pouce DECIMAL(4,1) NOT NULL,
    CONSTRAINT PK_ECRAN PRIMARY KEY(idEcran)
);
-- Création de la table CATEGORIE
CREATE TABLE CATEGORIE (
    id_categorie INT AUTO_INCREMENT PRIMARY KEY,
    nom_categorie VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);   
-- Création de la table PRODUIT
CREATE TABLE PRODUIT (
    id_produit INT AUTO_INCREMENT PRIMARY KEY,

    ref_produit VARCHAR(50) UNIQUE,
    nom_commercial VARCHAR(150) NOT NULL,
    marque VARCHAR(50) NOT NULL,
    prix_vente DECIMAL(10,2) NOT NULL,

    etat ENUM('nouveau', 'reconditionne') NOT NULL,
    disponibilite ENUM('en_stock', 'bientot_disponible') NOT NULL,

    stock_quantite INT NOT NULL,

    os VARCHAR(50),
    poids_kg DECIMAL(4,2),
    image VARCHAR(255),
    description TEXT,

    -- catégorie
    id_categorie INT NOT NULL,

    -- composants
    idProcesseur INT NOT NULL,
    id_ram INT NOT NULL,
    idCarteGraphique INT NOT NULL,
    idEcran INT NOT NULL,

    CONSTRAINT fk_produit_categorie
        FOREIGN KEY (id_categorie)
        REFERENCES CATEGORIE(id_categorie),

    CONSTRAINT fk_proc
        FOREIGN KEY (idProcesseur)
        REFERENCES PROCESSEUR(idProcesseur),

    CONSTRAINT fk_ram
        FOREIGN KEY (id_ram)
        REFERENCES MEMOIRE_RAM(id_ram),

    CONSTRAINT fk_gpu
        FOREIGN KEY (idCarteGraphique)
        REFERENCES CARTE_GRAPHIQUE(idCarteGraphique),

    CONSTRAINT fk_ecran
        FOREIGN KEY (idEcran)
        REFERENCES ECRAN(idEcran)
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
ON ECRAN(diagonale_pouce);
CREATE INDEX idx_produit_categorie 
ON PRODUIT(id_categorie);
--les vues
-- VUE N°1 : Fiche technique complete d'un produit 
CREATE VIEW VUE_COMPOSANTS_PRODUIT AS
SELECT 
        p.id_produit,
        p.nom_commercial              AS nom_produit,
        p.marque,
        p.prix_vente,
        p.etat,
        pr.modele           AS processeur,
        pr.vitesse_ghz,
        pr.nb_coeurs,
        r.capacite_gb       AS ram_gb,
        cg.modele           AS carte_graphique,
        e.diagonale_pouce   AS ecran_pouce
FROM PRODUIT p 
JOIN PROCESSEUR pr ON p.idProcesseur = pr.idProcesseur
JOIN MEMOIRE_RAM r ON p.id_ram = r.id_ram
JOIN CARTE_GRAPHIQUE cg ON p.idCarteGraphique = cg.idCarteGraphique
JOIN ECRAN e ON p.idEcran = e.idEcran;

-- VUE N°2 : classement des produits du moins cher au plus cher
-- utile pour les clients qui ont un budget limité
CREATE VIEW VUE_PRODUITS_PAR_PRIX AS 
SELECT 
        p.id_produit,
        p.nom_commercial              AS nom_produit,
        p.marque,
        p.prix_vente,
        p.etat,
        pr.modele           AS processeur,
        pr.vitesse_ghz,
        pr.nb_coeurs,
        r.capacite_gb       AS ram_gb,
        cg.modele           AS carte_graphique,
        e.diagonale_pouce   AS ecran_pouce
FROM PRODUIT p 
JOIN PROCESSEUR pr ON p.idProcesseur = pr.idProcesseur
JOIN MEMOIRE_RAM r ON p.id_ram = r.id_ram
JOIN CARTE_GRAPHIQUE cg ON p.idCarteGraphique = cg.idCarteGraphique
JOIN ECRAN e ON p.idEcran = e.idEcran
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
       SET MESSAGE_TEXT = ' Erreur : le nombre de coeurs doit etre superieur a 0';
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
       SET MESSAGE_TEXT = ' Erreur : le nombre de coeurs doit etre superieur a 0';
    END IF;
END$$

--Trigger 3 : verification de la diagonale de l'ecran celle ci 
-- devrait etre entre 10 et 20 pouces 
CREATE TRIGGER TRG_VERIF_ECRAN_INSERT
BEFORE INSERT ON ECRAN
FOR EACH ROW 
BEGIN 
    IF NEW.diagonale_pouce <10 OR NEW.diagonale_pouce > 20 THEN
     SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT ='Erreur : la diagonale doit etre entre 10 et 20 pouces.';
    END IF;
END$$

--Trigger 4 : rigger empêche de mettre une quantité négative et si la quantite egale a 0 
CREATE TRIGGER tr_check_stock_update
BEFORE UPDATE ON PRODUIT
FOR EACH ROW
BEGIN
    -- Si la nouvelle quantité est inférieure à 0
    IF NEW.stock_quantite < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Opération annulée : Stock insuffisant pour ce produit.';
    END IF;
    
    -- Changer automatiquement la disponibilité si le stock tombe à 0
    IF NEW.stock_quantite = 0 THEN
        SET NEW.disponibilite = 'bientot_disponible';
    END IF;
END$$
-- Trigger 5 :  pour vérifier le prix lors de l'insertion
CREATE TRIGGER TRG_VERIF_PRIX_INSERT
BEFORE INSERT ON PRODUIT
FOR EACH ROW
BEGIN
    -- Vérifie si le prix est inférieur ou égal à 0 [1]
    IF NEW.prix_vente <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : Le prix de vente doit être strictement supérieur à 0.';
    END IF;
END$$

-- -- Trigger 6 : pour vérifier le prix lors de mises à jour
CREATE TRIGGER TRG_VERIF_PRIX_UPDATE
BEFORE UPDATE ON PRODUIT
FOR EACH ROW
BEGIN
    IF NEW.prix_vente <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : Le prix de vente ne peut pas être modifié par une valeur négative ou nulle.';
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
INSERT INTO ECRAN (diagonale_pouce) VALUES 
    (13.3),
    (14.0),
    (15.6),
    (16.0),
    (17.3);
INSERT INTO CATEGORIE (nom_categorie) VALUES 
('PC Portable Windows'), 
('Apple MacBook'), 
('PC Portable Gamer'), 
('Google Chrome OS');
