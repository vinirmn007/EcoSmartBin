import logging
from pythonjsonlogger import jsonlogger
from datetime import datetime, timezone

class BusinessEventFormatter(jsonlogger.JsonFormatter):
    def add_fields(self, log_record, record, message_dict):
        super(BusinessEventFormatter, self).add_fields(log_record, record, message_dict)
        # GCP Cloud Logging espera 'severity' nativamente
        log_record['severity'] = record.levelname
        log_record['time'] = datetime.now(timezone.utc).isoformat()
        # Marca específica para filtrar en Grafana los eventos de negocio
        log_record['event_category'] = 'business_event'

def get_business_logger():
    logger = logging.getLogger("business_events_basureros")
    logger.setLevel(logging.INFO)

    # Evitar que se añadan múltiples handlers si se llama varias veces
    if not logger.handlers:
        handler = logging.StreamHandler()
        formatter = BusinessEventFormatter('%(message)s %(event_type)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)

        # Evita propagar al root logger para que no se dupliquen o cambien de formato
        logger.propagate = False

    return logger

business_logger = get_business_logger()
