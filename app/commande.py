# Responsable : Hiba Khadiri

import mysql.connector
from datetime import date
from db import get_connection

# --- Afficher les produits disponibles ---
def afficher_catalogue():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT id_produit, nom_commercial, prix_vente, stock_quantite
        FROM PRODUIT
        WHERE disponibilite = 'en_stock'
    """)
    produits = cursor.fetchall()

    print("\n--- CATALOGUE ---")
    for p in produits:
        print(f"ID: {p[0]} | {p[1]} | {p[2]}€ | Stock: {p[3]}")

    cursor.close()
    conn.close()


# --- Afficher le panier ---
def afficher_panier(panier):
    print("\n--- VOTRE PANIER ---")
    if not panier:
        print("Le panier est vide.")
        return
    total = 0
    for item in panier:
        sous_total = item["prix"] * item["quantite"]
        total += sous_total
        print(f"{item['nom']} x{item['quantite']} = {sous_total:.2f}€")
    print(f"TOTAL : {total:.2f}€")


# --- Ajouter un produit au panier ---
def ajouter_au_panier(panier):
    afficher_catalogue()

    id_produit = int(input("\nID du produit à ajouter : "))
    quantite = int(input("Quantité : "))

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT nom_commercial, prix_vente, stock_quantite
        FROM PRODUIT WHERE id_produit = %s
    """, (id_produit,))
    produit = cursor.fetchone()

    if not produit:
        print("Produit introuvable.")
    elif quantite > produit[2]:
        print(f"Stock insuffisant. Disponible : {produit[2]}")
    else:
        panier.append({
            "id_produit": id_produit,
            "nom": produit[0],
            "prix": float(produit[1]),
            "quantite": quantite
        })
        print(f"'{produit[0]}' ajouté au panier !")

    cursor.close()
    conn.close()


# --- Valider la commande ---
def valider_commande(panier, id_client, adresse_livraison):
    if not panier:
        print("Le panier est vide.")
        return

    conn = get_connection()
    cursor = conn.cursor()

    try:
        # Créer la commande
        cursor.execute("""
            INSERT INTO COMMANDE (date_commande, statut, prix_total, adresse_livraison, id_client)
            VALUES (%s, 'en_cours', 0, %s, %s)
        """, (date.today(), adresse_livraison, id_client))

        id_commande = cursor.lastrowid

        # Ajouter chaque produit dans LIGNE_COMMANDE
        for item in panier:
            cursor.execute("""
                INSERT INTO LIGNE_COMMANDE (id_commande, id_produit, quantite, prix_unitaire_capture)
                VALUES (%s, %s, %s, %s)
            """, (id_commande, item["id_produit"], item["quantite"], item["prix"]))

            # Mettre à jour le stock
            cursor.execute("""
                UPDATE PRODUIT SET stock_quantite = stock_quantite - %s
                WHERE id_produit = %s
            """, (item["quantite"], item["id_produit"]))

        conn.commit()
        print(f"\nCommande #{id_commande} validée avec succès !")
        panier.clear()

    except mysql.connector.Error as e:
        conn.rollback()
        print(f"Erreur : {e.msg}")

    finally:
        cursor.close()
        conn.close()


# --- Historique des commandes ---
def afficher_historique(id_client):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT id_commande, date_commande, statut, prix_total
        FROM COMMANDE
        WHERE id_client = %s
        ORDER BY date_commande DESC
    """, (id_client,))
    commandes = cursor.fetchall()

    print("\n--- HISTORIQUE DE VOS COMMANDES ---")
    if not commandes:
        print("Aucune commande trouvée.")
        return

    for cmd in commandes:
        id_cmd, date_cmd, statut, total = cmd
        print(f"\nCommande #{id_cmd} | {date_cmd} | {statut} | {total:.2f}€")

        # Détail des produits de cette commande
        cursor.execute("""
            SELECT p.nom_commercial, lc.quantite, lc.prix_unitaire_capture
            FROM LIGNE_COMMANDE lc
            JOIN PRODUIT p ON lc.id_produit = p.id_produit
            WHERE lc.id_commande = %s
        """, (id_cmd,))
        for ligne in cursor.fetchall():
            print(f"   - {ligne[0]} x{ligne[1]} à {ligne[2]:.2f}€")

    cursor.close()
    conn.close()


# --- Menu principal ---
def menu_commandes(id_client, adresse_livraison):
    panier = []

    while True:
        print("\n--- MENU COMMANDES ---")
        print("1. Voir le catalogue")
        print("2. Ajouter au panier")
        print("3. Voir mon panier")
        print("4. Valider ma commande")
        print("5. Voir mon historique")
        print("0. Quitter")

        choix = input("Votre choix : ")

        if choix == "1":
            afficher_catalogue()
        elif choix == "2":
            ajouter_au_panier(panier)
        elif choix == "3":
            afficher_panier(panier)
        elif choix == "4":
            valider_commande(panier, id_client, adresse_livraison)
        elif choix == "5":
            afficher_historique(id_client)
        elif choix == "0":
            break
        else:
            print("Choix invalide.")
