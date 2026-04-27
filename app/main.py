"""
main.py — Menu principal
INFOB212 — Bases de données — Phase 3
Groupe 6 : Hiba Khadiri, Maya Bouhamdani, Yahya Lahniti, Ahmed Feki
"""

from db import get_connection
from client import (
    inscrire_client,
    connexion_client,
    afficher_profil,
    modifier_client,
    desinscrire_client
)
from commande import menu_commandes
from avis import deposer_avis, consulter_mes_avis, supprimer_avis
from produit import afficher_catalogue
from comptabilite import menu_comptabilite


# ─────────────────────────────────────────────
# Connexion comptable
# ─────────────────────────────────────────────

def connexion_comptable():
    print("\n=== CONNEXION COMPTABILITE ===")
    email = input("Email : ").strip()
    mot_de_passe = input("Mot de passe : ").strip()

    conn = get_connection()
    if not conn:
        return None

    cursor = conn.cursor()
    try:
        cursor.execute("""
            SELECT u.id_utilisateur
            FROM UTILISATEUR u
            JOIN MEMBRE_COMPTABILITE mc ON u.id_utilisateur = mc.id_utilisateur
            WHERE u.email = %s AND u.mot_de_passe = %s
        """, (email, mot_de_passe))
        result = cursor.fetchone()
        if result:
            print("Connexion reussie")
            return result[0]
        else:
            print("Email ou mot de passe incorrect, ou compte non autorise")
            return None
    except Exception as e:
        print("Erreur : " + str(e))
        return None
    finally:
        cursor.close()
        conn.close()


# ─────────────────────────────────────────────
# Menu client
# ─────────────────────────────────────────────

def menu_client(id_client):
    # Récupérer l'adresse de livraison du client
    conn = get_connection()
    adresse = ""
    if conn:
        cursor = conn.cursor()
        try:
            cursor.execute(
                "SELECT adresse_livraison FROM CLIENT WHERE id_client = %s",
                (id_client,)
            )
            result = cursor.fetchone()
            if result:
                adresse = result[0]
        except Exception:
            pass
        finally:
            cursor.close()
            conn.close()

    while True:
        print("\n" + "=" * 40)
        print("   ESPACE CLIENT")
        print("=" * 40)
        print("  1. Voir mon profil")
        print("  2. Modifier mes informations")
        print("  3. Catalogue et commandes")
        print("  4. Mes avis")
        print("  5. Me desinscrire")
        print("  0. Deconnexion")
        print("=" * 40)

        choix = input("Votre choix : ").strip()

        if choix == "1":
            afficher_profil(id_client)

        elif choix == "2":
            modifier_client(id_client)

        elif choix == "3":
            menu_commandes(id_client, adresse)

        elif choix == "4":
            menu_avis(id_client)

        elif choix == "5":
            desinscrire_client(id_client)
            print("Vous avez ete desinscrit. Au revoir !")
            break

        elif choix == "0":
            print("Deconnexion...")
            break

        else:
            print("Choix invalide.")


# ─────────────────────────────────────────────
# Menu avis
# ─────────────────────────────────────────────

def menu_avis(id_client):
    while True:
        print("\n── Menu Avis ──")
        print("  1. Deposer un avis")
        print("  2. Consulter mes avis")
        print("  3. Supprimer un avis")
        print("  0. Retour")

        choix = input("Votre choix : ").strip()

        if choix == "1":
            deposer_avis(id_client)
        elif choix == "2":
            consulter_mes_avis(id_client)
        elif choix == "3":
            supprimer_avis(id_client)
        elif choix == "0":
            break
        else:
            print("Choix invalide.")


# ─────────────────────────────────────────────
# Menu principal
# ─────────────────────────────────────────────

def main():
    while True:
        print("\n" + "=" * 40)
        print("   INFOB212 — Boutique PC en ligne")
        print("=" * 40)
        print("  1. Espace Client")
        print("  2. Espace Comptabilite")
        print("  3. Quitter")
        print("=" * 40)

        choix = input("Votre choix : ").strip()

        # ── Espace Client ──
        if choix == "1":
            print("\n── Espace Client ──")
            print("  a. Se connecter")
            print("  b. S'inscrire")
            print("  c. Voir le catalogue sans se connecter")
            sous_choix = input("Votre choix : ").strip().lower()

            if sous_choix == "a":
                id_client = connexion_client()
                if id_client:
                    menu_client(id_client)

            elif sous_choix == "b":
                inscrire_client()

            elif sous_choix == "c":
                afficher_catalogue()

            else:
                print("Option invalide.")

        # ── Espace Comptabilité ──
        elif choix == "2":
            id_utilisateur = connexion_comptable()
            if id_utilisateur:
                menu_comptabilite(id_utilisateur)

        # ── Quitter ──
        elif choix == "3":
            print("\nAu revoir !\n")
            break

        else:
            print("Choix invalide. Veuillez entrer 1, 2 ou 3.")


if __name__ == "__main__":
    main()
