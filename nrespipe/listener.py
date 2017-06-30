from kombu.mixins import ConsumerMixin
from nrespipe import tasks
import logging

logger = logging.getLogger('nrespipe')

class NRESListener(ConsumerMixin):
    def __init__(self, broker_url, db_address):
        self.broker_url = broker_url
        self.db_address = db_address

    def on_connection_error(self, exc, interval):
        logger.error("{0}. Retrying connection in {1} seconds...".format(exc, interval))
        self.connection = self.connection.clone()
        self.connection.ensure_connection(max_retries=None)

    def get_consumers(self, Consumer, channel):
        consumer = Consumer(queues=[self.queue], callbacks=[self.on_message])
        # Only fetch one thing off the queue at a time
        consumer.qos(prefetch_count=1)
        return [consumer]

    def on_message(self, body, message):
        path = body.get('path')
        tasks.process_nres_file.delay(path=path, db_address=self.db_address)
        message.ack()  # acknowledge to the sender we got this message (it can be popped)
