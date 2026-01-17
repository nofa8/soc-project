# Project Structure

> **Purpose:** Help developers and reviewers understand the SOC project layout.

---

## Directory Tree

```
soc-project/
├── README.md                 # Project overview & quick start
├── docker-compose.yml        # 13-service orchestration
├── Makefile                  # Automated testing & operations
├── .env.example              # Environment template
│
├── backend-fastapi/          # 🔵 Application Layer
│   ├── main.py               # FastAPI with security logging
│   ├── requirements.txt      # Python dependencies
│   └── Dockerfile            # Container build
│
├── nginx/                    # 🔵 Reverse Proxy
│   └── nginx.conf            # JSON access logs, security headers
│
├── config/                   # ⚙️ Configuration
│   ├── agent/                # Wazuh agent ossec.conf
│   └── wazuh_cluster/        # Wazuh manager config
│
├── wazuh/                    # 🛡️ SIEM Rules
│   ├── custom-rules.xml      # Detection rules (100xxx)
│   └── local_internal_options.conf
│
├── suricata/                 # 🔍 IDS Configuration
│   ├── suricata.yaml         # IDS settings
│   ├── rules/                # Custom Suricata rules
│   └── entrypoint.sh         # Rule update on start
│
├── firewall/                 # 🧱 Perimeter Security
│   ├── apply_rules.sh        # iptables rules with logging
│   └── 10-firewall.conf      # rsyslog config (optional)
│
├── filebeat/                 # 📤 Log Shipper
│   └── filebeat.yml          # ES output configuration
│
├── vpn/                      # 🔐 Remote Access
│   └── config/               # WireGuard peer configs
│
├── scripts/                  # 🔧 Utilities
│   └── *.sh                  # Helper scripts
│
├── tests/                    # 🧪 Test Scripts
│   └── verify-wazuh-rules.sh # Rule validation
│
├── logs/                     # 📋 Log Output (git-ignored)
│   ├── api/                  # FastAPI security logs
│   ├── nginx/                # Access/error logs
│   └── suricata/             # EVE JSON alerts
│
├── docs/                     # 📚 Documentation
│   ├── debug.md              # Troubleshooting guide
│   ├── limitations.md        # Architectural constraints
│   ├── test-results.md       # Latest test output
│   ├── tests.md              # Testing methodology
│   ├── tree.md               # This file
│   └── vulnerabilities.md    # Intentional vulns
│
├── State.md                  # Project status
└── Tasks.md                  # Development phases
```

---

## Key Directories

### `backend-fastapi/`
The vulnerable application with security logging. Generates JSON events for login attempts, SQL injection detection, and privilege escalation.

### `wazuh/`
Contains custom detection rules (IDs 100xxx). These rules correlate events from API logs, Suricata, and firewall to detect attacks.

### `config/`
Agent and manager OSSEC configurations. The agent config determines which log files are monitored.

### `logs/`
Centralized log directory mounted into containers. **Do not commit this folder** - it's git-ignored.

### `docs/`
All project documentation. See the Documentation Index in README.md.

---

## Configuration Files

| File | Purpose | Edit When |
|------|---------|-----------|
| `.env` | Environment variables | Setting interface, ports |
| `docker-compose.yml` | Service definitions | Adding/modifying containers |
| `Makefile` | Test automation | Adding new test targets |
| `wazuh/custom-rules.xml` | Detection rules | Adding new alerts |
| `suricata/rules/local.rules` | IDS signatures | Adding network detection |

---

## Log Flow

```
Application → logs/api/security.json → Wazuh Agent → Manager → ES
Nginx      → logs/nginx/access.log  → Wazuh Agent → Manager → ES  
Suricata   → logs/suricata/eve.jsonl → Wazuh Agent → Manager → ES
Firewall   → journald (host)         → [requires host agent]
```

---

## What NOT to Modify

| Path | Reason |
|------|--------|
| `logs/` | Runtime data, auto-generated |
| `vpn/config/` | Auto-generated WireGuard keys |
| `.git/` | Version control |
| `pcap/` | Optional PCAP captures |
