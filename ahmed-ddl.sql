# BDD - Partie Ahmed
-- Schéma logique : CLIENT, COMMANDE, LIGNE_COMMANDE, AVIS
-- Prérequis : la table PRODUIT existe deja (avec id_produit comme PK)

CREATE TABLE CLIENT (
    id_client INT AUTO_INCREMENT,
    -- id_utilisateur sera lie a UTILISATEUR (table de Yahya) dans le fichier final
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
    note_sur_5 INT NOT NULL CHECK (note >= 1 AND note <= 5),
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


-- Index pour optimiser les recherches
CREATE INDEX idx_avis_produit
ON AVIS(id_produit);

CREATE INDEX idx_avis_client
ON AVIS(id_client);

CREATE INDEX idx_commande_client
ON COMMANDE(id_client);

CREATE INDEX idx_commande_date
ON COMMANDE(date_commande);

CREATE INDEX idx_commande_statut
ON COMMANDE(statut);


-- TRIGGERS


DELIMITER $$

-- Trigger 1 : RGPD, avant suppression d'un client
-- on anonymise les references dans COMMANDE et AVIS
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
-- le client doit avoir une commande livree contenant ce produit
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

-- Trigger 4 : Mettre a jour prix_total de la commande apres insertion de ligne
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

-- Note : l'unicite client/produit est deja garantie par UK_AVIS_CLIENT_PRODUIT
-- Pas besoin d'un trigger supplementaire pour ca

DELIMITER ;


-- VUES COMPLEXES

-- Vue 1 : Clients fidelite avec statistiques completes
CREATE VIEW VUE_CLIENTS_FIDELITE AS
SELECT 
    c.id_client,
    c.nom,
    c.prenom,
    c.email,
    COUNT(DISTINCT cmd.id_commande) AS nb_commandes,
    COUNT(DISTINCT a.id_avis) AS nb_avis_rediges,
    SUM(cmd.prix_total) AS prix_total_depense,
    AVG(a.note) AS note_moyenne_donnee,
    CASE 
        WHEN SUM(cmd.prix_total) IS NULL OR SUM(cmd.prix_total) < 500 THEN 'Standard'
        WHEN SUM(cmd.prix_total) < 2000 THEN 'Premium'
        ELSE 'VIP'
    END AS statut_fidelite,
    DATE(c.date_inscription) AS date_inscription
FROM CLIENT c
LEFT JOIN COMMANDE cmd ON c.id_client = cmd.id_client AND cmd.statut = 'livree'
LEFT JOIN AVIS a ON c.id_client = a.id_client
GROUP BY c.id_client, c.nom, c.prenom, c.email, c.date_inscription;

-- Vue 2 : Produits avec statistiques et avis
CREATE VIEW VUE_PRODUITS_STATS AS
SELECT 
    p.id_produit,
    p.ref_produit,
    p.nom_commercial,
    p.marque,
    p.prix_vente,
    COUNT(DISTINCT lc.id_commande) AS nb_ventes,
    SUM(lc.quantite) AS quantite_totale_vendue,
    COUNT(DISTINCT a.id_avis) AS nb_avis,
    ROUND(AVG(a.note), 2) AS note_moyenne,
    CASE 
        WHEN COUNT(DISTINCT a.id_avis) = 0 THEN 'Non evalue'
        WHEN AVG(a.note) >= 4.5 THEN 'Excellent'
        WHEN AVG(a.note) >= 4 THEN 'Tres bien'
        WHEN AVG(a.note) >= 3 THEN 'Bien'
        ELSE 'A ameliorer'
    END AS qualite_produit
FROM PRODUIT p
LEFT JOIN LIGNE_COMMANDE lc ON p.id_produit = lc.id_produit
LEFT JOIN AVIS a ON p.id_produit = a.id_produit
GROUP BY p.id_produit, p.ref_produit, p.nom_commercial, p.marque, p.prix_vente;


-- DONNEES DE TEST


-- 3 clients
INSERT INTO CLIENT (nom, prenom, email, telephone, date_inscription) VALUES
    ('Benali', 'Sara', 'sara.benali@email.com', '0600000001', '2026-01-10'),
    ('El Idrissi', 'Youssef', 'youssef.elidrissi@email.com', '0600000002', '2026-01-12'),
    ('Naciri', 'Lina', 'lina.naciri@email.com', '0600000003', '2026-01-15');

-- 3 commandes (2 livrees, 1 en_cours)
INSERT INTO COMMANDE (date_commande, statut, prix_total, id_client) VALUES
    ('2026-02-10', 'livree', 2499.00, 1),   -- client 1 achete produit 1
    ('2026-02-15', 'en_cours', 1399.00, 2), -- client 2 en cours produit 2
    ('2026-02-12', 'livree', 1399.00, 1);   -- client 1 achete aussi produit 2

-- lignes de commande
INSERT INTO LIGNE_COMMANDE (id_commande, id_produit, quantite, prix_unitaire_capture) VALUES
    (1, 1, 1, 2499.00),
    (2, 2, 1, 1399.00),
    (3, 2, 1, 1399.00); -- client 1 a bien achete produit 2 dans commande 3 (livree)

-- 2 avis valides selon TRG_VERIF_AVIS
-- client 1 a commande 1 (livree) pour produit 1
INSERT INTO AVIS (id_client, id_produit, note, commentaire, date_avis) VALUES
    (1, 1, 5, 'Excellent PC, tres performant.', '2026-02-20');

-- client 1 a commande 3 (livree) pour produit 2 → avis autorise
INSERT INTO AVIS (id_client, id_produit, note, commentaire, date_avis) VALUES
    (1, 2, 4, 'Tres bon produit, autonomie correcte.', '2026-02-22');
