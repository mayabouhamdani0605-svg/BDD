"""
comptabilite.py — Espace Comptabilité
INFOB212 — Bases de données — Phase 3
"""

from db import get_connection


MOIS_FR = {
    1: "Janvier",   2: "Fevrier",    3: "Mars",
    4: "Avril",     5: "Mai",        6: "Juin",
    7: "Juillet",   8: "Aout",       9: "Septembre",
    10: "Octobre",  11: "Novembre",  12: "Decembre"
}

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
        cursor.execute(
            "SELECT chiffreAffaires FROM VUE_CA_ANNUEL WHERE annee = %s",
            (annee,)
        )
        row_annuel = cursor.fetchone()
        ca_annuel = row_annuel[0] if row_annuel else 0.0
        cursor.close()
        conn.close()

        print("\n" + "=" * 45)
        print(f"     Rapport annuel — {annee}")
        print("=" * 45)
        if ca_annuel:
            print(f"  CA Annuel : {ca_annuel:>12,.2f} EUR")
        else:
            print("  Aucune donnee disponible pour cette annee.")
        print("=" * 45)
        

    except Exception as e:
        print(f"Erreur lors de la génération du rapport : {e}")
        conn.close()

# ─────────────────────────────────────────────
# Rapport mensuel (tableau mois par mois)
# ─────────────────────────────────────────────

def rapport_mensuel():
    annee_saisie = input("\nEntrez l'annee (ex : 2026) : ").strip()
    if not annee_saisie.isdigit() or len(annee_saisie) != 4:
        print("Annee invalide. Veuillez saisir une annee sur 4 chiffres.")
        return
 
    annee = int(annee_saisie)
    conn = get_connection()
    if conn is None:
        return
 
    try:
        cursor = conn.cursor()
 
        # CA mensuel
        cursor.execute(
            "SELECT mois, chiffreAffaires "
            "FROM VUE_CA_MENSUEL "
            "WHERE annee = %s "
            "ORDER BY mois ASC",
            (annee,)
        )
        lignes = cursor.fetchall()
 
        # CA annuel total pour le pied de tableau
        cursor.execute(
            "SELECT chiffreAffaires FROM VUE_CA_ANNUEL WHERE annee = %s",
            (annee,)
        )
        row_annuel = cursor.fetchone()
        ca_annuel  = row_annuel[0] if row_annuel else 0.0
 
        cursor.close()
        conn.close()
 
        # ── Construction du tableau ───────────────
        COL_M = 14   # largeur colonne Mois
        COL_C = 16   # largeur colonne CA
 
        sep  = "+" + "-" * COL_M + "+" + "-" * COL_C + "+"
        sep2 = "+" + "=" * COL_M + "+" + "=" * COL_C + "+"
        total_inner = COL_M + COL_C + 1   # largeur intérieure totale
 
        print("\n" + sep2)
        titre = f" Rapport mensuel — {annee} "
        print("|" + titre.center(total_inner) + "|")
        print(sep2)
        print(f"| {'Mois':<{COL_M - 2}} | {'CA (EUR)':>{COL_C - 2}} |")
        print(sep2)
 
        if lignes:
            ca_par_mois = {m: ca for m, ca in lignes}
 
            for num in range(1, 13):
                nom    = MOIS_FR[num]
                ca     = ca_par_mois.get(num)
                valeur = f"{ca:,.2f}" if ca is not None else "—"
                print(f"| {nom:<{COL_M - 2}} | {valeur:>{COL_C - 2}} |")
                print(sep)
 
            # Ligne TOTAL
            print(sep2)
            print(f"| {'TOTAL':<{COL_M - 2}} | {f'{ca_annuel:,.2f}':>{COL_C - 2}} |")
            print(sep2)
 
        else:
            print(f"| {'Aucune donnee disponible':<{total_inner}} |")
            print(sep)
 
    except Exception as e:
        print(f"Erreur rapport mensuel : {e}")
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
