from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.dialects.postgresql import UUID
import os
from urllib.parse import quote_plus
from contextlib import contextmanager
from sqlalchemy.pool import NullPool
from sqlalchemy import create_engine


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


import concurrent.future
import asyncio

async def update_db(docs:list[str]):
    def blocking(doc):
        # this blocking function can not be async def, since loop.run_in_executor is for blocking func
        # and use executor for db blocking, this function has to be blocking function
        # asyncio.run(async_f()) in this blocking function for calling async function
        # if this is async func, that loop.run_in_executor(executor, lambda d=doc: asyncio.run(async_f(d)))

        with get_session() as db:
            db.query()
            db.commit()
    try:
        loop = asyncio.get_running_loop()
        result = []
        for doc in docs:
            result.append(loop.run_in_executor(None, lambda d=doc: blocking(d))) # lambda lazy binding

        await asyncio.gather(*result)
        return True
    except Exception as e:
        logger.error(e)
        return False

