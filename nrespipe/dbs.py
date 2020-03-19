import sqlalchemy.ext.declarative
from sqlalchemy import Column, Integer, Boolean, CHAR, String
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy import pool
from sqlalchemy.sql.expression import true


Base = sqlalchemy.ext.declarative.declarative_base()


class ProcessingState(Base):
    """
    Database Record to store which files have been processed.
    """
    __tablename__ = 'processingstate'
    id = Column(Integer, primary_key=True, autoincrement=True)
    filename = Column(String(100), unique=True, index=True)
    checksum = Column(CHAR(32), default='0'*32)
    processed = Column(Boolean, default=False)
    frameid = Column(Integer, default=None, nullable=True)


def create_db(db_address):
    """
    Create the database.

    Parameters
    ----------
    db_address : str
                 SQLAlchemy style url to the database

    Notes
    -----
    This only needs to be run once on initialization of the database. This code works for mysql, sqlite, and postgres
    without modification.
    """
    # Create an engine for the database
    engine = create_engine(db_address)

    # Create all tables in the engine
    # This only needs to be run once on initialization.
    Base.metadata.create_all(engine)


def get_session(db_address):
    """
    Get a connection to the database.

    Returns
    -------
    session: SQLAlchemy Database Session
    """
    # Build a new engine for each session. This makes things thread safe.
    engine = create_engine(db_address, poolclass=pool.NullPool)
    Base.metadata.bind = engine

    # We don't use autoflush typically. I have run into issues where SQLAlchemy would try to flush
    # incomplete records causing a crash. None of the queries here are large, so it should be ok.
    db_session = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)
    return db_session()


def get_or_create(db_address, table_model, equivalence_criteria, record_attributes):
    """
    Add a record to the database if it does not exist or update the record if it does exist.

    Parameters
    ----------
    table_model : SQLAlchemy Base
                  The class representation of the table of interest

    equivalence_criteria : dict
                           record attributes that need to match for the records to be considered
                           the same

    record_attributes : dict
                        Extra record attributes that will be set if the object is created.

    Returns
    -------
    record : SQLAlchemy Base
             The object representation of the added/retrieved record
    """
    # Build the query
    query = true()
    for key, value in equivalence_criteria.items():
        query &= getattr(table_model, key) == value

    # Connect to the database
    db_session = get_session(db_address)
    record = db_session.query(table_model).filter(query).first()
    if record is None:
        record = table_model(**equivalence_criteria, **record_attributes)
        db_session.add(record)
        db_session.commit()
    db_session.close()
    return record


def get_processing_state(filename, db_address):
    """
    Get the state of pipeline processing for a given file from the database.

    Parameters
    ----------
    filename : str
               file name. This is the primary key of the table
    filepath : str
               Full path to the file of interest
    db_address : str
                 SQLAlchemy style url to the database

    Returns
    -------
    state : nrespipe.dbs.ProcessingState
            The current state of processing for the file of interest
    """
    return get_or_create(db_address, ProcessingState, {'filename': filename}, {})


def set_file_as_processed(filename, checksum, frameid, db_address):
    """
    Mark a file as processed in the database

    Parameters
    ----------
    filename : str
           File name of interest
    checksum :
    db_address : str
                 SQLAlchemy style url to the database
    """
    record = get_or_create(db_address, ProcessingState, {'filename': filename}, {'checksum': checksum})
    record.processed = True
    record.checksum = checksum
    record.frameid = frameid

    db_session = get_session(db_address)
    db_session.add(record)
    db_session.commit()
    db_session.close()
