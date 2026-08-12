from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.dialects.postgresql import UUID
import os
from urllib.parse import quote_plus
from contextlib import contextmanager
from sqlalchemy.pool import NullPool


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

# No idle connections
# engine = create_engine(f'postgresql+psycopg2://{user}:{password}@{host}/{database_name}',
           # pool_pre_ping=True,  # Check connection before using
           # poolclass=NullPool,  # No connection pooling, every request will start a new connection, connection overhead on each requests
        # )

engine = create_engine(f'postgresql+psycopg2://{user}:{password}@{host}/{database_name}',
           pool_pre_ping=True,  # Check connection before using
           pool_size=10,
           max_overflow=20,
           pool_recycle=3600,    # Recycle connections after 1 hour
           pool_timeout=30,  # Add timeout for getting connections
        )

Session = sessionmaker(bind=engine,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False
    )

@contextmanager
def get_session():
    session = Session()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


# in other file
# from sqlalchemy_db import get_session
# with get_session() as db:
    # db.query()
