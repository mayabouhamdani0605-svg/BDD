-- BDD - Partie hiba
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

CREATE INDEX idx_produit_categorie 
ON PRODUIT(id_categorie);

DELIMITER $$
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

INSERT INTO CATEGORIE (nom_categorie) VALUES 
('PC Portable Windows'), 
('Apple MacBook'), 
('PC Portable Gamer'), 
('Google Chrome OS');
