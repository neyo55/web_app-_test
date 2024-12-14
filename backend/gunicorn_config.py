import multiprocessing

# Bind to a different port if using a reverse proxy like Nginx, or keep it on 5000 for direct access
bind = "0.0.0.0:5000"

# Number of workers based on the number of CPU cores
workers = (multiprocessing.cpu_count() * 2) + 1

# Timeout settings: Adjust according to the nature of your application
timeout = 30  # Lower the timeout for better performance and to avoid hanging workers

# Logging settings for production
loglevel = "info"  # Use "info" or "warning" for production to reduce log noise
errorlog = "/var/log/gunicorn/error.log"  # Log errors to a file
accesslog = "/var/log/gunicorn/access.log"  # Log access requests to a file

# Enable output capture to the Gunicorn log
capture_output = True

# Additional settings
preload_app = True  # Preload the application code before the worker processes are forked (saves memory)
