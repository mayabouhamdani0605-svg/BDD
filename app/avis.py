from db import get_connection
import mysql.connector


def deposer_avis(id_client):
    print("\n=== DEPOSER UN AVIS ===")

    conn = get_connection()
    if not conn:
        return

    cursor = conn.cursor()

    try:
        # Récupérer les produits que le client a commandés et reçus
        cursor.execute("""
            SELECT DISTINCT p.id_produit, p.nom_commercial, p.marque, p.prix_vente
            FROM PRODUIT p
            JOIN LIGNE_COMMANDE lc ON p.id_produit = lc.id_produit
            JOIN COMMANDE c ON lc.id_commande = c.id_commande
            WHERE c.id_client = %s AND c.statut = 'livree'
            ORDER BY p.nom_commercial
        """, (id_client,))

        produits = cursor.fetchall()

        if not produits:
            print("Vous n'avez pas de commande livree. Impossible de laisser un avis.")
            cursor.close()
            conn.close()
            return

        print("\nProduits que vous avez recus :")
        for i, produit in enumerate(produits, 1):
            print(str(i) + ". " + produit[1] + " (" + produit[2] + ") - " + str(produit[3]) + "EUR")

        try:
            choix = int(input("\nSelectionnez le numero du produit : "))
            if choix < 1 or choix > len(produits):
                print("Choix invalide")
                cursor.close()
                conn.close()
                return

            id_produit = produits[choix - 1][0]

        except ValueError:
            print("Veuillez entrer un nombre valide")
            cursor.close()
            conn.close()
            return

        # Saisir la note
        while True:
            try:
                note = int(input("\nNote (1-5) : "))
                if 1 <= note <= 5:
                    break
                else:
                    print("La note doit etre entre 1 et 5")
            except ValueError:
                print("Veuillez entrer un nombre")

        # Saisir le commentaire
        commentaire = input("Commentaire (optionnel) : ").strip() or None

        # Insérer l'avis
        try:
            cursor.execute("""
                INSERT INTO AVIS (id_client, id_produit, note_sur_5, commentaire, date_avis)
                VALUES (%s, %s, %s, %s, CURDATE())
            """, (id_client, id_produit, note, commentaire))

            conn.commit()
            print("\nAvis enregistre avec succes")

        except mysql.connector.Error as e:
            conn.rollback()
            # Gérer les erreurs des triggers
            if "TRG_VERIF_AVIS" in str(e) or "sans commande livree" in str(e):
                print("Erreur : Vous n'avez pas de commande livree pour ce produit")
            elif "Duplicate entry" in str(e) or "unique" in str(e).lower():
                print("Erreur : Vous avez deja note ce produit")
            else:
                print("Erreur : " + str(e))

    except Exception as e:
        print("Erreur : " + str(e))

    finally:
        cursor.close()
        conn.close()


def consulter_mes_avis(id_client):
    print("\n=== MES AVIS ===")

    conn = get_connection()
    if not conn:
        return

    cursor = conn.cursor()

    try:
        # Afficher tous les avis du client
        cursor.execute("""
            SELECT a.id_avis, p.nom_commercial, p.marque, a.note_sur_5, a.commentaire, a.date_avis
            FROM AVIS a
            JOIN PRODUIT p ON a.id_produit = p.id_produit
            WHERE a.id_client = %s
            ORDER BY a.date_avis DESC
        """, (id_client,))

        avis = cursor.fetchall()

        if not avis:
            print("Vous n'avez pas poste d'avis")
            cursor.close()
            conn.close()
            return

        print("\nVous avez " + str(len(avis)) + " avis(s) :\n")

        for avis_item in avis:
            id_avis, nom_prod, marque, note, commentaire, date = avis_item
            print("ID: " + str(id_avis))
            print("Produit: " + nom_prod + " (" + marque + ")")
            print("Note: " + str(note) + "/5")
            if commentaire:
                print("Commentaire: " + commentaire)
            print("Date: " + str(date))
            print()

    except Exception as e:
        print("Erreur : " + str(e))

    finally:
        cursor.close()
        conn.close()


def supprimer_avis(id_client):
    print("\n=== SUPPRIMER UN AVIS ===")

    conn = get_connection()
    if not conn:
        return

    cursor = conn.cursor()

    try:
        # Afficher les avis du client
        cursor.execute("""
            SELECT a.id_avis, p.nom_commercial, a.note_sur_5, a.date_avis
            FROM AVIS a
            JOIN PRODUIT p ON a.id_produit = p.id_produit
            WHERE a.id_client = %s
            ORDER BY a.date_avis DESC
        """, (id_client,))

        avis = cursor.fetchall()

        if not avis:
            print("Vous n'avez pas d'avis a supprimer")
            cursor.close()
            conn.close()
            return

        print("\nVos avis :\n")
        for i, avis_item in enumerate(avis, 1):
            id_avis, nom_prod, note, date = avis_item
            print(str(i) + ". " + nom_prod + " - Note: " + str(note) + "/5 (" + str(date) + ")")

        try:
            choix = int(input("\nSelectionnez le numero de l'avis a supprimer : "))
            if choix < 1 or choix > len(avis):
                print("Choix invalide")
                cursor.close()
                conn.close()
                return

            id_avis = avis[choix - 1][0]

            # Supprimer l'avis
            cursor.execute("DELETE FROM AVIS WHERE id_avis = %s AND id_client = %s", (id_avis, id_client))
            conn.commit()
            print("Avis supprime")

        except ValueError:
            print("Veuillez entrer un nombre valide")
        except Exception as e:
            conn.rollback()
            print("Erreur : " + str(e))

    finally:
        cursor.close()
        conn.close()
