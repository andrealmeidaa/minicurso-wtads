#!/usr/bin/env python3

import multiprocessing
import os

# Gunicorn configuration file

# Server socket
bind = "127.0.0.1:8000"
backlog = 2048

# Worker processes
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
worker_connections = 1000
timeout = 30
keepalive = 2

# Restart workers after this many requests, to help prevent memory leaks
max_requests = 1000
max_requests_jitter = 100

# Logging
loglevel = "info"
accesslog = "-"  # Log to stdout
errorlog = "-"   # Log to stderr

# Process naming
proc_name = "task_project"

# Server mechanics
preload_app = True
daemon = False
tmp_upload_dir = None

# SSL
keyfile = None
certfile = None
