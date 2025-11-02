from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import socket
import random
import json
import logging
import psycopg2
import sys
import time

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Environment variables with defaults
option_a = os.getenv('OPTION_A', "Cats")
option_b = os.getenv('OPTION_B', "Dogs")
db_hostname = os.getenv('DB_HOST', 'postgresql')
db_database = os.getenv('PGDATABASE', 'postgres')
db_password = os.getenv('PGPASSWORD', 'postgres')
db_user = os.getenv('PGUSER', 'postgres')
db_port = os.getenv('DB_PORT', '5432')

app = Flask(__name__)
CORS(app)

def get_db_connection():
    """Get database connection with retry logic"""
    max_retries = 5
    retry_delay = 5
    
    for attempt in range(max_retries):
        try:
            conn = psycopg2.connect(
                host=db_hostname,
                user=db_user,
                password=db_password,
                dbname=db_database,
                port=db_port
            )
            logger.info("Successfully connected to database")
            return conn
        except psycopg2.OperationalError as e:
            if attempt < max_retries - 1:
                logger.warning(f"Database connection failed (attempt {attempt + 1}/{max_retries}): {e}")
                time.sleep(retry_delay)
            else:
                logger.error(f"Failed to connect to database after {max_retries} attempts: {e}")
                raise

@app.route("/health", methods=['GET'])
def health():
    """Health check endpoint"""
    try:
        # Test database connection
        conn = get_db_connection()
        conn.close()
        return jsonify({"status": "healthy", "database": "connected"}), 200
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 500

@app.route("/api", methods=['GET'])
def hello():
    return jsonify({"message": "Hello, I am the api service"}), 200

@app.route("/api/vote", methods=['GET'])
def get_votes():
    logger.info("Getting votes")
    
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT vote, COUNT(id) AS count FROM votes GROUP BY vote")
        res = cur.fetchall()
        cur.close()
        conn.close()
        
        # Convert to dictionary for JSON
        votes = {vote: count for vote, count in res}
        return jsonify(votes), 200
    except Exception as e:
        logger.error(f"Error getting votes: {e}")
        return jsonify({"error": "Failed to get votes"}), 500

@app.route("/api/vote", methods=['POST'])
def post_vote():
    voter_id = hex(random.getrandbits(64))[2:-1]
    
    if request.method == 'POST':
        try:
            vote = request.form['vote']
            data = {'voter_id': voter_id, 'vote': vote}
            logger.info(f"Received vote request for '{vote}' from voter id: '{voter_id}'")
            
            conn = get_db_connection()
            query = "INSERT INTO votes (id, vote, created_at) VALUES (%s, %s, NOW())"
            queryParams = (voter_id, vote)
            cur = conn.cursor()
            cur.execute(query, queryParams)
            conn.commit()
            cur.close()
            conn.close()
            
            return jsonify(data), 200
        except Exception as e:
            logger.error(f"Error posting vote: {e}")
            return jsonify({"error": "Failed to post vote"}), 500
    else:
        logger.warning("Received invalid request method")
        return jsonify({"error": "Method not allowed"}), 405

if __name__ == "__main__":
    logger.info("Starting API service")
    # Use Gunicorn in production, Flask dev server for development
    if os.getenv('FLASK_ENV') == 'development':
        app.run(host='0.0.0.0', port=8080, debug=True)
    else:
        # Gunicorn will be used in production
        app.run(host='0.0.0.0', port=8080)