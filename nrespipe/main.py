from nrespipe.listener import NRESListener
import argparse
from kombu import Exchange, Connection, Queue
import logging
import sys
from celery import Celery
from celery.bin import worker


logger = logging.getLogger('nrespipe')
fits_exchange = Exchange('fits_files', type='fanout')


def run_listener():
    parser = argparse.ArgumentParser(description='Run the NRES pipeline listener on the fits exchange.')
    parser.add_argument('--fits-broker', dest='fits_broker', help='URL of the fits exchange')
    parser.add_argument('--db-addresss', dest='db_address', help='SQLAlchemy style URL of the pipeline database')
    args = parser.parse_args()

    logger.info('Starting NRES pipeline listener')
    listener = NRESListener(args.fits_broker, args.db_address)

    with Connection(listener.broker_url) as connection:
        listener.connection = connection
        listener.ensure_connection(max_retries=None)
        listener.queue = Queue('nres_pipeline', fits_exchange)
        try:
            listener.run()
        except KeyboardInterrupt:
            logger.info('Shutting down...')
            sys.exit(0)


def run_celery_tasks():
    app = Celery('nrestasks', broker='pyamqp://guest@localhost//')


worker = worker.worker(app=app)


class Command(CeleryCommand):
    """Run the celery daemon."""
    help = 'Old alias to the "celery worker" command.'
    options = (CeleryCommand.options +
               worker.get_options() +
               worker.preload_options)

    def handle(self, *args, **options):
        worker.check_args(args)
        worker.run(**options)