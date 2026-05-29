# INFOB212 — Projet Base de Données

## Boutique de vente d’ordinateurs portables

---

# 1. Description du projet

Ce projet a été réalisé dans le cadre du cours **INFOB212**.

L’objectif est de développer une application de gestion d’une boutique de vente d’ordinateurs portables avec :

* une base de données MySQL ;
* une application Python en ligne de commande ;
* des règles métier implémentées via triggers, vues et contraintes SQL ;
* une gestion des rôles utilisateurs ;
* une gestion RGPD des données clients.

---

# 2. Technologies utilisées

## Base de données

* MySQL 8
* Docker
* Docker Compose

## Application

* Python 3
* mysql-connector-python

---

# 3. Structure du projet

```text
projet_bdd/
│
├── db_docker/
│   ├── docker-compose.yml
│   └── init.sql
│
├── python/
│   ├── main.py
│   ├── db.py
│   ├── client.py
│   ├── commande.py
│   ├── produit.py
│   ├── avis.py
│   └── comptabilite.py
│
└── README.md
```

---

# 4. Fonctionnalités principales

## Espace Client

### Gestion du compte

* Inscription
* Connexion
* Modification du profil
* Désinscription RGPD

### Produits et commandes

* Consultation du catalogue
* Ajout au panier
* Suppression du panier
* Validation de commande
* Historique des commandes

### Avis

* Déposer un avis
* Supprimer un avis

---

## Espace Comptabilité

* Connexion réservée aux comptables
* Rapport annuel du chiffre d’affaires
* Rapport mensuel détaillé

---

# 5. Fonctionnalités SQL avancées

## Triggers

### TRG_RGPD_DESINSCRIPTION

Avant suppression d’un client :

* anonymise les commandes ;
* anonymise les avis ;
* conserve l’historique.

### TRG_VERIF_AVIS

Empêche un client de laisser un avis :

* sans commande livrée ;
* ou s’il a déjà noté le produit.

### TRG_MAJ_MONTANT_COMMANDE_INSERT

Met automatiquement à jour :

* le prix total d’une commande.

### TRG_MAJ_RAPPORT_FINANCIER

Met automatiquement à jour :

* les rapports financiers lorsqu’une commande devient livrée.

---

## Vues

### VUE_ALERTE_STOCK

Estime les risques de rupture de stock.

### VUE_CLIENTS_FIDELITE

Classe les clients :

* VIP
* Premium
* Standard

### VUE_PRODUITS_STATS

Affiche :

* nombre de ventes ;
* moyenne des avis ;
* statistiques produits.

---

# 6. Installation du projet

## Prérequis

Installer :

* Docker Desktop
* Python 3
* pip

---

# 7. Démarrage de la base de données

## Étape 1 — Lancer Docker Desktop

Attendre que :

```text
Engine running
```

apparaisse.

---

## Étape 2 — Aller dans le dossier Docker

```bash
cd C:\Users\VotreNom\Desktop\projet_bdd\projet_bdd\db_docker
```
on ecrit dans le cmd : docker compose up -d

lancer sql dans le meme terminal que docker compose up - d : docker exec -it projet-bdd-mysql-1 mysql -u root -prootpassword boutique_pc


## 8 - aller dans le dossier python

cd C:\Users\VotreNom\Desktop\projet_bdd\projet_bdd\python

executer cette ligne : python main.py 



# 10. Données de test

## Comptabilité

| Email                                                     | Mot de passe |
| --------------------------------------------------------- | ------------ |
| [comptable1@boutique.com](mailto:comptable1@boutique.com) | compta123    |

---

## Clients

| Email                                                 | Mot de passe |
| ----------------------------------------------------- | ------------ |
| [sara.benali@email.com](mailto:sara.benali@email.com) | pass123      |
| [maya@unamur.be](mailto:maya@unamur.be)               | maya1234     |

---

# 11. Tests réalisés

---

# Test 1 — Inscription

## Étapes

1. Créer un compte.
2. Vérifier dans MySQL :

```sql
SELECT * FROM UTILISATEUR;
SELECT * FROM CLIENT;
```

## Résultat attendu

* le client apparaît dans les deux tables.

---

# Test 2 — Connexion

## Cas valide

Connexion avec :

```text
sara.benali@email.com
pass123
```

## Cas invalide

Mot de passe incorrect → accès refusé.

---

# Test 3 — Modification du profil

## Vérification SQL

```sql
SELECT * FROM CLIENT;
```

Les nouvelles données doivent apparaître.

---

# Test 4 — Désinscription RGPD

## Étapes

1. Se désinscrire via l’application.
2. Vérifier :

```sql
SELECT * FROM CLIENT;
SELECT * FROM UTILISATEUR;
```

## Résultat attendu

* le client disparaît ;
* l’utilisateur disparaît.

## Vérification historique

```sql
SELECT * FROM COMMANDE WHERE id_client IS NULL;
```

Résultat attendu :

* commandes conservées ;
* client anonymisé.

---

# Test 5 — Commande

## Vérifier le stock avant

```sql
SELECT id_produit, nom_commercial, stock_quantite
FROM PRODUIT;
```

## Passer une commande

Exemple :

* Dell XPS 15
* quantité : 2

## Vérifier le stock après

Le stock doit diminuer automatiquement.

---

# Test 6 — Vérification commande enregistrée

```sql
SELECT * FROM COMMANDE;
```

Résultat attendu :

* nouvelle commande visible ;
* prix total correct.

---

# Test 7 — Rapport comptable

## Connexion comptabilité

```text
Email : comptable1@boutique.com
Mot de passe : compta123
```

## Rapport annuel

* année avec données → chiffre d’affaires affiché ;
* année vide → “Aucune donnée”.

## Rapport mensuel

* tableau des 12 mois affiché.

---

# Test 8 — Avis

## Cas refusé

Client sans commande livrée :

```text
Vous n'avez pas de commande livrée.
```

## Cas accepté

Client avec commande livrée :

* avis enregistré.

## Cas doublon

Même produit déjà noté :

```text
Erreur : Vous avez déjà noté ce produit.
```

---

# 12. Vérification manuelle MySQL

## Connexion au conteneur

```bash
docker exec -it projet-bdd-mysql-1 mysql -u root -prootpassword boutique_pc
```

---

## Commandes utiles

### Voir les utilisateurs

```sql
SELECT * FROM UTILISATEUR;
```

### Voir les clients

```sql
SELECT * FROM CLIENT;
```

### Voir les commandes

```sql
SELECT * FROM COMMANDE;
```

### Voir les avis

```sql
SELECT * FROM AVIS;
```

---

# 14. Conclusion

Le projet implémente :

* une architecture SQL complète ;
* des contraintes métier avancées ;
* des triggers et vues complexes ;
* une application Python fonctionnelle ;
* une gestion RGPD correcte ;
* une séparation des rôles utilisateurs.

Tous les tests principaux ont été validés avec succès.
