import os
import logging
from lcogt_logging import LCOGTFormatter
from datetime import timedelta


# logging
logConf = { "formatters": { "default": {"()": LCOGTFormatter}},
            "handlers": { "console": { "class": "logging.StreamHandler", "formatter": "default"}},
            "loggers": { "nrespipe": { "handlers": ["console"], "level": logging.DEBUG}},
            "version": 1 }

logging.config.dictConfig(logConf)

#  General settings
broker_url = os.getenv('BROKER_URL', 'memory://localhost')
broker_username = os.getenv('BROKER_USERNAME', 'guest')
broker_password = os.getenv('BROKER_PASSWORD', 'guest')

FITS_BROKER = os.getenv('FITS_BROKER', 'memory://localhost')

db_address = os.getenv('DB_URL', 'sqlite:///test.db')
data_reduction_root = os.getenv('NRES_DATA_ROOT', './')

beat_schedule = {'queue-length-every-minute': {'task': 'tasks.collect_queue_length_metric',
                                               'schedule': timedelta(minutes=1),
                                               'args': ('http://rabbitmq:15672/',),
                                               'options': {'queue': 'periodic'}
                                               }
                 }

