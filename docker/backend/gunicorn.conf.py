import multiprocessing
import os

bind = "0.0.0.0:8000"
workers = max(2, multiprocessing.cpu_count())
accesslog = "/var/log/conduit/access.log"
errorlog = "/var/log/conduit/error.log"
loglevel = os.getenv("GUNICORN_LOG_LEVEL", "info")
timeout = int(os.getenv("GUNICORN_TIMEOUT", "30"))
preload_app = True

