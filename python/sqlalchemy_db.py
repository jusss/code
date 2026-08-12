from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.dialects.postgresql import UUID
import os
from urllib.parse import quote_plus

# dev env
host = ''
database_name = ''
user = ''
password = quote_plus('')

# product env
if os.getenv('ENV') != 'dev':
    host=''
    database_name=''
    user =''
    password=quote_plus('')

engine = create_engine(f'postgresql+psycopg2://{user}:{password}@{host}/{database_name}')
Session = sessionmaker(bind=engine)

# in other file
# from sqlalchemy_db import Session
# with Session() as db:
    # db.query()
