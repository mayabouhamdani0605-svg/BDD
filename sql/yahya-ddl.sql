-- BDD - Partie Yahya

-- Création de la table UTILISATAEUR
CREATE TABLE UTILISATEUR (
    id_utilisateur INT  PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    mot_de_passe VARCHAR(255) NOT NULL
);

--Création de la table MEMBRE_COMPTABILITE 
CREATE TABLE MEMBRE_COMPTABILITE (
    id_utilisateur INT PRIMARY KEY,
    matricule VARCHAR(50),
    niveau_acces VARCHAR(50),
    FOREIGN KEY (id_utilisateur) REFERENCES UTILISATEUR(id_utilisateur)
);

--Création de la table RAPPORT_FINANCIER 
CREATE TABLE RAPPORT_FINANCIER (
    id_rapport INT  PRIMARY KEY,
    annee INT UNIQUE,
    chiffre_affaires_annuel DECIMAL(15,2) DEFAULT 0
);

--Création de la table RAPPORT_MENSUEL
CREATE TABLE RAPPORT_MENSUEL (
    id_rapport INT,
    mois INT,
    chiffre_affaires_mensuel DECIMAL(15,2),
    PRIMARY KEY (id_rapport, mois),
    FOREIGN KEY (id_rapport) REFERENCES RAPPORT_FINANCIER(id_rapport)
);


-- Création de la view VUE_CA_ANNUE qui affiche le chiffre d'affaire annuel
CREATE VIEW VUE_CA_ANNUEL AS
SELECT 
    YEAR(c.date_commande) AS annee,
    SUM(l.quantite * l.prix_unitaire_capture) AS chiffre_affaires
FROM COMMANDE c
JOIN LIGNE_COMMANDE l ON c.id_commande = l.id_commande
WHERE c.statut = 'LIVREE'
GROUP BY YEAR(c.date_commande);

-- Création de la view VUE_CA_ANNUE qui affiche le chiffre d'affaire mensuel
CREATE VIEW VUE_CA_MENSUEL AS
SELECT 
    YEAR(c.date_commande) AS annee,
    MONTH(c.date_commande) AS mois,
    SUM(l.quantite * l.prix_unitaire_capture) AS chiffre_affaires
FROM COMMANDE c
JOIN LIGNE_COMMANDE l ON c.id_commande = l.id_commande
WHERE c.statut = 'LIVREE'
GROUP BY YEAR(c.date_commande), MONTH(c.date_commande);

--Creation des roles
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
ALTER ROLE db_owner ADD MEMBER role_admin;

--Trigger : mettre a jour le chiffre d’affaires dans RAPPORT_FINANCIER et RAPPORT_MENSUE
CREATE TRIGGER TRG_MAJ_RAPPORT_FINANCIER
AFTER UPDATE ON COMMANDE
FOR EACH ROW
BEGIN
    IF NEW.statut = 'LIVREE' AND OLD.statut <> 'LIVREE' THEN

        DECLARE total DECIMAL(10,2);

        SELECT SUM(quantite * prix_unitaire_capture)
        INTO total
        FROM LIGNE_COMMANDE
        WHERE id_commande = NEW.id_commande;

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

CREATE INDEX idx_annee ON RAPPORT_FINANCIER(annee);
