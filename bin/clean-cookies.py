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
from sys import platform

def append_to_log(log_file, deleted_rows):
    current_date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_line = f"{current_date} - deleted rows: {len(deleted_rows)}\n"
    with open(log_file, "a") as file:
        file.write(log_line)

home_dir = os.path.expanduser('~')
whitelist_dir = f'{home_dir}/cookies-whitelist.txt'

if not os.path.exists(whitelist_dir):
    print(f'no whitelist file found on {whitelist_dir}')
    quit()

if platform == 'linux' or platform == 'linux2':
    db_name = f'{home_dir}/.config/google-chrome/Default/Cookies'
elif platform == 'darwin':
    db_name = f'{home_dir}/Library/Application Support/Google/Chrome/Default/Cookies'

with open(whitelist_dir) as f:
    white_listed_lines = f.read().splitlines()

conn = db.connect(db_name)
c = conn.cursor()
c.execute("SELECT host_key FROM cookies")

rows = c.fetchall()

run_clean = (len(sys.argv)> 1 and sys.argv[1] == '--clean')

print(f"Number cookies: {len(rows)}")
print(f"runclean: {run_clean}")

deleted_rows = []

for index, row in enumerate(rows):
    host = row[0]
    if (host not in white_listed_lines):
        if (run_clean):
            c.execute("DELETE FROM cookies where host_key='" + host + "'")
            deleted_rows.append(host)
        else:
            print(f"dry run: skipping removing cookie for {host}")
    else: # white listed
        if not (run_clean):
            print(f"white listed: {host}")

log_file = f'{home_dir}/cookies-whitelist-log.log'
append_to_log(log_file, deleted_rows)

conn.commit()
c.execute("vacuum")
conn.close()
