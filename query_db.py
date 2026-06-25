import psycopg2

conn_str = "postgres://postgres.vqxblugxfhsiecyhvlgx:MarcoCouRoman1492@aws-1-us-east-1.pooler.supabase.com:5432/postgres"

try:
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()
    cur.execute("SELECT id, email, puntos_ecologicos FROM perfiles LIMIT 5;")
    rows = cur.fetchall()
    print("Perfiles in DB:")
    for row in rows:
        print(row)
    cur.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")
