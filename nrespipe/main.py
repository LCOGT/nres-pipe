import logging
import sys

from kombu import Exchange, Connection, Queue

from nrespipe import settings
from nrespipe.listener import NRESListener
from nrespipe.utils import wait_for_task_rabbitmq
from nrespipe import tasks
import celery

logger = logging.getLogger('nrespipe')
fits_exchange = Exchange('fits_files', type='fanout')


def run_listener():
    logger.info('Starting NRES pipeline listener')
    wait_for_task_rabbitmq(settings.broker_url, settings.broker_username, settings.broker_password)

    listener = NRESListener(settings.FITS_BROKER, settings.data_reduction_root, settings.db_address)

    with Connection(listener.broker_url) as connection:
        listener.connection = connection
        listener.ensure_connection(max_retries=None)
        listener.queue = Queue('nres_pipeline', fits_exchange)
        try:
            listener.run()
        except KeyboardInterrupt:
            logger.info('Shutting down...')
            sys.exit(0)


def run_celery_worker():
    logger.info('Starting celery worker')
    worker = celery.bin.worker.worker(app=tasks.app)
    worker.run(concurrency=1)
