import logging
from logging.handlers import RotatingFileHandler
from flask import Flask, request, render_template, send_from_directory, redirect, url_for, flash
import mysql.connector
import redis
from dotenv import load_dotenv
import os
from forms import UserForm  # Import the form from forms.py
from prometheus_client import start_http_server, Counter, generate_latest, Summary
from flask import Response

# Load environment variables from .env file
load_dotenv()

# Initialize Flask app with custom static and template folders
app = Flask(
    __name__,
    static_folder='../frontend/static',
    template_folder='../frontend/templates'
)

# Set the secret key for session management and CSRF protection
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY')

# Ensure the logs directory exists and is writable
log_directory = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'logs')
if not os.path.exists(log_directory):
    os.makedirs(log_directory)

# Set up logging with rotation and use LOG_LEVEL from environment
log_file_path = os.path.join(log_directory, 'app.log')
handler = RotatingFileHandler(log_file_path, maxBytes=10240, backupCount=5)

# Get log level from environment, default to DEBUG if not set
log_level = os.getenv('LOG_LEVEL', 'DEBUG').upper()
logging.getLogger().setLevel(getattr(logging, log_level))

handler.setFormatter(logging.Formatter('%(asctime)s %(levelname)s:%(message)s'))
logging.getLogger().addHandler(handler)

# Check required environment variables
required_vars = ['DB_HOST', 'DB_USER', 'DB_PASSWORD', 'DB_NAME', 'REDIS_HOST', 'REDIS_PORT', 'REDIS_DB']
for var in required_vars:
    if not os.getenv(var):
        logging.error(f'Missing required environment variable: {var}')
        raise ValueError(f'Missing required environment variable: {var}')

# Configure Redis connection using environment variables
def get_redis_connection():
    redis_host = os.getenv('REDIS_HOST', 'localhost')
    redis_port = int(os.getenv('REDIS_PORT', 6379))
    redis_db = int(os.getenv('REDIS_DB', 0))
    
    try:
        r = redis.StrictRedis(host=redis_host, port=redis_port, db=redis_db, decode_responses=True)
        if r.ping():
            logging.info('Connected to Redis successfully.')
        return r
    except Exception as e:
        logging.error(f'Failed to connect to Redis: {e}')
        raise

# Initialize Redis connection
redis_client = get_redis_connection()

