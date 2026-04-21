"""
main.py — Menu principal & Login
INFOB212 — Bases de données — Phase 3
"""

from db import get_connection
from client import menu_client
from comptabilite import menu_comptabilite


# ─────────────────────────────────────────────
# Authentification
# ─────────────────────────────────────────────

def login():
    """
    Demande email + mot de passe, vérifie dans UTILISATEUR.
    Retourne (id_utilisateur, type_utilisateur) ou (None, None) si échec.
    """
    print("\n── Connexion ──")
    email = input("Email     : ").strip()
    mdp   = input("Mot de passe : ").strip()

    conn = get_connection()
    if conn is None:
        return None, None

    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            "SELECT idUtilisateur, typeUtilisateur "
            "FROM UTILISATEUR "
            "WHERE email = %s AND motDePasse = %s",
            (email, mdp)
        )
        user = cursor.fetchone()
        cursor.close()
        conn.close()

        if user:
            print(f"\n✔  Bienvenue ! (compte : {user['typeUtilisateur']})")
            return user["idUtilisateur"], user["typeUtilisateur"]
        else:
            print("\n✘  Identifiants incorrects.")
            return None, None

    except Exception as e:
        print(f"Erreur lors de l'authentification : {e}")
        conn.close()
        return None, None


# ─────────────────────────────────────────────
# Menu d'accueil
# ─────────────────────────────────────────────

def afficher_menu_accueil():
    print("\n" + "=" * 40)
    print("   INFOB212 — Boutique PC en ligne")
    print("=" * 40)
    print("  1. Espace Client")
    print("  2. Espace Comptabilité")
    print("  3. Quitter")
    print("=" * 40)


# ─────────────────────────────────────────────
# Boucle principale
# ─────────────────────────────────────────────

def main():
    while True:
        afficher_menu_accueil()
        choix = input("Votre choix : ").strip()

        # ── Option 1 : Espace Client ──────────────
        if choix == "1":
            print("\n── Espace Client ──")
            print("  a. Se connecter")
            print("  b. S'inscrire")
            sous_choix = input("Votre choix : ").strip().lower()

            if sous_choix == "a":
                id_user, type_user = login()
                if id_user is None:
                    continue
                if type_user != "client":
                    print("✘  Ce compte n'est pas un compte client.")
                    continue
                # Récupère l'idClient lié à l'utilisateur
                id_client = get_id_client(id_user)
                if id_client is None:
                    print("✘  Impossible de récupérer le profil client.")
                    continue
                menu_client(id_client, id_user)

            elif sous_choix == "b":
                # Inscription sans être connecté
                from client import inscrire_client
                inscrire_client()
            else:
                print("Option invalide.")

        # ── Option 2 : Espace Comptabilité ────────
        elif choix == "2":
            id_user, type_user = login()
            if id_user is None:
                continue
            if type_user != "comptabilite":
                print("✘  Ce compte n'est pas un compte comptabilité.")
                continue
            menu_comptabilite(id_user)

        # ── Option 3 : Quitter ────────────────────
        elif choix == "3":
            print("\nAu revoir !\n")
            break

        else:
            print("Choix invalide. Veuillez entrer 1, 2 ou 3.")


# ─────────────────────────────────────────────
# Utilitaire
# ─────────────────────────────────────────────

def get_id_client(id_utilisateur):
    """Retourne l'idClient correspondant à l'idUtilisateur."""
    conn = get_connection()
    if conn is None:
        return None
    try:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT idClient FROM CLIENT WHERE idUtilisateur = %s",
            (id_utilisateur,)
        )
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        return row[0] if row else None
    except Exception as e:
        print(f"Erreur get_id_client : {e}")
        conn.close()
        return None


if __name__ == "__main__":
    main()
