from sqlalchemy import create_engine, text
from sqlalchemy import Column, Integer, String, Text, Boolean, Float, DateTime, PrimaryKeyConstraint, Index
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.dialects.postgresql import UUID

Base = declarative_base()

class App(Base):
    __tablename__ = 'apps'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='app_pkey'),
        Index('app_tenant_id_idx', 'tenant_id')
    )

    id = Column(UUID(as_uuid=False), server_default=text('uuid_generate_v4()'))
    tenant_id = Column(UUID(as_uuid=False), nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=False, server_default=text("''::character varying"))
    mode = Column(String(255), nullable=False)
    icon = Column(String(255))
    icon_background = Column(String(255))
    app_model_config_id = Column(UUID(as_uuid=False), nullable=True)
    workflow_id = Column(UUID(as_uuid=False), nullable=True)
    status = Column(String(255), nullable=False, server_default=text("'normal'::character varying"))
    enable_site = Column(Boolean, nullable=False)
    enable_api = Column(Boolean, nullable=False)
    api_rpm = Column(Integer, nullable=False, server_default=text('0'))
    api_rph = Column(Integer, nullable=False, server_default=text('0'))
    is_demo = Column(Boolean, nullable=False, server_default=text('false'))
    is_public = Column(Boolean, nullable=False, server_default=text('false'))
    is_universal = Column(Boolean, nullable=False, server_default=text('false'))
    created_at = Column(DateTime, nullable=False, server_default=text('CURRENT_TIMESTAMP(0)'))
    updated_at = Column(DateTime, nullable=False, server_default=text('CURRENT_TIMESTAMP(0)'))
    creator_id = Column(UUID(as_uuid=False), nullable=True)
    creator_name = Column(String(255), nullable=True)

# create_engine('postgresql+psycopg2://user:password@hostname/database_name')
engine = create_engine('postgresql+psycopg2://postgres:password@localhost/database_name')
Session = sessionmaker(bind=engine)
session = Session()

data = session.query(App).select_from(App).all()
for i in data:
    print(i.id, end='  ')
    print(i.name)

