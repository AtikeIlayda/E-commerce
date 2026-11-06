import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

# Load credentials from the project-level .env file
load_dotenv()

connection_url = URL.create(
    drivername="postgresql+psycopg",
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

try:
    with engine.connect() as connection:
        result = connection.execute(
            text("SELECT current_database(), current_user, version();")
        )
        database, user, version = result.fetchone()

        print("Connection successful!")
        print("Database:", database)
        print("User:", user)
        print("PostgreSQL version:", version.split(",")[0])

except Exception as error:
    print("Connection failed.")
    print(type(error).__name__, str(error))

finally:
    engine.dispose()