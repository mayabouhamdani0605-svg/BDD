from db import get_connection

def connexion_client():
    print("\n=== CONNEXION CLIENT ===")
    email = input("Email : ")
    mot_de_passe = input("Mot de passe : ")

    conn = get_connection()
    if not conn:
        return None

    cursor = conn.cursor()

    try:
        cursor.execute(
            "SELECT id_client FROM CLIENT WHERE email = %s AND email IN (SELECT email FROM UTILISATEUR WHERE mot_de_passe = %s)",
            (email, mot_de_passe)
        )
        result = cursor.fetchone()

        if result:
            id_client = result[0]
            print("Connexion reussie")
            return id_client
        else:
            print("Email ou mot de passe incorrect")
            return None

    except Exception as e:
        print("Erreur lors de la connexion : " + str(e))
        return None

    finally:
        cursor.close()
        conn.close()


def afficher_profil(id_client):
    print("\n=== MON PROFIL ===")

    conn = get_connection()
    if not conn:
        return

    cursor = conn.cursor()

    try:
        cursor.execute(
            "SELECT id_client, nom, prenom, email, telephone, adresse_livraison, date_inscription, statut_compte FROM CLIENT WHERE id_client = %s",
            (id_client,)
        )
        client = cursor.fetchone()

        if not client:
            print("Client introuvable")
            return

        print("ID Client : " + str(client[0]))
        print("Nom : " + client[1])
        print("Prenom : " + client[2])
        print("Email : " + client[3])
        print("Telephone : " + str(client[4]))
        print("Adresse : " + client[5])
        print("Date inscription : " + str(client[6]))
        print("Statut : " + client[7])

    except Exception as e:
        print("Erreur : " + str(e))

    finally:
        cursor.close()
        conn.close()


def inscrire_client():
    print("\n=== INSCRIPTION ===")
    nom = input("Nom : ")
    prenom = input("Prenom : ")
    email = input("Email : ")
    telephone = input("Telephone : ")
    adresse = input("Adresse de livraison : ")
    mot_de_passe = input("Mot de passe : ")

    conn = get_connection()
    if not conn:
        return

    cursor = conn.cursor()

    try:
        cursor.execute("SELECT id_client FROM CLIENT WHERE email = %s", (email,))
        if cursor.fetchone():
            print("Cet email est deja utilise")
            return

        cursor.execute("INSERT INTO UTILISATEUR (email, mot_de_passe) VALUES (%s, %s)", (email, mot_de_passe))
        id_utilisateur = cursor.lastrowid

        cursor.execute("INSERT INTO CLIENT (id_utilisateur, nom, prenom, email, telephone, adresse_livraison, date_inscription) VALUES (%s, %s, %s, %s, %s, %s, CURDATE())", (id_utilisateur, nom, prenom, email, telephone, adresse))

        conn.commit()
        print("Inscription reussie")

    except Exception as e:
        conn.rollback()
        print("Erreur lors de l'inscription : " + str(e))

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
        cursor.execute("SELECT nom, prenom, email, telephone, adresse_livraison FROM CLIENT WHERE id_client = %s", (id_client,))
        client = cursor.fetchone()

        if not client:
            print("Client introuvable")
            return

        print("Infos actuelles :")
        print("Nom : " + client[0])
        print("Prenom : " + client[1])
        print("Email : " + client[2])
        print("Telephone : " + str(client[3]))
        print("Adresse : " + client[4])

        nom = input("Nouveau nom [" + client[0] + "] : ") or client[0]
        prenom = input("Nouveau prenom [" + client[1] + "] : ") or client[1]
        telephone = input("Nouveau telephone [" + str(client[3]) + "] : ") or client[3]
        adresse = input("Nouvelle adresse [" + client[4] + "] : ") or client[4]

        cursor.execute("UPDATE CLIENT SET nom = %s, prenom = %s, telephone = %s, adresse_livraison = %s WHERE id_client = %s", (nom, prenom, telephone, adresse, id_client))

        conn.commit()
        print("Informations mises a jour")

    except Exception as e:
        conn.rollback()
        print("Erreur : " + str(e))

    finally:
        cursor.close()
        conn.close()


def desinscrire_client(id_client):
    print("\n=== DESINSCRIPTION ===")
    print("Attention : cette action est irreversible")
    confirmation = input("Etes-vous sur de vouloir vous desinscrire ? (oui/non) : ")

    if confirmation.lower() != "oui":
        print("Desinscription annulee")
        return

    conn = get_connection()
    if not conn:
        return

    cursor = conn.cursor()

    try:
        cursor.execute("SELECT id_utilisateur FROM CLIENT WHERE id_client = %s", (id_client,))
        result = cursor.fetchone()
        if not result:
            print("Client introuvable")
            return
        id_utilisateur = result[0]

        cursor.execute("DELETE FROM CLIENT WHERE id_client = %s", (id_client,))

        if id_utilisateur:
            cursor.execute("DELETE FROM UTILISATEUR WHERE id_utilisateur = %s", (id_utilisateur,))

        conn.commit()
        print("Desinscription effectuee. Vos donnees ont ete supprimees.")

    except Exception as e:
        conn.rollback()
        print("Erreur lors de la desinscription : " + str(e))

    finally:
        cursor.close()
        conn.close()
