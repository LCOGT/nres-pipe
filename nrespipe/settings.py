import os
import logging.config
from lcogt_logging import LCOGTFormatter
from datetime import timedelta
from celery.schedules import crontab
import requests

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

ARCHIVE_API_ROOT = os.getenv('API_ROOT')
ARCHIVE_FRAME_URL = f'{ARCHIVE_API_ROOT}/frames/'

ARCHIVE_AUTH_TOKEN = {'Authorization': f'Token {os.getenv("AUTH_TOKEN")}'}

DO_INGEST = os.getenv('DO_INGEST', False)

db_address = os.getenv('DB_URL', 'sqlite:///test.db')
data_reduction_root = os.getenv('NRES_DATA_ROOT', './')
do_radial_velocity = os.getenv('NRES_DO_RV', 1)

calibration_stack_delay_from_site_restart = int(os.getenv('CAL_STACK_DELAY', 4))

blacklisted_filenames = ['g00', 'x00']

recipient_emails = os.getenv('SUMMARY_RECIPIENTS', "somaddress@somewhere.com").split(',')
sender_email = os.getenv('SUMMARY_SENDER', "somaddress@somewhere.com")
sender_password = os.getenv('SUMMARY_SENDER_PASSWORD', "password")

# Format for parsing dates throughout the code
date_format = '%Y-%m-%dT%H:%M:%S'

calibration_schedule = {'{site}__stack_calibrations_nightly'.format(site=site):
                            {'task': 'nrespipe.tasks.make_stacked_calibrations_for_one_night',
                             'schedule': crontab(minute=0,
                                                 hour=site_restart + calibration_stack_delay_from_site_restart),
                             'kwargs': {'site': site, 'camera': camera,'nres_instrument': nres_instrument},
                             'options': {'queue': 'periodic'}
                            }
                        for site, camera, nres_instrument, site_restart in [('lsc', 'fa09', 'nres01', 16),
                                                                            ('elp', 'fa17', 'nres02', 18),
                                                                            ('cpt', 'fa13', 'nres03', 11),
                                                                            ('tlv', 'fa18', 'nres04', 9)]}


trace_refine_schedule = {'{site}_refine_trace_nightly'.format(site=site):
                             {'task': 'nrespipe.tasks.refine_trace_from_night',
                              'schedule': crontab(minute=0,
                                                  hour= site_restart + calibration_stack_delay_from_site_restart),
                              'kwargs': {'site': site, 'camera': camera, 'nres_instrument': nres_instrument,
                                         'raw_data_root': '/archive/engineering'},
                              'options': {'queue': 'periodic'}
                              }
                         for site, camera, nres_instrument, site_restart in [('lsc', 'fa09', 'nres01', 16),
                                                                             ('elp', 'fa17', 'nres02', 18),
                                                                             ('cpt', 'fa13', 'nres03', 11),
                                                                             ('tlv', 'fa18', 'nres04', 9)]}
beat_schedule = {**calibration_schedule, **trace_refine_schedule,
                 'queue-length-every-minute': {'task': 'nrespipe.tasks.collect_queue_length_metric',
                                               'schedule': timedelta(minutes=1),
                                               'args': (rabbitmq_host,),
                                               'options': {'queue': 'periodic'}
                                               },
                 'send_nightly_summary': {'task': 'nrespipe.tasks.send_end_of_night_summary_plots',
                                          'schedule': crontab(minute=31, hour=16),
                                          'kwargs': {'sites': ['lsc', 'elp', 'cpt', 'tlv'],
                                                     'instruments':['nres01', 'nres02', 'nres03', 'nres04'],
                                                     'sender_email': sender_email,
                                                     'sender_password': sender_password,
                                                     'recipient_emails': recipient_emails,
                                                     'raw_data_root': '/archive/engineering'},
                                          'options': {'queue': 'periodic'}
                                          }
                 }

