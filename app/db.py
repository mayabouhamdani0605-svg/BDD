import mysql.connector
from mysql.connector import Error

def get_connection():
    try:
        conn = mysql.connector.connect(
            host="127.0.0.1",
            port=3306,
            database="boutique_pc",
            user="root",
            password="rootpassword"
        )
        return conn
    except Error as e:
        print(f"Erreur de connexion à la base de données : {e}")
        return None
