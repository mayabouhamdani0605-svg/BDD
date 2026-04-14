from db import get_connection

# ajoutez la condition pour l'adresse mail @ 
def inscrire_client():
    print("\n=== INSCRIPTION ===")
    nom = input("Nom : ")
    prenom = input("Prénom : ")
    email = input("Email : ")
    telephone = input("Téléphone : ")
    adresse = input("Adresse de livraison : ")
    mot_de_passe = input("Mot de passe : ")

    conn = get_connection()
    if not conn:
        return

    cursor = conn.cursor()

    try:
        # Vérifier si l'email existe déjà
        cursor.execute("SELECT id_client FROM CLIENT WHERE email = %s", (email,))
        if cursor.fetchone():
            print("Cet email est déjà utilisé !")
            return

        # Insérer dans UTILISATEUR
        cursor.execute("INSERT INTO UTILISATEUR (email, mot_de_passe) VALUES (%s, %s)", (email, mot_de_passe))
        id_utilisateur = cursor.lastrowid

        # Insérer dans CLIENT
        cursor.execute("INSERT INTO CLIENT (id_utilisateur, nom, prenom, email, telephone, adresse_livraison, date_inscription) VALUES (%s, %s, %s, %s, %s, %s, CURDATE())", (id_utilisateur, nom, prenom, email, telephone, adresse))

        conn.commit()
        print(f" Inscription réussie ! Bienvenue {prenom} {nom} !")

    except Exception as e:
        conn.rollback()
        print(f" Erreur lors de l'inscription : {e}")

    finally:
        cursor.close()
        conn.close()


def modifier_client(id_client):
    print("\n=== MODIFIER MES INFORMATIONS ===")

    conn = get_connection()
    if not conn:
        return

    cursor = conn.cursor()

    try:
        # Afficher les infos actuelles
        cursor.execute("SELECT nom, prenom, email, telephone, adresse_livraison FROM CLIENT WHERE id_client = %s", (id_client,))
        client = cursor.fetchone()

        if not client:
            print(" Client introuvable.")
            return

        print(f"\nInfos actuelles :")
        print(f"  Nom        : {client[0]}")
        print(f"  Prénom     : {client[1]}")
        print(f"  Email      : {client[2]}")
        print(f"  Téléphone  : {client[3]}")
        print(f"  Adresse    : {client[4]}")
        print("\n(Laissez vide pour ne pas modifier)")

        nom = input(f"Nouveau nom [{client[0]}] : ") or client[0]
        prenom = input(f"Nouveau prénom [{client[1]}] : ") or client[1]
        telephone = input(f"Nouveau téléphone [{client[3]}] : ") or client[3]
        adresse = input(f"Nouvelle adresse [{client[4]}] : ") or client[4]

        cursor.execute("UPDATE CLIENT SET nom = %s, prenom = %s, telephone = %s, adresse_livraison = %s WHERE id_client = %s", (nom, prenom, telephone, adresse, id_client))

        conn.commit()
        print(" Informations mises à jour avec succès !")

    except Exception as e:
        conn.rollback()
        print(f"Erreur : {e}")

    finally:
        cursor.close()
        conn.close()


def desinscrire_client(id_client):
    print("\n=== DÉSINSCRIPTION ===")
    print("  Cette action est irréversible !")
    confirmation = input("Êtes-vous sûr de vouloir vous désinscrire ? (oui/non) : ")

    if confirmation.lower() != "oui":
        print("Désinscription annulée.")
        return

    conn = get_connection()
    if not conn:
        return

    cursor = conn.cursor()

    try:
        # Récupérer id_utilisateur
        cursor.execute("SELECT id_utilisateur FROM CLIENT WHERE id_client = %s", (id_client,))
        result = cursor.fetchone()
        if not result:
            print(" Client introuvable.")
            return
        id_utilisateur = result[0]

        # Supprimer le client (le trigger TRG_RGPD_DESINSCRIPTION s'occupe du reste)
        cursor.execute("DELETE FROM CLIENT WHERE id_client = %s", (id_client,))

        # Supprimer aussi de UTILISATEUR
        if id_utilisateur:
            cursor.execute("DELETE FROM UTILISATEUR WHERE id_utilisateur = %s", (id_utilisateur,))

        conn.commit()
        print(" Désinscription effectuée. Vos données personnelles ont été supprimées.")
        print("   Votre historique de commandes est conservé de manière anonyme (RGPD).")

    except Exception as e:
        conn.rollback()
        print(f" Erreur lors de la désinscription : {e}")

    finally:
        cursor.close()
        conn.close()
