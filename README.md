# hetzner-firewall-updater

Keeps a Hetzner Cloud firewall rule in sync with your current home IP. Useful when your ISP assigns a dynamic IP and you want to restrict server access to your home address only.

The container runs the update script once on startup, then again every day at 05:00 via cron. If the IP hasn't changed since the last run, nothing happens.

## How it works

1. Fetches your current public IPv4 from [ipify.org](https://api4.ipify.org)
2. Looks up the named firewall via the Hetzner Cloud API
3. Finds the rule identified by `RULE_DESCRIPTION`
4. Replaces its `source_ips` with `<current-ip>/32` — leaving all other rules untouched

## Prerequisites

- A Hetzner Cloud project with an existing firewall
- A firewall rule whose **description** matches `RULE_DESCRIPTION` exactly (e.g. `home-ip`)
- A Hetzner Cloud API token with **read + write** permissions
- Docker + Docker Compose

## Setup

### 1. Create the firewall rule in Hetzner Cloud

In the Hetzner Cloud console, open your firewall and add an inbound rule. Set the description to whatever you'll use as `RULE_DESCRIPTION` — that description is how the script finds the rule, so the two must match exactly. The source IP can be anything; the script overwrites it on first run.

### 2. Get an API token

Go to your Hetzner Cloud project → **Security** → **API Tokens** → **Generate API Token**. Select **Read & Write**.

### 3. Configure environment

All three variables are required — the container exits immediately if any is missing:

| Variable           | Required | Description                                                                |
| ------------------ | -------- | -------------------------------------------------------------------------- |
| `API_TOKEN`        | yes      | Hetzner Cloud API token (read+write)                                       |
| `FIREWALL_NAME`    | yes      | Exact name of the firewall to update                                       |
| `RULE_DESCRIPTION` | yes      | Description of the rule to update — must match the rule in Hetzner exactly |

**Set them in the compose file.** Write the values straight into the service's `environment:` block, as in `compose.example.yaml`:

```yaml
services:
  hetzner-ip-updater:
    image: ghcr.io/neonpimpz/hetzner-firewall-updater:latest
    restart: unless-stopped
    environment:
      - API_TOKEN=<your-api-token>
      - FIREWALL_NAME=<firewall-name>
      - RULE_DESCRIPTION=<firewall-rule-description>
```

This is the simplest option for a server or a Portainer stack.

**Pass them from your shell.** `compose.yaml` in this repo uses `${API_TOKEN:?...}` placeholders instead, so the values come from the environment you run `docker compose` in and never touch the file:

```bash
export API_TOKEN=your-token
export FIREWALL_NAME=your-firewall
export RULE_DESCRIPTION=home-ip
docker compose up -d
```

Or inline for a single run:

```bash
API_TOKEN=... FIREWALL_NAME=... RULE_DESCRIPTION=... docker compose up -d
```

Compose also picks up a `.env` next to `compose.yaml` and uses it to resolve those placeholders, if you prefer a file.

### 4. Run

```bash
docker compose up -d
```

`compose.yaml` builds the image from this checkout. To deploy without cloning the repo, use the prebuilt image from GHCR instead — copy `compose.example.yaml` to your server as `compose.yaml`, fill in the three values, and run the same command.

Logs are forwarded to Docker's stdout:

```bash
docker compose logs -f
```

## Files

| File                        | Purpose                                           |
| --------------------------- | ------------------------------------------------- |
| `update-hetzner-home-ip.sh` | Core script — fetches IP, diffs, updates firewall |
| `entrypoint.sh`             | Runs the script once on startup, then starts cron |
| `Dockerfile`                | Alpine-based image with `curl`, `jq`, and `bash`  |
| `compose.yaml`              | Compose service that builds the image locally     |
| `compose.example.yaml`      | Compose service that pulls the prebuilt image     |
