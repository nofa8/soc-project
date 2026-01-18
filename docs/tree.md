# Project Structure

> **Purpose:** Help developers and reviewers understand the SOC project layout.

---

## Directory Tree

```
soc-project/
├── README.md                 # Project overview & quick start
├── docker-compose.yml        # 14-service orchestration
├── Makefile                  # Orchestration layer (v4.1)
├── .env.example              # Environment template
│
├── attacks/                  # 🔴 Threat Stimulus Generation
│   ├── brute_force.sh        # Deterministic brute-force
│   ├── brute_force_hydra.sh  # Hydra-based (realistic, optional)
│   ├── sqli.sh               # SQL injection payloads
│   ├── vpn_noise.sh          # VPN UDP probes
│   └── firewall_scan.sh      # Blocked port attempts
│
├── scripts/                  # 🔵 Verification & Health Checks
│   ├── check_alert.sh        # Detection assertion (ES query)
│   ├── check_pipeline.sh     # SIEM pipeline health
│   └── lib/                  # Shared primitives (NO logic)
│       ├── timing.sh         # Backoff utilities
│       └── colors.sh         # Terminal UX
│
├── backend-fastapi/          # 🟢 Application Layer
│   ├── main.py               # FastAPI with security logging
│   ├── requirements.txt      # Python dependencies
│   └── Dockerfile            # Container build
│
├── nginx/                    # 🟢 Reverse Proxy
│   └── nginx.conf            # JSON access logs, security headers
│
├── keycloak/                 # 🔐 Identity Provider
│   └── import/               # Realm configuration
│       └── safepay_realm.json
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
│   └── firewall-log-export.service  # Systemd bridge service
│
├── filebeat/                 # 📤 Log Shipper
│   └── filebeat.yml          # ES output configuration
│
├── vpn/                      # 🔐 Remote Access
│   └── config/               # WireGuard peer configs (auto-generated)
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
│   ├── architecture.md       # Design rationale (NEW)
│   ├── debug.md              # Troubleshooting guide
│   ├── limitations.md        # Architectural constraints
│   ├── test-results.md       # Latest test output
│   ├── tests.md              # Testing methodology
│   ├── tree.md               # This file
│   └── vulnerabilities.md    # Intentional vulns
│
└── State.md                  # Project status
```

---

## Key Directories

### `attacks/`
Threat stimulus scripts. Each generates controlled attack traffic for detection validation. **Red team tooling.**

### `scripts/`
Verification and health check scripts. Used by Makefile to assert detection. **Blue team tooling.**

### `scripts/lib/`
Shared primitives only. No logic, no queries, no assertions. Only timing and UX helpers.

### `backend-fastapi/`
The vulnerable application with security logging. Generates JSON events for login attempts, SQL injection detection, and privilege escalation.

### `wazuh/`
Contains custom detection rules (IDs 100xxx). These rules correlate events from API logs, Suricata, and firewall to detect attacks.

### `keycloak/`
Identity provider configuration. Manages SSO for Kibana and API authentication.

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
| `Makefile` | Orchestration layer | Adding new test targets |
| `wazuh/custom-rules.xml` | Detection rules | Adding new alerts |
| `suricata/rules/local.rules` | IDS signatures | Adding network detection |

---

## Log Flow

```
Application → logs/api/security.json → Wazuh Agent → Manager → ES
Nginx      → logs/nginx/access.log  → Wazuh Agent → Manager → ES  
Suricata   → logs/suricata/eve.jsonl → Wazuh Agent → Manager → ES
Firewall   → /var/log/firewall/      → Wazuh Agent → Manager → ES
           (via systemd export service)
```

---

## What NOT to Modify

| Path | Reason |
|------|--------|
| `logs/` | Runtime data, auto-generated |
| `vpn/config/` | Auto-generated WireGuard keys |
| `.git/` | Version control |
| `pcap/` | Optional PCAP captures |
