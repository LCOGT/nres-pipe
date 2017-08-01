import logging
import sys

from kombu import Exchange, Connection, Queue

from nrespipe import settings
from nrespipe.listener import NRESListener
from nrespipe.utils import wait_for_task_rabbitmq
from nrespipe import tasks
import celery.bin.worker
import celery.bin.beat
import argparse


logger = logging.getLogger('nrespipe')
logger.propagate = False
fits_exchange = Exchange('fits_files', type='fanout')


def run_listener():
    logger.info('Starting NRES pipeline listener')
    wait_for_task_rabbitmq(settings.rabbitmq_host, settings.broker_username, settings.broker_password)

    listener = NRESListener(settings.FITS_BROKER, settings.data_reduction_root, settings.db_address)

    with Connection(listener.broker_url) as connection:
        listener.connection = connection
        connection.ensure_connection(max_retries=None)
        listener.queue = Queue('nres_pipeline', fits_exchange)
        try:
            listener.run()
        except KeyboardInterrupt:
            logger.info('Shutting down...')
            sys.exit(0)


def run_celery_worker():
    wait_for_task_rabbitmq(settings.rabbitmq_host, settings.broker_username, settings.broker_password)
    logger.info('Starting celery worker')
    worker = celery.bin.worker.worker(app=tasks.app)
    worker.run(concurrency=1, hostname='worker')


def stack_nres_calibrations():
    parser = argparse.ArgumentParser(description='Reduce all the data from a site at the end of a night.')
    parser.add_argument('--site', dest='site', required=True, help='Site code (e.g. ogg)')
    parser.add_argument('--camera', dest='camera', required=True, help='instrument code (e.g. fl09)')
    parser.add_argument('--calibration-type', dest='calibration_type', choices=['BIAS', 'DARK', 'FLAT'], required=True,
                        help='Calibration type to stack.')
    parser.add_argument('--start', required=True, help='Starting datetime to stack. Format should be YYYY-mm-ddTHH:MM:ss')
    parser.add_argument('--end', required=True, help='Ending datetime to stack. Format should be YYYY-mm-ddTHH:MM:ss')
    parser.add_argument('--nres-instrument', dest='nres_instrument', required=True,
                        help='NRES instrument name (e.g. nres01)')
    args = parser.parse_args()

    tasks.make_stacked_calibrations.delay(args.site, args.camera, args.calibration_type, [args.start, args.end],
                                          settings.data_reduction_root, args.nres_instrument)


def run_periodic_worker():
    wait_for_task_rabbitmq(settings.rabbitmq_host, settings.broker_username, settings.broker_password)
    logger.info('Starting periodic worker')
    worker = celery.bin.worker.worker(app=tasks.app)
    worker.run(concurrency=1, queues='periodic', hostname='periodic')


def run_beats_scheduler():
    wait_for_task_rabbitmq(settings.rabbitmq_host, settings.broker_username, settings.broker_password)
    logger.info('Starting Beats Scheduler')
    beat = celery.bin.beat.beat(app=tasks.app)
    beat.run()

def create_db():
    pass

def create_deployment_directories():
    """zero  trace  temp  spec  plot  extr  diag  dark  config  ccor  bias
       trip  thar   tar   rv    flat  expm  dble  csv   class   blaz
    """
    pass

def copy_in_empty_csv_files():
    pass
