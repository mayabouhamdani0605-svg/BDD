-- partie de maya 
-- creation des tables : processeur , memoire_ram, carte_graphique, ecran
CREATE TABLE PROCESSEUR (
    idProcesseur INT AUTO_INCREMENT,
    modele VARCHAR(100) NOT NULL,
    vitesse_ghz DECIMAL(4,2) NOT NULL,
    nb_coeurs INT NOT NULL,
    CONSTRAINT PK_PROCESSEUR PRIMARY KEY (idProcesseur)
);
CREATE TABLE MEMOIRE_RAM (
    id_ram INT AUTO_INCREMENT,
    capacite_gb INT NOT NULL,
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

-- Les index:
-- filtrage par type de processeur
CREATE INDEX idx_processeur_modele 
ON PROCESSEUR(modele);
-- filtrage par performance du processeur
CREATE INDEX idx_processeur_vitesse
ON PROCESSEUR(vitesse_ghz);
-- (filtrage par memoire : 8GB , 16GB , 32GB )
CREATE INDEX idx_ram_capacite
ON MEMOIRE_RAM(capacite_gb);
-- filtrage sur la carte graphique
CREATE INDEX idx_carte_graphique_modele
ON CARTE_GRAPHIQUE(modele);
-- filtrage par taille d'ecran 
CREATE INDEX idx_ecran_diagonale
ON ECRAN(diagonale_pouce);
CREATE INDEX idx_produit_categorie 
ON PRODUIT(id_categorie);
-- les vues
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

-- Triggers 
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

-- Trigger 2 : check la meme chose a la modification 
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

-- Trigger 3 : verification de la diagonale de l'ecran celle ci 
-- devrait etre entre 10 et 20 pouces 
CREATE TRIGGER TRG_VERIF_ECRAN_INSERT
BEFORE INSERT ON ECRAN
FOR EACH ROW 
BEGIN 
    IF NEW.diagonale_pouce < 10 OR NEW.diagonale_pouce > 20 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : la diagonale doit etre entre 10 et 20 pouces.';
    END IF;
END$$

-- Trigger 4 : rigger empêche de mettre une quantité négative et si la quantite egale a 0 
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


INSERT INTO PRODUIT (ref_produit, nom_commercial, marque, prix_vente, etat, disponibilite, stock_quantite, os, poids_kg, description, id_categorie, idProcesseur, id_ram, idCarteGraphique, idEcran) VALUES
    ('LAP-001', 'Dell XPS 15', 'Dell', 2499.00, 'nouveau', 'en_stock', 10, 'Windows 11', 1.86, 'Laptop haut de gamme', 1, 2, 2, 3, 3),
    ('LAP-002', 'HP Pavilion 14', 'HP', 1399.00, 'nouveau', 'en_stock', 15, 'Windows 11', 1.41, 'Laptop milieu de gamme', 1, 1, 1, 1, 2);

-- BDD - Partie Ahmed
-- Schéma logique : CLIENT, COMMANDE, LIGNE_COMMANDE, AVIS
-- Prérequis : la table PRODUIT existe deja (avec id_produit)

CREATE TABLE CLIENT (
    id_client INT AUTO_INCREMENT,
    id_utilisateur INT NULL,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    telephone VARCHAR(30),
    adresse_livraison TEXT,
    statut_compte ENUM('actif', 'inactif') NOT NULL DEFAULT 'actif',
    date_inscription DATE NOT NULL,
    CONSTRAINT PK_CLIENT PRIMARY KEY (id_client)
);

CREATE TABLE COMMANDE (
    id_commande INT AUTO_INCREMENT,
    date_commande DATE NOT NULL,
    statut ENUM('en_cours', 'livree', 'annulee') NOT NULL,
    prix_total DECIMAL(10,2) NOT NULL,
    adresse_livraison TEXT,
    id_client INT NULL,
    CONSTRAINT PK_COMMANDE PRIMARY KEY (id_commande),
    CONSTRAINT FK_COMMANDE_CLIENT FOREIGN KEY (id_client)
        REFERENCES CLIENT(id_client)
);

CREATE TABLE LIGNE_COMMANDE (
    id_commande INT NOT NULL,
    id_produit INT NOT NULL,
    quantite INT NOT NULL CHECK (quantite > 0),
    prix_unitaire_capture DECIMAL(10,2) NOT NULL CHECK (prix_unitaire_capture > 0),
    CONSTRAINT PK_LIGNE_COMMANDE PRIMARY KEY (id_commande, id_produit),
    CONSTRAINT FK_LIGNE_COMMANDE_COMMANDE FOREIGN KEY (id_commande)
        REFERENCES COMMANDE(id_commande) ON DELETE CASCADE,
    CONSTRAINT FK_LIGNE_COMMANDE_PRODUIT FOREIGN KEY (id_produit)
        REFERENCES PRODUIT(id_produit) ON DELETE RESTRICT
);

CREATE TABLE AVIS (
    id_avis INT AUTO_INCREMENT,
    id_client INT NULL,
    id_produit INT NOT NULL,
    note_sur_5 INT NOT NULL CHECK (note_sur_5 >= 1 AND note_sur_5 <= 5),
    commentaire TEXT,
    date_avis DATE NOT NULL,
    CONSTRAINT PK_AVIS PRIMARY KEY (id_avis),
    CONSTRAINT FK_AVIS_CLIENT FOREIGN KEY (id_client)
        REFERENCES CLIENT(id_client) ON DELETE SET NULL,
    CONSTRAINT FK_AVIS_PRODUIT FOREIGN KEY (id_produit)
        REFERENCES PRODUIT(id_produit) ON DELETE RESTRICT,
    CONSTRAINT UK_AVIS_CLIENT_PRODUIT UNIQUE (id_client, id_produit)
);


-- INDEX


CREATE INDEX idx_avis_produit
ON AVIS(id_produit);

CREATE INDEX idx_commande_client
ON COMMANDE(id_client);

CREATE INDEX idx_commande_date
ON COMMANDE(date_commande);


-- TRIGGERS


DELIMITER $$

-- Trigger 1 : RGPD, avant suppression d'un client
CREATE TRIGGER TRG_RGPD_DESINSCRIPTION
BEFORE DELETE ON CLIENT
FOR EACH ROW
BEGIN
    UPDATE COMMANDE
    SET id_client = NULL
    WHERE id_client = OLD.id_client;

    UPDATE AVIS
    SET id_client = NULL
    WHERE id_client = OLD.id_client;
END$$

-- Trigger 2 : verifier que la note est entre 1 et 5
CREATE TRIGGER TRG_VERIF_NOTE
BEFORE INSERT ON AVIS
FOR EACH ROW
BEGIN
    IF NEW.note_sur_5 < 1 OR NEW.note_sur_5 > 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : la note doit etre comprise entre 1 et 5.';
    END IF;
END$$

-- Trigger 3 : verifier qu'un avis est autorise
CREATE TRIGGER TRG_VERIF_AVIS
BEFORE INSERT ON AVIS
FOR EACH ROW
BEGIN
    IF NEW.id_client IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : un avis doit etre lie a un client.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM COMMANDE c
        JOIN LIGNE_COMMANDE lc ON lc.id_commande = c.id_commande
        WHERE c.id_client = NEW.id_client
          AND c.statut = 'livree'
          AND lc.id_produit = NEW.id_produit
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : avis refuse, client sans commande livree pour ce produit.';
    END IF;
END$$

DELIMITER ;


-- DONNEES DE TEST


-- 3 clients
INSERT INTO CLIENT (nom, prenom, email, telephone, date_inscription) VALUES
    ('Benali', 'Sara', 'sara.benali@email.com', '0600000001', '2026-01-10'),
    ('El Idrissi', 'Youssef', 'youssef.elidrissi@email.com', '0600000002', '2026-01-12'),
    ('Naciri', 'Lina', 'lina.naciri@email.com', '0600000003', '2026-01-15');

-- 3 commandes (2 livrees, 1 en_cours)
INSERT INTO COMMANDE (date_commande, statut, prix_total, id_client) VALUES
    ('2026-02-10', 'livree', 2499.00, 1),
    ('2026-02-15', 'en_cours', 1399.00, 2),
    ('2026-02-12', 'livree', 1399.00, 1);

-- lignes de commande
INSERT INTO LIGNE_COMMANDE (id_commande, id_produit, quantite, prix_unitaire_capture) VALUES
    (1, 1, 1, 2499.00),
    (2, 2, 1, 1399.00),
    (3, 2, 1, 1399.00);

-- 2 avis valides selon TRG_VERIF_AVIS
INSERT INTO AVIS (id_client, id_produit, note_sur_5, commentaire, date_avis) VALUES
    (1, 1, 5, 'Excellent PC, tres performant.', '2026-02-20');

INSERT INTO AVIS (id_client, id_produit, note_sur_5, commentaire, date_avis) VALUES
    (1, 2, 4, 'Tres bon produit, autonomie correcte.', '2026-02-22');


-- Partie Comptabilite

CREATE TABLE UTILISATEUR (
    id_utilisateur INT PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    mot_de_passe VARCHAR(255) NOT NULL
);
CREATE TABLE MEMBRE_COMPTABILITE (
    id_utilisateur INT PRIMARY KEY,
    matricule VARCHAR(50),
    niveau_acces VARCHAR(50),
    FOREIGN KEY (id_utilisateur) REFERENCES UTILISATEUR(id_utilisateur)
);
CREATE TABLE RAPPORT_FINANCIER (
    id_rapport INT PRIMARY KEY,
    annee INT UNIQUE,
    chiffre_affaires_annuel DECIMAL(15,2) DEFAULT 0
);
CREATE TABLE RAPPORT_MENSUEL (
    id_rapport INT,
    mois INT,
    chiffre_affaires_mensuel DECIMAL(15,2),
    PRIMARY KEY (id_rapport, mois),
    FOREIGN KEY (id_rapport) REFERENCES RAPPORT_FINANCIER(id_rapport)
);

CREATE VIEW VUE_CA_ANNUEL AS
SELECT 
    YEAR(c.date_commande) AS annee,
    SUM(l.quantite * l.prix_unitaire_capture) AS chiffre_affaires
FROM COMMANDE c
JOIN LIGNE_COMMANDE l ON c.idCommande = l.idCommande
WHERE c.statut = 'livree'
GROUP BY YEAR(c.date_commande);

CREATE VIEW VUE_CA_MENSUEL AS
SELECT 
    YEAR(c.date_commande) AS annee,
    MONTH(c.date_commande) AS mois,
    SUM(l.quantite * l.prix_unitaire_capture) AS chiffre_affaires
FROM COMMANDE c
JOIN LIGNE_COMMANDE l ON c.idCommande = l.idCommande
WHERE c.statut = 'livree'
GROUP BY YEAR(c.date_commande), MONTH(c.date_commande);

CREATE ROLE role_comptabilite;
CREATE ROLE role_client;
CREATE ROLE role_admin;
-- Comptabilité → uniquement vues
GRANT SELECT ON VUE_CA_ANNUEL TO role_comptabilite;
GRANT SELECT ON VUE_CA_MENSUEL TO role_comptabilite;
-- Client
GRANT SELECT ON PRODUIT TO role_client;
GRANT INSERT ON COMMANDE TO role_client;
-- Admin
GRANT ALL PRIVILEGES ON *.* TO role_admin WITH GRANT OPTION;

DELIMITER //
CREATE TRIGGER TRG_MAJ_RAPPORT_FINANCIER
AFTER UPDATE ON COMMANDE
FOR EACH ROW
BEGIN
    DECLARE total DECIMAL(10,2);
    IF NEW.statut = 'livree' AND OLD.statut <> 'livree' THEN
        SELECT SUM(quantite * prix_unitaire_capture)
        INTO total
        FROM LIGNE_COMMANDE
        WHERE idCommande = NEW.idCommande;
        -- annuel
        INSERT INTO RAPPORT_FINANCIER (annee, chiffre_affaires_annuel)
        VALUES (YEAR(NEW.date_commande), total)
        ON DUPLICATE KEY UPDATE
        chiffre_affaires_annuel = chiffre_affaires_annuel + total;
        -- mensuel
        INSERT INTO RAPPORT_MENSUEL (id_rapport, mois, chiffre_affaires_mensuel)
        SELECT id_rapport, MONTH(NEW.date_commande), total
        FROM RAPPORT_FINANCIER
        WHERE annee = YEAR(NEW.date_commande)
        ON DUPLICATE KEY UPDATE
        chiffre_affaires_mensuel = chiffre_affaires_mensuel + total;
    END IF;
END //
DELIMITER ;

CREATE INDEX idx_annee ON RAPPORT_FINANCIER(annee);
