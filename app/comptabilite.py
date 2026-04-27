"""
comptabilite.py — Espace Comptabilité
INFOB212 — Bases de données — Phase 3
"""

from db import get_connection


# ─────────────────────────────────────────────
# Vérification du droit d'accès
# ─────────────────────────────────────────────

def est_membre_comptabilite(id_utilisateur):
    conn = get_connection()
    if conn is None:
        return False
    try:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id_utilisateur FROM MEMBRE_COMPTABILITE "
            "WHERE id_utilisateur = %s",
            (id_utilisateur,)
        )
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        return row is not None
    except Exception as e:
        print(f"Erreur vérification comptabilité : {e}")
        conn.close()
        return False


# ─────────────────────────────────────────────
# Rapport annuel
# ─────────────────────────────────────────────

def rapport_annuel():
    annee_saisie = input("\nEntrez l'année du rapport (ex : 2026) : ").strip()

    if not annee_saisie.isdigit() or len(annee_saisie) != 4:
        print("Année invalide. Veuillez saisir une année sur 4 chiffres.")
        return

    annee = int(annee_saisie)

    conn = get_connection()
    if conn is None:
        return

    try:
        cursor = conn.cursor()

        # CA annuel
        cursor.execute(
            "SELECT chiffreAffaires FROM VUE_CA_ANNUEL WHERE annee = %s",
            (annee,)
        )
        row_annuel = cursor.fetchone()
        ca_annuel = row_annuel[0] if row_annuel else 0.0

        # CA mensuel
        cursor.execute(
            "SELECT mois, chiffreAffaires "
            "FROM VUE_CA_MENSUEL "
            "WHERE annee = %s "
            "ORDER BY mois ASC",
            (annee,)
        )
        lignes_mensuelles = cursor.fetchall()

        cursor.close()
        conn.close()

        # Affichage
        MOIS_FR = {
            1: "Janvier",   2: "Fevrier",   3: "Mars",
            4: "Avril",     5: "Mai",       6: "Juin",
            7: "Juillet",   8: "Aout",      9: "Septembre",
            10: "Octobre",  11: "Novembre", 12: "Decembre"
        }

        print("\n" + "=" * 45)
        print(f"   Rapport financier {annee}")
        print("=" * 45)
        print(f"  CA Annuel : {ca_annuel:,.2f} EUR")
        print("-" * 45)

        if lignes_mensuelles:
            for ligne in lignes_mensuelles:
                nom_mois = MOIS_FR.get(ligne[0], f"Mois {ligne[0]}")
                print(f"  {nom_mois:<12} : {ligne[1]:>10,.2f} EUR")
        else:
            print("  Aucune donnée disponible pour cette année.")

        print("=" * 45)

    except Exception as e:
        print(f"Erreur lors de la génération du rapport : {e}")
        conn.close()


# ─────────────────────────────────────────────
# Menu comptabilité
# ─────────────────────────────────────────────

def menu_comptabilite(id_utilisateur):
    if not est_membre_comptabilite(id_utilisateur):
        print("\nAccès refusé : vous n'êtes pas membre du service comptabilité.")
        return

    print("\nAccès autorisé — Espace Comptabilité")

    while True:
        print("\n── Menu Comptabilité ──")
        print("  1. Générer le rapport annuel des ventes")
        print("  2. Retour au menu principal")

        choix = input("Votre choix : ").strip()

        if choix == "1":
            rapport_annuel()
        elif choix == "2":
            break
        else:
            print("Choix invalide. Veuillez entrer 1 ou 2.")
