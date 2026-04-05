
-- ============================================================
-- BOUTIQUE PC EN LIGNE - Base de données complète et corrigée
-- Groupe : Hiba Khadiri, Maya Bouhamdani, Yahya Lahniti, Ahmed Feki
-- ============================================================

-- ============================================================
-- PARTIE MAYA : Composants techniques
-- ============================================================

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
    CONSTRAINT PK_MEMOIRE_RAM PRIMARY KEY (id_ram)
);

CREATE TABLE CARTE_GRAPHIQUE (
    id_gpu INT AUTO_INCREMENT,
    modele VARCHAR(100) NOT NULL,
    CONSTRAINT PK_CARTE_GRAPHIQUE PRIMARY KEY (id_gpu)
);

CREATE TABLE ECRAN (
    id_ecran INT AUTO_INCREMENT,
    diagonale_pouces DECIMAL(4,1) NOT NULL,
    CONSTRAINT PK_ECRAN PRIMARY KEY (id_ecran)
);

-- Index composants
CREATE INDEX idx_processeur_modele ON PROCESSEUR(modele);
CREATE INDEX idx_processeur_vitesse ON PROCESSEUR(vitesse_ghz);
CREATE INDEX idx_ram_capacite ON MEMOIRE_RAM(capacite_gb);
CREATE INDEX idx_carte_graphique_modele ON CARTE_GRAPHIQUE(modele);
CREATE INDEX idx_ecran_diagonale ON ECRAN(diagonale_pouces);

-- Triggers composants
DELIMITER $$

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
        SET MESSAGE_TEXT = 'Erreur : le nombre de coeurs doit etre superieur a 0.';
    END IF;
END$$

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
        SET MESSAGE_TEXT = 'Erreur : le nombre de coeurs doit etre superieur a 0.';
    END IF;
END$$

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

-- Données de test composants
INSERT INTO PROCESSEUR (modele, vitesse_ghz, nb_coeurs) VALUES
    ('Intel Core i5-1235U', 1.30, 10),
    ('Intel Core i7-1355U', 1.70, 10),
    ('Intel Core Ultra 7',  2.20, 16),
    ('AMD Ryzen 7 7730U',   2.00,  8),
    ('AMD Ryzen 5 7530U',   2.00,  6),
    ('Apple M3',            3.70,  8),
    ('Apple M3 Pro',        3.70, 11);

INSERT INTO MEMOIRE_RAM (capacite_gb) VALUES
    (8), (16), (32), (64);

INSERT INTO CARTE_GRAPHIQUE (modele) VALUES
    ('Intel Iris Xe Graphics'),
    ('AMD Radeon Graphics'),
    ('NVIDIA GeForce RTX 4060'),
    ('NVIDIA GeForce RTX 4070'),
    ('Apple M3 GPU');

INSERT INTO ECRAN (diagonale_pouces) VALUES
    (13.3), (14.0), (15.6), (16.0), (17.3);


-- ============================================================
-- PARTIE HIBA : Catégorie et Produit
-- ============================================================

