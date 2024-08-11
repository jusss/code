from sqlalchemy import create_engine, text
from sqlalchemy import Column, Integer, String, Text, Boolean, Float, DateTime, PrimaryKeyConstraint, Index
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.dialects.postgresql import UUID
from app import App
import pandas as pd

Base = declarative_base()

username = ""
password = ""
host = "localhost"
port = 5432
database_name = ""

engine = create_engine(f'postgresql+psycopg2://{username}:{password}@{host}:{port}/{database_name}')
Session = sessionmaker(bind=engine)
session = Session()

data = session.query(App)
df = pd.read_sql_query(data.statement, engine.connect())

# sort
df = df.sort_values(by='created_at', ascending=False)

# filter, use & for multiple conditions
filters = (
    df['status'] == 1
        )

df = df[filters]

# ten lines
df = df.head(10)

pd.set_option('display.max_colwidth', 22)  # Set maximum column width
pd.set_option('display.max_rows', None)
pd.set_option('display.max_columns', None)
pd.set_option('display.width', 1000)
pd.set_option('display.colheader_justify', 'left')  # Left-align column headers
pd.set_option('display.column_space', 6)  # Set column space

# print(df.to_string(justify='left'))

print(df)
session.close()

# save to excel file
postfix = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
df.to_excel(f"~/Downloads/sql-{postfix}.xlsx", index=True)


