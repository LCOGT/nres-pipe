import os
import logging.config
from lcogt_logging import LCOGTFormatter
from datetime import timedelta
from celery.schedules import crontab

# logging
logging.captureWarnings(True)

logConf = { "formatters": { "default": {"()": LCOGTFormatter},
                            "idl": {'(fmt=u"%(message)s")': logging.Formatter}},
            "handlers": { "console": { "class": "logging.StreamHandler", "formatter": "default",
                                       "stream": "ext://sys.stdout"},
                          "idlconsole": {"class": "logging.StreamHandler", "formatter": "idl",
                                         "stream": "ext://sys.stdout"}},
            "loggers": {"nrespipe": { "handlers": ["console"], "level": logging.INFO, "propagate": False},
                        "idl": {"handlers": ["idlconsole"], "level": logging.INFO, "propagate": False}},
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
do_radial_velocity = os.getenv('NRES_DO_RV', 1)


blacklisted_filenames = ['g00', 'x00']

recipient_emails = os.getenv('SUMMARY_RECIPIENTS', "somaddress@somewhere.com").split(',')
sender_email = os.getenv('SUMMARY_SENDER', "somaddress@somewhere.com")
sender_password = os.getenv('SUMMARY_SENDER_PASSWORD', "password")

# Format for parsing dates throughout the code
date_format = '%Y-%m-%dT%H:%M:%S'

beat_schedule = {'queue-length-every-minute': {'task': 'nrespipe.tasks.collect_queue_length_metric',
                                               'schedule': timedelta(minutes=1),
                                               'args': (rabbitmq_host,),
                                               'options': {'queue': 'periodic'}
                                               },
                 'lsc_stack_calibrations_nightly': {'task': 'nrespipe.tasks.make_stacked_calibrations_for_one_night',
                                               'schedule': crontab(minute=0, hour=16),
                                               'kwargs': {'site': 'lsc', 'camera': 'fl09', 'nres_instrument': 'nres01'},
                                               'options': {'queue': 'periodic'}
                                               },
                 'lsc_refine_trace_nightly': {'task': 'nrespipe.tasks.refine_trace_from_night',
                                                'schedule': crontab(minute=1, hour=16),
                                                'kwargs': {'site': 'lsc', 'camera': 'fl09',
                                                           'nres_instrument': 'nres01',
                                                           'raw_data_root': '/archive/engineering'},
                                                'options': {'queue': 'periodic'}
                                                },
                 'elp_stack_calibrations_nightly': {'task': 'nrespipe.tasks.make_stacked_calibrations_for_one_night',
                                                    'schedule': crontab(minute=0, hour=18),
                                                    'kwargs': {'site': 'elp', 'camera': 'fl17',
                                                               'nres_instrument': 'nres02'},
                                                    'options': {'queue': 'periodic'}
                                                    },
                 'elp_refine_trace_nightly': {'task': 'nrespipe.tasks.refine_trace_from_night',
                                              'schedule': crontab(minute=1, hour=18),
                                              'kwargs': {'site': 'elp', 'camera': 'fl17',
                                                         'nres_instrument': 'nres02',
                                                         'raw_data_root': '/archive/engineering'},
                                              'options': {'queue': 'periodic'}
                                          },
                 'cpt_stack_calibrations_nightly': {'task': 'nrespipe.tasks.make_stacked_calibrations_for_one_night',
                                                    'schedule': crontab(minute=0, hour=11),
                                                    'kwargs': {'site': 'cpt', 'camera': 'fl13',
                                                               'nres_instrument': 'nres03'},
                                                    'options': {'queue': 'periodic'}
                                                    },
                 'cpt_refine_trace_nightly': {'task': 'nrespipe.tasks.refine_trace_from_night',
                                              'schedule': crontab(minute=1, hour=11),
                                              'kwargs': {'site': 'cpt', 'camera': 'fl13',
                                                         'nres_instrument': 'nres03',
                                                         'raw_data_root': '/archive/engineering'},
                                              'options': {'queue': 'periodic'}
                                              },
                 'send_nightly_summary': {'task': 'nrespipe.tasks.send_end_of_night_summary_plots',
                                              'schedule': crontab(minute=31, hour=16),
                                              'kwargs': {'sites': ['lsc', 'elp', 'cpt'],
                                                         'instruments':['nres01', 'nres02', 'nres03'],
                                                         'sender_email': sender_email,
                                                         'sender_password': sender_password,
                                                         'recipient_emails': recipient_emails,
                                                         'raw_data_root': '/archive/engineering'},
                                              'options': {'queue': 'periodic'}
                                              }
                 }

