#!/bin/sh

# Run once immediately on startup
/usr/local/bin/update-hetzner-home-ip.sh

# Start cron in the foreground
crond -f -l 2