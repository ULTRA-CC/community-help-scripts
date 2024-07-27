import subprocess
from flask import Flask, jsonify, request, abort
import socket
import json
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import sqlite3
import os
import requests

app = Flask(__name__)

limiter = Limiter(
    get_remote_address,
    app=app,
    default_limits=["100 per day", "10 per hour"],
    storage_uri="memory://",
)

# Replace with the desired port number
port = ">port<"
home_dir = os.getcwd()
try:
    # Get the hostname and construct the host URL
    hostname = socket.gethostname()
    host = "{}-direct.usbx.me".format(hostname)
except socket.error as e:
    print("Error:", e)

# BASIC FUNCTIONS

def get_storage_info():
    """
    Retrieve storage information using 'quota -s' command.
    Returns a dictionary with storage information.
    """
    quota_info = subprocess.check_output(["quota", "-s"]).decode("utf-8").splitlines()[-1]

    used_storage_str, total_storage_str = quota_info.split()[1], quota_info.split()[2]

    used_storage_value, used_storage_unit = int(used_storage_str[:-1]), used_storage_str[-1]
    total_storage_value, total_storage_unit = int(total_storage_str[:-1]), total_storage_str[-1]

    unit_to_bytes = {'G': 1024 ** 3, 'M': 1024 ** 2, 'K': 1024}
    used_bytes = used_storage_value * unit_to_bytes.get(used_storage_unit, 1)
    total_bytes = total_storage_value * unit_to_bytes.get(total_storage_unit, 1)
    free_bytes = total_bytes - used_bytes

    free_storage_gb = free_bytes / 1024 ** 3

    storage_info = {
        "used_storage_value": used_storage_value,
        "used_storage_unit": used_storage_unit,
        "total_storage_value": total_storage_value,
        "total_storage_unit": total_storage_unit,
        "free_storage_bytes": free_bytes,
        "free_storage_gb": free_storage_gb
    }

    return storage_info


def get_traffic_info():
    """
    Retrieve traffic information using 'app-traffic info' command.
    Returns a dictionary with traffic information.
    """
    result = subprocess.run(['app-traffic', 'info'], stdout=subprocess.PIPE, text=True)
    lines = result.stdout.split('\n')

    traffic_available_percentage = None
    last_traffic_reset = None
    next_traffic_reset = None
    traffic_used_percentage = None

    for line in lines:
        if 'Traffic available' in line:
            _, traffic_available_percentage = line.split(':')
            traffic_available_percentage = traffic_available_percentage.strip().replace('%', '')
            traffic_used_percentage = 100 - float(traffic_available_percentage)
        elif 'Last traffic reset' in line:
            _, last_traffic_reset = line.split(':', 1)
            last_traffic_reset = last_traffic_reset.strip()
        elif 'Next traffic reset' in line:
            _, next_traffic_reset = line.split(':', 1)
            next_traffic_reset = next_traffic_reset.strip()

    result_dict = {
        'traffic_available_percentage': float(traffic_available_percentage) if traffic_available_percentage else None,
        'last_traffic_reset': last_traffic_reset if last_traffic_reset else None,
        'next_traffic_reset': next_traffic_reset if next_traffic_reset else None,
        'traffic_used_percentage': float(traffic_used_percentage) if traffic_used_percentage else None
    }

    return result_dict


# Function to read the auth token from SQLite database
def read_auth_token(db_file):
    try:
        # Connect to the SQLite database
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()

        # Execute a simple query to retrieve the auth token
        cursor.execute("SELECT auth_token FROM tokens LIMIT 1;")
        token = cursor.fetchone()

        # Close the connection
        conn.close()

        return token[0] if token else None

    except sqlite3.Error as e:
        print("Error reading auth token from the database:", str(e))
        return None


# Specify the SQLite database file path
db_file_path = "{}/scripts/Ultra-API/auth_tokens.db".format(home_dir) 

# Read the auth token
auth_token = read_auth_token(db_file_path)

if auth_token:
    print("Authentication Token found.")
else:
    print("No authentication token found.")

# Authentication decorator using the token from the database
def authenticate(func):
    def wrapper(*args, **kwargs):
        # Check the header for the token
        header_token = request.headers.get("Authorization")

        # Check the query string for the token
        query_token = request.args.get("token")  # Updated to read 'token' from query parameters

        if not header_token and not query_token:
            abort(401, "Unauthorized - Token not provided")

        if header_token and header_token.startswith("Bearer "):
            header_token = header_token.split("Bearer ")[1]

        if query_token and header_token and query_token != header_token:
            abort(401, "Unauthorized - Token mismatch between header and query parameter")

        if header_token:
            if header_token != auth_token:
                abort(401, "Unauthorized - Invalid token in header")
        elif query_token:
            if query_token != auth_token:
                abort(401, "Unauthorized - Invalid token in query parameter")
        else:
            abort(401, "Unauthorized - Token not provided")

        return func(*args, **kwargs)
    return wrapper
# API endpoints

@app.route('/get-diskquota', methods=['GET'],endpoint='get-diskquota')
@limiter.limit("2 per minute",override_defaults = True)
@authenticate
def get_diskquota():
    """
    API endpoint to retrieve storage quota information.
    """
    try:
        storage_info = get_storage_info()
        return jsonify({'Storage Info': storage_info}), 200
    except subprocess.CalledProcessError as e:
        return jsonify({'error': str(e)}), 500


@app.route('/get-traffic', methods=['GET'],endpoint='get-traffic')
@limiter.limit("2 per minute",override_defaults = True)
@authenticate
def get_traffic():
    """
    API endpoint to retrieve traffic bandwidth information.
    """
    try:
        traffic_info = get_traffic_info()
        return jsonify({'Traffic info': traffic_info}), 200
    except subprocess.CalledProcessError as e:
        return jsonify({'error': str(e)}), 500

@app.route('/total-stats', methods=['GET'],endpoint='total-stats')
@limiter.limit("2 per minute",override_defaults = True)
@authenticate
def total_stats():
    """
    API endpoint to retrieve combined storage and traffic information.
    """
    try:
        storage_info = get_storage_info()
        traffic_info = get_traffic_info()
        combined_info = {**storage_info, **traffic_info}
        return jsonify({'service_stats_info': combined_info}), 200
    except subprocess.CalledProcessError as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    app.run(host=host, port=port)
