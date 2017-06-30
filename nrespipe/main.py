from nrespipe.listener import NRESListener
from kombu import Exchange, Connection, Queue
import logging
import sys
from nrespipe import settings


logger = logging.getLogger('nrespipe')
fits_exchange = Exchange('fits_files', type='fanout')


def run_listener():
    logger.info('Starting NRES pipeline listener')
    listener = NRESListener(settings.fits_broker, settings.db_address)

    with Connection(listener.broker_url) as connection:
        listener.connection = connection
        listener.ensure_connection(max_retries=None)
        listener.queue = Queue('nres_pipeline', fits_exchange)
        try:
            listener.run()
        except KeyboardInterrupt:
            logger.info('Shutting down...')
            sys.exit(0)
