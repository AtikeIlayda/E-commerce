import os
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

# Load .env from the main project folder
project_folder = Path(__file__).resolve().parent.parent
load_dotenv(project_folder / ".env")

connection_url = URL.create(
    "postgresql+psycopg",
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST"),
    port=int(os.getenv("DB_PORT", "5432")),
    database=os.getenv("DB_NAME"),
)

engine = create_engine(
    connection_url,
    connect_args={"options": "-c default_transaction_read_only=on"}
)

schema = os.getenv("DB_SCHEMA", "s_atikesanli")

query = text("""
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = :schema
      AND table_type = 'BASE TABLE'
    ORDER BY table_name;
""")

try:
    with engine.connect() as connection:
        tables = connection.execute(
            query, {"schema": schema}
        ).fetchall()

        print(f"\nTables in schema: {schema}")
        print("-" * 45)

        if tables:
            for table in tables:
                print(table[0])
            print(f"\nTotal tables found: {len(tables)}")
        else:
            print("No tables found. Check the schema name or permissions.")

except Exception as error:
    print("Error:", type(error).__name__, str(error))

finally:
    engine.dispose()