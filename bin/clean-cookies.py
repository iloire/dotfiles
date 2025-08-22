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
import glob
from sys import platform

# Check for a specific file in the user's home directory
stop_file = os.path.expanduser("~/stop_cookie_cleaning.txt")
if os.path.exists(stop_file):
    sys.exit(0)

home_dir = os.path.expanduser('~')
run_clean = (len(sys.argv)> 1 and sys.argv[1] == '--clean')
whitelist_dir = f'{home_dir}/myconfig/cookies-whitelist.txt'
log_file = f'{home_dir}/cookies-whitelist-log.log'

def append_to_log(log_file, profile_name, deleted_rows, kept_rows):
    current_date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_line = f"{current_date} - Profile: {profile_name} - Deleted: {len(deleted_rows)} cookies, Kept: {len(kept_rows)} cookies\n"
    if deleted_rows:
        log_line += f"  Deleted domains: {', '.join(deleted_rows[:10])}" + ("..." if len(deleted_rows) > 10 else "") + "\n"
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

def get_all_db_paths():
    chrome_profiles = []
    
    if platform == 'linux' or platform == 'linux2':
        chrome_dir = f'{home_dir}/.config/google-chrome'
        if os.path.exists(chrome_dir):
            # Find all profile directories that contain a Cookies file
            profile_paths = glob.glob(f'{chrome_dir}/*/Cookies')
            for path in profile_paths:
                profile_dir = os.path.dirname(path)
                profile_name = os.path.basename(profile_dir)
                chrome_profiles.append((profile_name, path))
    elif platform == 'darwin':
        chrome_dir = f'{home_dir}/Library/Application Support/Google/Chrome'
        if os.path.exists(chrome_dir):
            # Find all profile directories that contain a Cookies file
            profile_paths = glob.glob(f'{chrome_dir}/*/Cookies')
            for path in profile_paths:
                profile_dir = os.path.dirname(path)
                profile_name = os.path.basename(profile_dir)
                chrome_profiles.append((profile_name, path))
    
    return chrome_profiles

def remove_cookies_hosts(db_path, cookie_hosts_to_remove):
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

chrome_profiles = get_all_db_paths()
if not chrome_profiles:
    print('No Chrome profiles found')
    quit()

print(f"Found {len(chrome_profiles)} Chrome profiles")

total_deleted = 0
total_kept = 0

for profile_name, db_path in chrome_profiles:
    print(f"\nProcessing profile: {profile_name}")
    
    if not os.path.exists(db_path):
        print(f'  Database file not found: {db_path}')
        continue
    
    try:
        cookie_host_list = get_cookie_host_list(db_path)
        print(f"  Found {len(cookie_host_list)} cookie hosts")
        
        cookies_to_keep, cookie_hosts_to_remove = filter_strings(cookie_host_list, white_listed_lines)
        
        print(f"  Cookies to keep: {len(cookies_to_keep)}")
        print(f"  Cookies to remove: {len(cookie_hosts_to_remove)}")
        
        if run_clean:
            if cookie_hosts_to_remove:
                remove_cookies_hosts(db_path, cookie_hosts_to_remove)
                print(f"  ✓ Removed {len(cookie_hosts_to_remove)} cookie hosts")
            else:
                print(f"  ✓ No cookies to remove")
            append_to_log(log_file, profile_name, cookie_hosts_to_remove, cookies_to_keep)
        else:
            print(f"  --- DRY RUN: Would remove {len(cookie_hosts_to_remove)} cookie hosts")
            if cookie_hosts_to_remove:
                print(f"  --- Domains to be removed: {', '.join(cookie_hosts_to_remove[:5])}" + ("..." if len(cookie_hosts_to_remove) > 5 else ""))
        
        total_deleted += len(cookie_hosts_to_remove)
        total_kept += len(cookies_to_keep)
        
    except Exception as e:
        print(f"  Error processing profile {profile_name}: {str(e)}")
        continue

print(f"\n=== Summary ===")
print(f"Processed {len(chrome_profiles)} profiles")
print(f"Total cookies to keep: {total_kept}")
print(f"Total cookies {'removed' if run_clean else 'to remove'}: {total_deleted}")

if not run_clean:
    print("\nRun with --clean flag to actually remove cookies")
