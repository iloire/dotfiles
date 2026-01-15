#!/usr/bin/env python3
# Category: cleanup
# Description: Check if cookie cleaning is running on schedule
import os
import sys

from datetime import datetime, timedelta

stop_file = os.path.expanduser("~/stop_cookie_cleaning.txt")
if os.path.exists(stop_file):
    sys.exit(0)

# Configuration
home_dir = os.path.expanduser('~')
LOG_FILE_PATH = f'{home_dir}/cookies-whitelist-log.log'
DAYS_THRESHOLD = 2  # Alert if no update for more than 2 days

def check_log_file():
    # Get the last modification time of the log file
    try:
        last_modified_time = os.path.getmtime(LOG_FILE_PATH)
        last_modified = datetime.fromtimestamp(last_modified_time)
    except FileNotFoundError:
        print(f"ERROR: Log file '{LOG_FILE_PATH}' not found!")
        return

    # Current time
    now = datetime.now()

    # Calculate the difference
    time_difference = now - last_modified

    # Check if the difference exceeds the threshold
    if time_difference > timedelta(days=DAYS_THRESHOLD):
        print(f"ALERT: Log file '{LOG_FILE_PATH}' hasn't been updated since {last_modified}!")
        print(f"It’s been over {DAYS_THRESHOLD} days.")
    else:
        print(f"Log file '{LOG_FILE_PATH}' is up to date. Last modified: {last_modified}")

if __name__ == "__main__":
    check_log_file()
