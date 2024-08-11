from sqlalchemy import create_engine, text
from sqlalchemy import Column, Integer, String, Text, Boolean, Float, DateTime, PrimaryKeyConstraint, Index
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.dialects.postgresql import UUID

Base = declarative_base()

class TestTable(Base):
    __tablename__ = 'test_table'

    id = Column(UUID(as_uuid=False), server_default=text('uuid_generate_v4()'), primary_key=True)
    name = Column(String(255), nullable=False)
    created_at = Column(DateTime, nullable=False, server_default=text('CURRENT_TIMESTAMP(0)'))
    updated_at = Column(DateTime, nullable=False, server_default=text('CURRENT_TIMESTAMP(0)'))
    creator_id = Column(UUID(as_uuid=False), nullable=True)
    creator_name = Column(String(255), nullable=True)

# create_engine('postgresql+psycopg2://user:password@hostname/database_name')
engine = create_engine('postgresql+psycopg2://postgres:password@localhost/database_name')
Session = sessionmaker(bind=engine)
session = Session()

Base.metadata.create_all(engine)

test = TestTable(name = "john")
session.add(test)
session.commit()

data = session.query(TestTable).select_from(TestTable).all()
for i in data:
    print(i.id, end='  ')
    print(i.name)

# you can also check it via `psql -h localhost -p 5432 -U postgres database` input password, then `select * from test_table;`


