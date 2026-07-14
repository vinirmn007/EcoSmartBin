import os
import sys
from dotenv import load_dotenv
from supabase import create_client, Client
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
from settings import settings

# Load environment variables
load_dotenv()

SUPABASE_URL = settings.SUPABASE_URL
SUPABASE_KEY = settings.SUPABASE_KEY
DATABASE_URL = settings.DATABASE_URL

if not all([SUPABASE_URL, SUPABASE_KEY, DATABASE_URL]):
    print("Error: Missing SUPABASE_URL, SUPABASE_KEY, or DATABASE_URL in .env")
    sys.exit(1)

def make_admin(email: str):
    print(f"Buscando usuario con email: {email}")
    
    # Connect to PostgreSQL directly
    engine = create_engine(DATABASE_URL)
    Session = sessionmaker(bind=engine)
    session = Session()

    try:
        # 1. Update the 'perfiles' table
        result = session.execute(
            text("UPDATE perfiles SET role = 'admin' WHERE email = :email RETURNING id"),
            {"email": email}
        )
        user = result.fetchone()
        
        if not user:
            print(f"❌ Error: No se encontró ningún usuario con el correo {email} en la tabla 'perfiles'.")
            session.rollback()
            return
            
        user_id = user[0]
        session.commit()
        print(f"✅ Tabla 'perfiles' actualizada. Usuario ID: {user_id}")

        # 2. Update the 'auth.users' table directly to set raw_user_meta_data->>'role' = 'admin'
        # This is required so the next time the user logs in, the JWT token contains the 'admin' role.
        session.execute(
            text("""
                UPDATE auth.users 
                SET raw_user_meta_data = jsonb_set(
                    COALESCE(raw_user_meta_data, '{}'::jsonb), 
                    '{role}', 
                    '"admin"'
                ) 
                WHERE id = :uid
            """),
            {"uid": user_id}
        )
        session.commit()
        print(f"✅ Tabla 'auth.users' actualizada. El próximo token JWT contendrá el rol 'admin'.")
        
        print(f"\n🎉 ¡Éxito! El usuario {email} ahora es Administrador.")
        print("NOTA: El usuario debe cerrar sesión y volver a iniciarla para que el nuevo rol se aplique.")
        
    except Exception as e:
        session.rollback()
        print(f"❌ Ocurrió un error al actualizar la base de datos: {e}")
    finally:
        session.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python make_admin.py <correo_del_usuario>")
        sys.exit(1)
        
    target_email = sys.argv[1]
    make_admin(target_email)