CREATE TABLE CATEGORIE (
    id_categorie INT AUTO_INCREMENT PRIMARY KEY,
    nom_categorie VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE PRODUIT (
    id_produit INT AUTO_INCREMENT PRIMARY KEY,
    ref_produit VARCHAR(50) UNIQUE,
    nom_commercial VARCHAR(150) NOT NULL,
    marque VARCHAR(50) NOT NULL,
    prix_vente DECIMAL(10,2) NOT NULL,
    etat ENUM('nouveau', 'reconditionne') NOT NULL,
    disponibilite ENUM('en_stock', 'bientot_disponible') NOT NULL,
    stock_quantite INT NOT NULL,
    systeme_exploitation VARCHAR(50),
    poids_kg DECIMAL(4,2),
    image VARCHAR(255),
    description TEXT,
    id_categorie INT NOT NULL,
    id_processeur INT NOT NULL,
    id_ram INT NOT NULL,
    id_gpu INT NOT NULL,
    id_ecran INT NOT NULL,
    CONSTRAINT fk_produit_categorie FOREIGN KEY (id_categorie) REFERENCES CATEGORIE(id_categorie),
    CONSTRAINT fk_proc FOREIGN KEY (id_processeur) REFERENCES PROCESSEUR(id_processeur),
    CONSTRAINT fk_ram FOREIGN KEY (id_ram) REFERENCES MEMOIRE_RAM(id_ram),
    CONSTRAINT fk_gpu FOREIGN KEY (id_gpu) REFERENCES CARTE_GRAPHIQUE(id_gpu),
    CONSTRAINT fk_ecran FOREIGN KEY (id_ecran) REFERENCES ECRAN(id_ecran)
);

CREATE INDEX idx_produit_categorie ON PRODUIT(id_categorie);
CREATE INDEX idx_produit_marque ON PRODUIT(marque);
CREATE INDEX idx_produit_prix ON PRODUIT(prix_vente);

-- Triggers produit
DELIMITER $$

CREATE TRIGGER tr_check_stock_update
BEFORE UPDATE ON PRODUIT
FOR EACH ROW
BEGIN
    IF NEW.stock_quantite < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Operation annulee : Stock insuffisant pour ce produit.';
    END IF;
    IF NEW.stock_quantite = 0 THEN
        SET NEW.disponibilite = 'bientot_disponible';
    END IF;
END$$

CREATE TRIGGER TRG_VERIF_PRIX_INSERT
BEFORE INSERT ON PRODUIT
FOR EACH ROW
BEGIN
    IF NEW.prix_vente <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : Le prix de vente doit etre strictement superieur a 0.';
    END IF;
END$$

CREATE TRIGGER TRG_VERIF_PRIX_UPDATE
BEFORE UPDATE ON PRODUIT
FOR EACH ROW
BEGIN
    IF NEW.prix_vente <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : Le prix de vente ne peut pas etre modifie par une valeur negative ou nulle.';
    END IF;
END$$

DELIMITER ;

-- Vues produit
CREATE VIEW VUE_COMPOSANTS_PRODUIT AS
SELECT
    p.id_produit,
    p.nom_commercial    AS nom_produit,
    p.marque,
    p.prix_vente,
    p.etat,
    p.disponibilite,
    p.stock_quantite,
    pr.modele           AS processeur,
    pr.vitesse_ghz,
    pr.nb_coeurs,
    r.capacite_gb       AS ram_gb,
    cg.modele           AS carte_graphique,
    e.diagonale_pouces  AS ecran_pouces,
    c.nom_categorie     AS categorie
FROM PRODUIT p
JOIN PROCESSEUR pr      ON p.id_processeur = pr.id_processeur
JOIN MEMOIRE_RAM r      ON p.id_ram        = r.id_ram
JOIN CARTE_GRAPHIQUE cg ON p.id_gpu        = cg.id_gpu
JOIN ECRAN e            ON p.id_ecran      = e.id_ecran
JOIN CATEGORIE c        ON p.id_categorie  = c.id_categorie;

CREATE VIEW VUE_PRODUITS_PAR_PRIX AS
SELECT
    p.id_produit,
    p.nom_commercial    AS nom_produit,
    p.marque,
    p.prix_vente,
    p.etat,
    pr.modele           AS processeur,
    pr.vitesse_ghz,
    pr.nb_coeurs,
    r.capacite_gb       AS ram_gb,
    cg.modele           AS carte_graphique,
    e.diagonale_pouces  AS ecran_pouces
FROM PRODUIT p
JOIN PROCESSEUR pr      ON p.id_processeur = pr.id_processeur
JOIN MEMOIRE_RAM r      ON p.id_ram        = r.id_ram
JOIN CARTE_GRAPHIQUE cg ON p.id_gpu        = cg.id_gpu
JOIN ECRAN e            ON p.id_ecran      = e.id_ecran
WHERE p.disponibilite = 'en_stock'
ORDER BY p.prix_vente ASC;

CREATE VIEW VUE_STOCK_FAIBLE AS
SELECT
    p.id_produit,
    p.nom_commercial,
    p.marque,
    p.stock_quantite,
    p.disponibilite
FROM PRODUIT p
WHERE p.stock_quantite < 5;

-- Données de test catégories et produits
INSERT INTO CATEGORIE (nom_categorie) VALUES
    ('PC Portable Windows'),
    ('Apple MacBook'),
    ('PC Portable Gamer'),
    ('Google Chrome OS');

INSERT INTO PRODUIT (ref_produit, nom_commercial, marque, prix_vente, etat, disponibilite, stock_quantite, systeme_exploitation, poids_kg, description, id_categorie, id_processeur, id_ram, id_gpu, id_ecran) VALUES
    ('LAP-001', 'Dell XPS 15',         'Dell',  2499.00, 'nouveau',      'en_stock', 10, 'Windows 11', 1.86, 'Laptop haut de gamme',      1, 2, 2, 3, 3),
    ('LAP-002', 'HP Pavilion 14',       'HP',    1399.00, 'nouveau',      'en_stock', 15, 'Windows 11', 1.41, 'Laptop milieu de gamme',    1, 1, 1, 1, 2),
    ('LAP-003', 'Apple MacBook Air M3', 'Apple', 1599.00, 'nouveau',      'en_stock',  8, 'macOS',      1.24, 'MacBook ultra fin',          2, 6, 2, 5, 1),
    ('LAP-004', 'MSI Raider GE78',      'MSI',   3299.00, 'nouveau',      'en_stock',  5, 'Windows 11', 2.60, 'PC Gamer haute performance', 3, 3, 3, 4, 5),
    ('LAP-005', 'ASUS VivoBook 15',     'ASUS',   799.00, 'reconditionne','en_stock', 20, 'Windows 11', 1.70, 'PC portable abordable',     1, 5, 1, 2, 3);


-- ============================================================
-- PARTIE AHMED : Client, Commande, Ligne_Commande, Avis
-- ============================================================

CREATE TABLE UTILISATEUR (
    id_utilisateur INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    mot_de_passe VARCHAR(255) NOT NULL
);

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
    CONSTRAINT PK_CLIENT PRIMARY KEY (id_client),
    CONSTRAINT FK_CLIENT_UTILISATEUR FOREIGN KEY (id_utilisateur)
        REFERENCES UTILISATEUR(id_utilisateur) ON DELETE SET NULL
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

-- Index
CREATE INDEX idx_avis_produit ON AVIS(id_produit);
CREATE INDEX idx_avis_client ON AVIS(id_client);
CREATE INDEX idx_commande_client ON COMMANDE(id_client);
CREATE INDEX idx_commande_date ON COMMANDE(date_commande);
CREATE INDEX idx_commande_statut ON COMMANDE(statut);

-- Triggers
DELIMITER $$

CREATE TRIGGER TRG_RGPD_DESINSCRIPTION
BEFORE DELETE ON CLIENT
FOR EACH ROW
BEGIN
    UPDATE COMMANDE SET id_client = NULL WHERE id_client = OLD.id_client;
    UPDATE AVIS SET id_client = NULL WHERE id_client = OLD.id_client;
END$$

CREATE TRIGGER TRG_VERIF_NOTE
BEFORE INSERT ON AVIS
FOR EACH ROW
BEGIN
    IF NEW.note_sur_5 < 1 OR NEW.note_sur_5 > 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : la note doit etre comprise entre 1 et 5.';
    END IF;
END$$

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

CREATE TRIGGER TRG_MAJ_MONTANT_COMMANDE_INSERT
AFTER INSERT ON LIGNE_COMMANDE
FOR EACH ROW
BEGIN
    UPDATE COMMANDE
    SET prix_total = (
        SELECT SUM(quantite * prix_unitaire_capture)
        FROM LIGNE_COMMANDE
        WHERE id_commande = NEW.id_commande
    )
    WHERE id_commande = NEW.id_commande;
END$$

DELIMITER ;

-- Vues
CREATE VIEW VUE_CLIENTS_FIDELITE AS
SELECT
    c.id_client,
    c.nom,
    c.prenom,
    c.email,
    COUNT(DISTINCT cmd.id_commande) AS nb_commandes,
    COUNT(DISTINCT a.id_avis)       AS nb_avis_rediges,
    SUM(cmd.prix_total)             AS total_depense,
    ROUND(AVG(a.note_sur_5), 2)     AS note_moyenne_donnee,
    CASE
        WHEN SUM(cmd.prix_total) IS NULL OR SUM(cmd.prix_total) < 500 THEN 'Standard'
        WHEN SUM(cmd.prix_total) < 2000 THEN 'Premium'
        ELSE 'VIP'
    END AS statut_fidelite,
    c.date_inscription
FROM CLIENT c
LEFT JOIN COMMANDE cmd ON c.id_client = cmd.id_client AND cmd.statut = 'livree'
LEFT JOIN AVIS a ON c.id_client = a.id_client
GROUP BY c.id_client, c.nom, c.prenom, c.email, c.date_inscription;

CREATE VIEW VUE_PRODUITS_STATS AS
SELECT
    p.id_produit,
    p.ref_produit,
    p.nom_commercial,
    p.marque,
    p.prix_vente,
    COUNT(DISTINCT lc.id_commande)  AS nb_ventes,
    SUM(lc.quantite)                AS quantite_totale_vendue,
    COUNT(DISTINCT a.id_avis)       AS nb_avis,
    ROUND(AVG(a.note_sur_5), 2)     AS note_moyenne,
    CASE
        WHEN COUNT(DISTINCT a.id_avis) = 0 THEN 'Non evalue'
        WHEN AVG(a.note_sur_5) >= 4.5 THEN 'Excellent'
        WHEN AVG(a.note_sur_5) >= 4   THEN 'Tres bien'
        WHEN AVG(a.note_sur_5) >= 3   THEN 'Bien'
        ELSE 'A ameliorer'
    END AS qualite_produit
FROM PRODUIT p
LEFT JOIN LIGNE_COMMANDE lc ON p.id_produit = lc.id_produit
LEFT JOIN AVIS a ON p.id_produit = a.id_produit
GROUP BY p.id_produit, p.ref_produit, p.nom_commercial, p.marque, p.prix_vente;

-- Données de test
INSERT INTO UTILISATEUR (email, mot_de_passe) VALUES
    ('sara.benali@email.com',          'pass123'),
    ('youssef.elidrissi@email.com',    'pass456'),
    ('lina.naciri@email.com',          'pass789');

INSERT INTO CLIENT (id_utilisateur, nom, prenom, email, telephone, adresse_livraison, date_inscription) VALUES
    (1, 'Benali',     'Sara',    'sara.benali@email.com',       '0600000001', '12 rue des Lilas, Bruxelles', '2026-01-10'),
    (2, 'El Idrissi', 'Youssef', 'youssef.elidrissi@email.com', '0600000002', '5 avenue du Parc, Liege',     '2026-01-12'),
    (3, 'Naciri',     'Lina',    'lina.naciri@email.com',       '0600000003', '8 rue de la Gare, Namur',     '2026-01-15');

INSERT INTO COMMANDE (date_commande, statut, prix_total, adresse_livraison, id_client) VALUES
    ('2026-02-10', 'livree',   2499.00, '12 rue des Lilas, Bruxelles', 1),
    ('2026-02-15', 'en_cours', 1399.00, '5 avenue du Parc, Liege',     2),
    ('2026-02-12', 'livree',   1399.00, '12 rue des Lilas, Bruxelles', 1);

INSERT INTO LIGNE_COMMANDE (id_commande, id_produit, quantite, prix_unitaire_capture) VALUES
    (1, 1, 1, 2499.00),
    (2, 2, 1, 1399.00),
    (3, 2, 1, 1399.00);

INSERT INTO AVIS (id_client, id_produit, note_sur_5, commentaire, date_avis) VALUES
    (1, 1, 5, 'Excellent PC, tres performant.',      '2026-02-20'),
    (1, 2, 4, 'Tres bon produit, autonomie correcte.', '2026-02-22');


-- ============================================================
-- PARTIE YAHYA : Comptabilité
-- ============================================================

CREATE TABLE MEMBRE_COMPTABILITE (
    id_utilisateur INT PRIMARY KEY,
    matricule VARCHAR(50),
    niveau_acces VARCHAR(50),
    FOREIGN KEY (id_utilisateur) REFERENCES UTILISATEUR(id_utilisateur)
);

CREATE TABLE RAPPORT_FINANCIER (
    id_rapport INT AUTO_INCREMENT PRIMARY KEY,
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

CREATE INDEX idx_annee ON RAPPORT_FINANCIER(annee);

-- Vues comptabilité
CREATE VIEW VUE_CA_ANNUEL AS
SELECT
    YEAR(c.date_commande) AS annee,
    SUM(l.quantite * l.prix_unitaire_capture) AS chiffre_affaires
FROM COMMANDE c
JOIN LIGNE_COMMANDE l ON c.id_commande = l.id_commande
WHERE c.statut = 'livree'
GROUP BY YEAR(c.date_commande);

CREATE VIEW VUE_CA_MENSUEL AS
SELECT
    YEAR(c.date_commande)  AS annee,
    MONTH(c.date_commande) AS mois,
    SUM(l.quantite * l.prix_unitaire_capture) AS chiffre_affaires
FROM COMMANDE c
JOIN LIGNE_COMMANDE l ON c.id_commande = l.id_commande
WHERE c.statut = 'livree'
GROUP BY YEAR(c.date_commande), MONTH(c.date_commande);

-- Trigger comptabilité
DELIMITER $$

CREATE TRIGGER TRG_MAJ_RAPPORT_FINANCIER
AFTER UPDATE ON COMMANDE
FOR EACH ROW
BEGIN
    DECLARE total DECIMAL(10,2);
    IF NEW.statut = 'livree' AND OLD.statut <> 'livree' THEN
        SELECT SUM(quantite * prix_unitaire_capture)
        INTO total
        FROM LIGNE_COMMANDE
        WHERE id_commande = NEW.id_commande;

        INSERT INTO RAPPORT_FINANCIER (annee, chiffre_affaires_annuel)
        VALUES (YEAR(NEW.date_commande), total)
        ON DUPLICATE KEY UPDATE
        chiffre_affaires_annuel = chiffre_affaires_annuel + total;

        INSERT INTO RAPPORT_MENSUEL (id_rapport, mois, chiffre_affaires_mensuel)
        SELECT id_rapport, MONTH(NEW.date_commande), total
        FROM RAPPORT_FINANCIER
        WHERE annee = YEAR(NEW.date_commande)
        ON DUPLICATE KEY UPDATE
        chiffre_affaires_mensuel = chiffre_affaires_mensuel + total;
    END IF;
END$$

DELIMITER ;

-- Permissions
CREATE ROLE role_comptabilite;
CREATE ROLE role_client;
CREATE ROLE role_admin;

GRANT SELECT ON VUE_CA_ANNUEL TO role_comptabilite;
GRANT SELECT ON VUE_CA_MENSUEL TO role_comptabilite;
GRANT SELECT ON PRODUIT TO role_client;
GRANT INSERT ON COMMANDE TO role_client;
GRANT ALL PRIVILEGES ON *.* TO role_admin WITH GRANT OPTION;

-- Données de test comptabilité
INSERT INTO UTILISATEUR (email, mot_de_passe) VALUES
    ('comptable1@boutique.com', 'compta123'),
    ('comptable2@boutique.com', 'compta456');

INSERT INTO MEMBRE_COMPTABILITE (id_utilisateur, matricule, niveau_acces) VALUES
    (4, 'COMPTA-001', 'lecture'),
    (5, 'COMPTA-002', 'lecture');

INSERT INTO RAPPORT_FINANCIER (annee, chiffre_affaires_annuel) VALUES
    (2026, 3898.00);

INSERT INTO RAPPORT_MENSUEL (id_rapport, mois, chiffre_affaires_mensuel) VALUES
    (1, 1, 1499.00),
    (1, 2, 2399.00);
