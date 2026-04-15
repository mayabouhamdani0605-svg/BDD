import mysql.connector
from db import get_connection


def get_all_products():
    """Sert a renvoyer tous les produits en stock"""
    conn = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        
        query = """
            SELECT *
            FROM VUE_COMPOSANTS_PRODUIT
            WHERE disponibilite = 'en_stock'
            ORDER BY prix_vente ASC
        """
        cursor.execute(query)
        return cursor.fetchall()
    
    except mysql.connector.Error as err:
        print(f"Erreur MySQL (get_all_products) : {err}")
        return []
    finally:
        if conn and conn.is_connected():
            conn.close()


def filtrer_products(prix_max=None, ram_min=None, marque=None, processeur=None):
    """Filtre les produits disponible en stock selon les critères choisis . """
    conn = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        
        query = """
            SELECT *
            FROM VUE_COMPOSANTS_PRODUIT
            WHERE disponibilite = 'en_stock'
        """
        params = []
        
        if prix_max is not None:
            query += " AND prix_vente <= %s"
            params.append(prix_max)
            
        if ram_min is not None:
            query += " AND ram_gb >= %s"
            params.append(ram_min)
            
        if marque:
            query += " AND marque = %s"
            params.append(marque)
            
        if processeur:
            query += " AND processeur LIKE %s"
            params.append(f"%{processeur}%")
        
        query += " ORDER BY prix_vente ASC"
        
        cursor.execute(query, params)
        return cursor.fetchall()

    except mysql.connector.Error as err:
        print(f"Erreur MySQL (filtrer_products) : {err}")
        return []
    finally:
        if conn and conn.is_connected():
            conn.close()


def get_product_by_id(id_produit):
    """Récupère tous les details d'un produit  ."""
    conn = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        query = """
            SELECT *
            FROM VUE_COMPOSANTS_PRODUIT
            WHERE id_produit = %s
        """
        cursor.execute(query, (id_produit,))
        result = cursor.fetchone()
        return result if result else None

    except mysql.connector.Error as err:
        print(f"Erreur MySQL (get_product_by_id) : {err}")
        return None
    finally:
        if conn and conn.is_connected():
            conn.close()


def afficher_produit_console(produit):
    """Affichage d'un produit"""
    print(f"{produit['nom_produit']}")
    print(f"   Marque          : {produit['marque']}")
    print(f"   Prix            : {produit['prix_vente']:.2f} €")
    print(f"   État            : {produit['etat']}")
    print(f"   Processeur      : {produit['processeur']} ({produit['vitesse_ghz']} GHz, {produit['nb_coeurs']} coeurs)")
    print(f"   RAM             : {produit['ram_gb']} Go")
    print(f"   Carte graphique : {produit['carte_graphique']}")
    print(f"   Écran           : {produit['ecran_pouces']} pouces")
    print(f"   Stock           : {produit['stock_quantite']} unité(s)")
    print("-" * 60)


def afficher_catalogue():
    """Affiche tout le catalogue en stock."""
    produits = get_all_products()
    if not produits:
        print("Aucun produit disponible en stock pour le moment.")
        return

    print("\nCATALOGUE DES PRODUITS EN STOCK\n")
    for p in produits:
        afficher_produit_console(p)