# Configure database connection using environment variables
def get_db_connection():
    try:
        db = mysql.connector.connect(
            host=os.getenv('DB_HOST'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            database=os.getenv('DB_NAME')
        )
        logging.info('Database connection established successfully.')
        return db
    except mysql.connector.Error as err:
        logging.error(f'Error connecting to the database: {err}')
        raise

@app.route('/', methods=['GET', 'POST'])
def index():
    form = UserForm()
    if request.method == 'POST':
        if form.validate_on_submit():
            db = get_db_connection()
            try:
                name = form.name.data
                email = form.email.data
                phone = form.phone.data
                dob = form.dob.data
                gender = form.gender.data
                address = form.address.data

                # Insert data into the database using parameterized query
                cursor = db.cursor()
                cursor.execute(
                    "INSERT INTO users (name, email, phone, dob, gender, address) VALUES (%s, %s, %s, %s, %s, %s)",
                    (name, email, phone, dob, gender, address)
                )
                db.commit()
                cursor.close()

                # Cache user data in Redis for 300 seconds
                redis_client.set(f"user:{email}", f"{name},{email},{phone},{dob},{gender},{address}", ex=300)
                logging.info(f"Cached user data for {email} in Redis with 300-second TTL.")

                # Invalidate Redis cache related to users
                redis_client.delete("user_list")
                logging.info("Redis cache 'user_list' invalidated after new data submission.")

                flash('Data submitted successfully!', 'success')
                return redirect(url_for('thank_you'))
            except mysql.connector.Error as db_err:
                logging.error(f'Database error: {db_err}')
                flash('A database error occurred.', 'danger')
            except Exception as e:
                logging.error(f'Error in / route: {e}')
                flash('An error occurred while processing your request.', 'danger')
            finally:
                if db.is_connected():
                    db.close()
                    logging.info('Database connection closed.')
        else:
            # Log form validation errors
            for field, errors in form.errors.items():
                for error in errors:
                    logging.error(f"Error in the {field} field - {error}")
            flash('Please correct the errors in the form.', 'danger')
    return render_template('index.html', form=form)

@app.route('/thank_you')
def thank_you():
    return render_template('thank_you.html')

# Add route for serving static files with no cache
@app.route('/static/<path:filename>')
def serve_static(filename):
    return send_from_directory(app.static_folder, filename, cache_timeout=0)

# Endpoint to manually log Redis stats
@app.route('/log_redis_stats')
def log_stats_endpoint():
    try:
        # Get Redis stats and log them
        redis_info = redis_client.info()
        logging.info(f"Redis Memory Usage: {redis_info['used_memory_human']}")
        logging.info(f"Redis Hits: {redis_info['keyspace_hits']}")
        logging.info(f"Redis Misses: {redis_info['keyspace_misses']}")
        return "Redis stats logged successfully", 200
    except Exception as e:
        logging.error(f"Error logging Redis stats: {e}")
        return "Error logging Redis stats", 500

# Prometheus metrics endpoint
@app.route('/metrics')
def metrics():
    return Response(generate_latest(), mimetype='text/plain')

if __name__ == "__main__":
    # Test Redis connection on startup
    try:
        get_redis_connection()
    except Exception as e:
        logging.error(f'Failed to connect to Redis on startup: {e}')

    # Start Prometheus metrics server
    start_http_server(5001)  # Exposes metrics at http://localhost:5001/metrics
    app.run(host='0.0.0.0', port=5000, debug=os.environ.get('FLASK_ENV') == 'development')

























# import logging
# from logging.handlers import RotatingFileHandler
# from flask import Flask, request, render_template, send_from_directory, redirect, url_for, flash
# import mysql.connector
# import redis
# from dotenv import load_dotenv
# import os
# from forms import UserForm  # Import the form from forms.py
# from prometheus_client import start_http_server, Counter, generate_latest, Summary
# from flask import Response

# # Load environment variables from .env file
# load_dotenv()

# # Initialize Flask app with custom static and template folders
# app = Flask(
#     __name__,
#     static_folder='../frontend/static',
#     template_folder='../frontend/templates'
# )

# # Set the secret key for session management and CSRF protection
# app.config['SECRET_KEY'] = os.getenv('SECRET_KEY')

# # Ensure the logs directory exists and is writable
# log_directory = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'logs')
# if not os.path.exists(log_directory):
#     os.makedirs(log_directory)

# # Set up logging with rotation and use LOG_LEVEL from environment
# log_file_path = os.path.join(log_directory, 'app.log')
# handler = RotatingFileHandler(log_file_path, maxBytes=10240, backupCount=5)

# # Get log level from environment, default to DEBUG if not set
# log_level = os.getenv('LOG_LEVEL', 'DEBUG').upper()
# logging.getLogger().setLevel(getattr(logging, log_level))

# handler.setFormatter(logging.Formatter('%(asctime)s %(levelname)s:%(message)s'))
# logging.getLogger().addHandler(handler)

# # Check required environment variables
# required_vars = ['DB_HOST', 'DB_USER', 'DB_PASSWORD', 'DB_NAME', 'REDIS_HOST', 'REDIS_PORT', 'REDIS_DB']
# for var in required_vars:
#     if not os.getenv(var):
#         logging.error(f'Missing required environment variable: {var}')
#         raise ValueError(f'Missing required environment variable: {var}')

# # Configure Redis connection using environment variables
# def get_redis_connection():
#     redis_host = os.getenv('REDIS_HOST', 'localhost')
#     redis_port = int(os.getenv('REDIS_PORT', 6379))
#     redis_db = int(os.getenv('REDIS_DB', 0))
    
#     try:
#         r = redis.StrictRedis(host=redis_host, port=redis_port, db=redis_db, decode_responses=True)
#         if r.ping():
#             logging.info('Connected to Redis successfully.')
#         return r
#     except Exception as e:
#         logging.error(f'Failed to connect to Redis: {e}')
#         raise

# # Initialize Redis connection
# redis_client = get_redis_connection()

# # Configure database connection using environment variables
# def get_db_connection():
#     try:
#         db = mysql.connector.connect(
#             host=os.getenv('DB_HOST'),
#             user=os.getenv('DB_USER'),
#             password=os.getenv('DB_PASSWORD'),
#             database=os.getenv('DB_NAME')
#         )
#         logging.info('Database connection established successfully.')
#         return db
#     except mysql.connector.Error as err:
#         logging.error(f'Error connecting to the database: {err}')
#         raise

# # Function to update user data in MySQL and Redis
# def update_user_data(user_id, name, email, phone, dob, gender, address):
#     db = get_db_connection()
#     try:
#         # Update in the database
#         cursor = db.cursor()
#         cursor.execute(
#             "UPDATE users SET name=%s, email=%s, phone=%s, dob=%s, gender=%s, address=%s WHERE id=%s",
#             (name, email, phone, dob, gender, address, user_id)
#         )
#         db.commit()
#         cursor.close()

#         # Update in Redis
#         redis_client.set(f"user:{email}", f"{name},{email},{phone},{dob},{gender},{address}", ex=300)
#         logging.info(f"Successfully updated data for {email} in both MySQL and Redis.")
#     except mysql.connector.Error as db_err:
#         logging.error(f"Database error during update: {db_err}")
#     except redis.RedisError as redis_err:
#         logging.error(f"Redis error during update: {redis_err}")
#     finally:
#         if db.is_connected():
#             db.close()
#             logging.info('Database connection closed.')

# @app.route('/', methods=['GET', 'POST'])
# def index():
#     form = UserForm()
#     if request.method == 'POST':
#         if form.validate_on_submit():
#             db = get_db_connection()
#             try:
#                 name = form.name.data
#                 email = form.email.data
#                 phone = form.phone.data
#                 dob = form.dob.data
#                 gender = form.gender.data
#                 address = form.address.data

#                 # Check if the user data is already cached in Redis
#                 cached_user_data = redis_client.get(f"user:{email}")
#                 if cached_user_data:
#                     logging.info(f"Cache hit for {email}")
#                     flash('Data retrieved from cache!', 'info')
#                 else:
#                     logging.info(f"Cache miss for {email}, inserting into database.")

#                     # Insert data into the database using parameterized query
#                     cursor = db.cursor()
#                     cursor.execute(
#                         "INSERT INTO users (name, email, phone, dob, gender, address) VALUES (%s, %s, %s, %s, %s, %s)",
#                         (name, email, phone, dob, gender, address)
#                     )
#                     db.commit()
#                     cursor.close()

#                     # Cache the user data in Redis with a TTL(Time To Live) of 3600 seconds (1 hour)
#                     redis_client.set(f"user:{email}", f"{name},{email},{phone},{dob},{gender},{address}", ex=3600)

#                     logging.info(f'Successfully inserted data for {name} into the database and cached in Redis.')
#                     flash('Data submitted successfully!', 'success')
#                 return redirect(url_for('thank_you'))
#             except mysql.connector.Error as db_err:
#                 logging.error(f'Database error: {db_err}')
#                 flash('A database error occurred.', 'danger')
#             except Exception as e:
#                 logging.error(f'Error in /submit route: {e}')
#                 flash('An error occurred while processing your request.', 'danger')
#             finally:
#                 if db.is_connected():
#                     db.close()
#                     logging.info('Database connection closed.')
#         else:
#             # Log form validation errors
#             for field, errors in form.errors.items():
#                 for error in errors:
#                     logging.error(f"Error in the {field} field - {error}")
#             flash('Please correct the errors in the form.', 'danger')
#     return render_template('index.html', form=form)

# @app.route('/thank_you')
# def thank_you():
#     return render_template('thank_you.html')

# # Add route for serving static files with no cache
# @app.route('/static/<path:filename>')
# def serve_static(filename):
#     return send_from_directory(app.static_folder, filename, cache_timeout=0)

# # Endpoint to manually log Redis stats
# @app.route('/log_redis_stats')
# def log_stats_endpoint():
#     try:
#         # Get Redis stats and log them
#         redis_info = redis_client.info()
#         logging.info(f"Redis Memory Usage: {redis_info['used_memory_human']}")
#         logging.info(f"Redis Hits: {redis_info['keyspace_hits']}")
#         logging.info(f"Redis Misses: {redis_info['keyspace_misses']}")
#         return "Redis stats logged successfully", 200
#     except Exception as e:
#         logging.error(f"Error logging Redis stats: {e}")
#         return "Error logging Redis stats", 500

# # Prometheus metrics endpoint
# @app.route('/metrics')
# def metrics():
#     return Response(generate_latest(), mimetype='text/plain')

# if __name__ == "__main__":
#     # Test Redis connection on startup
#     try:
#         get_redis_connection()
#     except Exception as e:
#         logging.error(f'Failed to connect to Redis on startup: {e}')

#     # Start Prometheus metrics server
#     start_http_server(5001)  # Exposes metrics at http://localhost:5001/metrics
#     app.run(host='0.0.0.0', port=5000, debug=os.environ.get('FLASK_ENV') == 'development')