import os
import logging.config
from lcogt_logging import LCOGTFormatter
from datetime import timedelta
from celery.schedules import crontab

# logging
logConf = { "formatters": { "default": {"()": LCOGTFormatter}},
            "handlers": { "console": { "class": "logging.StreamHandler", "formatter": "default",
                                       "stream": "ext://sys.stdout"}},
            "loggers": { "nrespipe": { "handlers": ["console"], "level": logging.INFO}},
            "version": 1 }

logging.config.dictConfig(logConf)

#  General settings
broker_url = os.getenv('BROKER_URL', 'memory://localhost')
rabbitmq_host = os.getenv('RABBITMQ_HOST', 'memory://localhost')
broker_username = os.getenv('BROKER_USERNAME', 'guest')
broker_password = os.getenv('BROKER_PASSWORD', 'guest')

FITS_BROKER = os.getenv('FITS_BROKER', 'memory://localhost')

db_address = os.getenv('DB_URL', 'sqlite:///test.db')
data_reduction_root = os.getenv('NRES_DATA_ROOT', './')


blacklisted_filenames = ['g00', 'x00']

# Format for parsing dates throughout the code
date_format = '%Y-%m-%dT%H:%M:%S'

beat_schedule = {'queue-length-every-minute': {'task': 'nrespipe.tasks.collect_queue_length_metric',
                                               'schedule': timedelta(minutes=1),
                                               'args': (rabbitmq_host,),
                                               'options': {'queue': 'periodic'}
                                               },
                 'stack_calibrations_nightly': {'task': 'nrespipe.tasks.make_stacked_calibrations_for_one_night',
                                               'schedule': crontab(minute=0, hour=16),
                                               'kwargs': {'site': 'lsc', 'camera': 'fl09', 'nres_instrument': 'nres01'},
                                               'options': {'queue': 'periodic'}
                                               },
                 'refine_trace_nightly': {'task': 'nrespipe.tasks.refine_trace_from_last_night',
                                                'schedule': crontab(minute=1, hour=16),
                                                'kwargs': {'site': 'lsc', 'camera': 'fl09',
                                                           'nres_instrument': 'nres01',
                                                           'raw_data_root': '/archive/engineering'},
                                                'options': {'queue': 'periodic'}
                                                }
                 }

