# BDD - Partie Ahmed
-- Schéma logique : CLIENT, COMMANDE, LIGNE_COMMANDE, AVIS
-- Prérequis : la table PRODUIT existe deja (avec id_produit)

CREATE TABLE CLIENT (
    idClient INT AUTO_INCREMENT,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    telephone VARCHAR(30),
    date_inscription DATE NOT NULL,
    CONSTRAINT PK_CLIENT PRIMARY KEY (idClient)
);

CREATE TABLE COMMANDE (
    idCommande INT AUTO_INCREMENT,
    dateCommande DATE NOT NULL,
    statut ENUM('en_cours', 'livree', 'annulee') NOT NULL,
    montant_total DECIMAL(10,2) NOT NULL,
    idClient INT NULL,
    CONSTRAINT PK_COMMANDE PRIMARY KEY (idCommande),
    CONSTRAINT FK_COMMANDE_CLIENT FOREIGN KEY (idClient)
        REFERENCES CLIENT(idClient)
);

CREATE TABLE LIGNE_COMMANDE (
    idLigneCommande INT AUTO_INCREMENT,
    idCommande INT NOT NULL,
    id_produit INT NOT NULL,
    quantite INT NOT NULL,
    prix_unitaire DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_LIGNE_COMMANDE PRIMARY KEY (idLigneCommande),
    CONSTRAINT FK_LIGNE_COMMANDE_COMMANDE FOREIGN KEY (idCommande)
        REFERENCES COMMANDE(idCommande),
    CONSTRAINT FK_LIGNE_COMMANDE_PRODUIT FOREIGN KEY (id_produit)
        REFERENCES PRODUIT(id_produit),
    CONSTRAINT CHK_LIGNE_QTE CHECK (quantite > 0),
    CONSTRAINT CHK_LIGNE_PRIX CHECK (prix_unitaire > 0)
);

CREATE TABLE AVIS (
    idAvis INT AUTO_INCREMENT,
    idClient INT NULL,
    id_produit INT NOT NULL,
    note INT NOT NULL,
    commentaire TEXT,
    date_avis DATE NOT NULL,
    CONSTRAINT PK_AVIS PRIMARY KEY (idAvis),
    CONSTRAINT FK_AVIS_CLIENT FOREIGN KEY (idClient)
        REFERENCES CLIENT(idClient),
    CONSTRAINT FK_AVIS_PRODUIT FOREIGN KEY (id_produit)
        REFERENCES PRODUIT(id_produit)
);


-- INDEX


CREATE INDEX idx_avis_produit
ON AVIS(id_produit);

CREATE INDEX idx_commande_client
ON COMMANDE(idClient);

CREATE INDEX idx_commande_date
ON COMMANDE(dateCommande);


-- TRIGGERS


DELIMITER $$

-- Trigger 1 : RGPD, avant suppression d'un client
-- on anonymise les references dans COMMANDE et AVIS
CREATE TRIGGER TRG_RGPD_DESINSCRIPTION
BEFORE DELETE ON CLIENT
FOR EACH ROW
BEGIN
    UPDATE COMMANDE
    SET idClient = NULL
    WHERE idClient = OLD.idClient;

    UPDATE AVIS
    SET idClient = NULL
    WHERE idClient = OLD.idClient;
END$$

-- Trigger 2 : verifier que la note est entre 1 et 5
CREATE TRIGGER TRG_VERIF_NOTE
BEFORE INSERT ON AVIS
FOR EACH ROW
BEGIN
    IF NEW.note < 1 OR NEW.note > 5 THEN
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
    IF NEW.idClient IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : un avis doit etre lie a un client.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM COMMANDE c
        JOIN LIGNE_COMMANDE lc ON lc.idCommande = c.idCommande
        WHERE c.idClient = NEW.idClient
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

-- 2 commandes (1 livree, 1 en_cours)
INSERT INTO COMMANDE (dateCommande, statut, montant_total, idClient) VALUES
    ('2026-02-10', 'livree', 2499.00, 1),
    ('2026-02-15', 'en_cours', 1399.00, 2);

-- lignes de commande
-- on suppose que les produits id 1 et 2 existent deja
INSERT INTO LIGNE_COMMANDE (idCommande, id_produit, quantite, prix_unitaire) VALUES
    (1, 1, 1, 2499.00),
    (2, 2, 1, 1399.00);

-- 2 avis (valides selon TRG_VERIF_AVIS)
-- client 1 a une commande livree pour le produit 1
INSERT INTO AVIS (idClient, id_produit, note, commentaire, date_avis) VALUES
    (1, 1, 5, 'Excellent PC, tres performant.', '2026-02-20');

-- deuxieme avis sur le meme produit pour rester coherent avec les commandes existantes
INSERT INTO AVIS (idClient, id_produit, note, commentaire, date_avis) VALUES
    (1, 1, 4, 'Tres bon produit, autonomie correcte.', '2026-02-22');
