import psycopg2

conn_str = "postgres://postgres.vqxblugxfhsiecyhvlgx:MarcoCouRoman1492@aws-1-us-east-1.pooler.supabase.com:5432/postgres"

try:
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM transacciones_puntos;")
    count = cur.fetchone()[0]
    print(f"Total transacciones in DB: {count}")
    cur.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")
