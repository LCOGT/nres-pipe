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
FITS_BROKER = os.getenv('FITS_BROKER', 'memory://localhost')

beat_schedule = {'queue-length-every-minute': {'task': 'tasks.collect_queue_length_metric',
                                               'schedule': timedelta(minutes=1),
                                               'args': ('http://ingesterrabbitmq:15672/',),
                                               'options': {'queue': 'periodic'}
                                               }
                 }

