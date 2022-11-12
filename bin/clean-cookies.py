# for OSX so far, cleans up cookies not found on the whitelist (one host per line)

import sqlite3 as db
import os
import sys

home_dir = os.path.expanduser('~')
whitelist_dir = f'{home_dir}/cookies-whitelist.txt'

if not os.path.exists(whitelist_dir):
    print(f'no whitelist file found on {whitelist_dir}')
    quit()

db_name = f'{home_dir}/Library/Application Support/Google/Chrome/Default/Cookies'

with open(whitelist_dir) as f:
    white_listed_lines = f.read().splitlines()

conn = db.connect(db_name)
c = conn.cursor()
c.execute("SELECT host_key FROM cookies")

rows = c.fetchall()
for index, row in enumerate(rows):
    host = row[0]
    if (host not in white_listed_lines):
        if (len(sys.argv)> 1 and sys.argv[1] == '--clean'):
            # print(f"removing cookie for {host}")
            c.execute("DELETE FROM cookies where host_key='" + host + "'")
        else:
            print(f"dry run: skipping removing cookie for {host}")

conn.commit()
c.execute("vacuum")
conn.close()
