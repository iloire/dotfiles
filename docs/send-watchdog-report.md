# send-watchdog-report

Collects server health metrics (disk, memory, CPU, services) and sends them to the [Devil Watchdog](https://devilwatchdog.vercel.app) server report API.

## Requirements

- `curl`
- `WATCHDOG_API_KEY` environment variable set (in `~/dotfiles/shell/local-overrides`)
- Hostname registered in the Devil Watchdog dashboard (must match `hostname` output, without `.local` suffix)

## Usage

```bash
send-watchdog-report          # silent mode (for cron)
send-watchdog-report -v       # verbose output
```

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `WATCHDOG_API_KEY` | Yes | API key (`dw_...`) from Devil Watchdog dashboard |
| `WATCHDOG_SERVICES` | No | Comma-separated services to monitor (e.g. `nginx,docker,postgres`) |

## Metrics collected

- **Disk**: mount point, total/used bytes, usage percentage (filters out tmpfs, devfs, snap, macOS system volumes)
- **Memory**: total, used, available, swap total/used
- **CPU**: usage percentage, load averages (1m, 5m, 15m), core count
- **Services**: running status of systemd services (Linux) or processes (macOS)

## Ansible deployment

The cron job is defined in the `crontab` role (`ansible-recipes/roles/crontab/tasks/main.yml`) and runs every 5 minutes.

To deploy on a new machine:

1. Register the machine's hostname in the Devil Watchdog dashboard (run `hostname` to check the exact name)
2. Ensure `WATCHDOG_API_KEY` is set in `~/dotfiles/shell/local-overrides` on the target machine
3. Run:
   ```bash
   ansible-playbook desktop-ubuntu.yml --tags dotfiles,crontab
   ```

## Logs

Errors are logged to `~/.watchdog-report.log`. The script always exits 0 to avoid breaking cron.
