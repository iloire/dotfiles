#!/usr/bin/env python3
"""
Cleans non white-listed cookies on Chrome

1. Example of cookies-whitelist.txt (domains you allow cookies for). One domain per line:

www.microsoft.com
www.google.es
www.namecheap.com

2. Now put it in your crontab:

0 20 * * 1 /usr/bin/python $HOME/dotfiles/bin/clean-cookies.py --clean
"""
import sqlite3 as db
import os
import sys
import datetime
import re
from sys import platform

if os.getenv('EXECUTE_COOKIE_CLEANING') == 'false':
    sys.exit(0)

home_dir = os.path.expanduser('~')
run_clean = (len(sys.argv)> 1 and sys.argv[1] == '--clean')
whitelist_dir = f'{home_dir}/myconfig/cookies-whitelist.txt'
log_file = f'{home_dir}/cookies-whitelist-log.log'

def append_to_log(log_file, deleted_rows):
    current_date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_line = f"{current_date} - deleted rows: {len(deleted_rows)}\n"
    with open(log_file, "a") as file:
        file.write(log_line)

def filter_strings(string_list, whitelist):
    filtered_list = []
    removed_list = []
    for string in string_list:
        if any(re.match(pattern, string) for pattern in whitelist):
            filtered_list.append(string)
        else:
            removed_list.append(string)
    return filtered_list, removed_list

def get_cookie_host_list(db_path):
    conn = db.connect(db_path)
    c = conn.cursor()
    c.execute("SELECT host_key FROM cookies")
    cookie_host_list = [row[0] for row in c.fetchall()]
    conn.close()
    return cookie_host_list

def get_db_path():
    if platform == 'linux' or platform == 'linux2':
        return f'{home_dir}/.config/google-chrome/Default/Cookies'
    elif platform == 'darwin':
        return f'{home_dir}/Library/Application Support/Google/Chrome/Default/Cookies'

def remove_cookies_hosts(cookie_hosts_to_remove):
    conn = db.connect(db_path)
    c = conn.cursor()
    for host in cookie_hosts_to_remove:
      c.execute("DELETE FROM cookies where host_key='" + host + "'")

    conn.commit()
    c.execute("vacuum")
    conn.close()

if not os.path.exists(whitelist_dir):
    print(f'no whitelist file found on {whitelist_dir}')
    quit()

with open(whitelist_dir) as f:
    white_listed_lines = f.read().splitlines()

db_path = get_db_path()
if not os.path.exists(db_path):
    print(f'database file not found on {db_path}')
    quit()

cookie_host_list = get_cookie_host_list(db_path)    

cookies_to_keep, cookie_hosts_to_remove = filter_strings(cookie_host_list, white_listed_lines)
if (run_clean):
    remove_cookies_hosts(cookie_hosts_to_remove)
    append_to_log(log_file, cookie_hosts_to_remove)
else:
    print(f"--- dry run: skipping removing cookie for hosts")
    print('--- Cookies to be removed:')
    print(cookie_hosts_to_remove)
    print('--- Whitelisted cookies:')
    print(cookies_to_keep)
    print('--- Cookies hosts:')
    print(cookie_host_list)
