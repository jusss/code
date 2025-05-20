import pandas as pd
from datetime import datetime
from typing import Callable

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, scoped_session, Session
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Mapped, DeclarativeBase
from sqlalchemy import BigInteger, Column, SmallInteger, String, Text, update, Integer
from sqlalchemy.orm import Mapped
from sqlalchemy.orm import Mapped
from sqlalchemy.orm import mapped_column

class BaseModel(DeclarativeBase):
    create_time: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now()
    )
    update_time: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP')
    )

class DownloadQuery(BaseModel):
    __tablename__ = "message"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)


class ExercisesAssessment(BaseModel):
    __tablename__ = "assessment"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    exercise_id: Mapped[int] = mapped_column(BigInteger)

class Exercises(BaseModel):
    __tablename__ = "exercises"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=False)
    state: Mapped[int] = mapped_column(Integer)

class MysqlSessionFactory(object):

    def __init__(self):

        user = ''
        pwd = ''
        host = ''
        port = 0
        database = ''

        self.engine = create_engine(
            f"mysql+pymysql://{user}:{pwd}@{host}:{port}/{database}?charset=utf8mb4",
            echo=True,
            pool_pre_ping=True,
            pool_recycle=3000,
            max_overflow=10
        )
        self._session_factory = scoped_session(sessionmaker(bind=self.engine, autoflush=False, expire_on_commit=False))

    @contextmanager
    def session(self):
        session: Session = self._session_factory()
        try:
            yield session
        except SQLAlchemyError:
            session.rollback()
            raise
        finally:
            session.close()


MYSQL_SESSION_FACTORY = MysqlSessionFactory()

]

# with MYSQL_SESSION_FACTORY.session() as session:
#     data = session.query(DownloadQuery).filter(DownloadQuery.create_time > datetime(2024,10,30))
#     result = [d.query for d in data if d.query not in TMP_SUG_LIST]
#     # data = session.query(DownloadQuery).count()
#     print(len(result))
#
#
#
# df = pd.DataFrame(result, columns=['query'])
#
# output_filename = 'query20k.xlsx'
# df.to_excel(output_filename, index=False)


with MYSQL_SESSION_FACTORY.session() as session:
    # data = session.query(Exercises).join(ExercisesAssessment, Exercises.id == ExercisesAssessment.exercise_id).filter(
    #     ExercisesAssessment.tag_id == 21).all()
    data = session.query(Exercises).all()
    # result = [d.query for d in data if d.query not in TMP_SUG_LIST]
    # data = session.query(DownloadQuery).count()
    print(len(data))
