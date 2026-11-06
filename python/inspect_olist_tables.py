import os
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

# Load credentials
project_folder = Path(__file__).resolve().parent.parent
load_dotenv(project_folder / ".env")

schema = os.getenv("DB_SCHEMA", "s_atikesanli")

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

query = text("""
    SELECT
        c.table_name,
        c.column_name,
        c.data_type,
        COALESCE(s.n_live_tup, 0) AS estimated_rows
    FROM information_schema.columns c
    LEFT JOIN pg_stat_user_tables s
        ON s.schemaname = c.table_schema
        AND s.relname = c.table_name
    WHERE c.table_schema = :schema
      AND c.table_name LIKE 'olist_%'
    ORDER BY c.table_name, c.ordinal_position;
""")

try:
    with engine.connect() as connection:
        results = connection.execute(
            query, {"schema": schema}
        ).fetchall()

        current_table = None

        for row in results:
            if row.table_name != current_table:
                current_table = row.table_name
                print(f"\n{'=' * 55}")
                print(f"TABLE: {current_table}")
                print(f"Estimated rows: {row.estimated_rows:,}")
                print("-" * 55)

            print(f"{row.column_name:<45} {row.data_type}")

except Exception as error:
    print("Error:", type(error).__name__, str(error))

finally:
    engine.dispose()