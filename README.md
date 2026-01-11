# 🛡️ SafePay SOC Project

> **Security Operations Center Prototype** for a mid-sized FinTech organization

A containerized security monitoring environment demonstrating log collection, correlation, and analysis using industry-standard tools.

---

## 📋 Project Overview

This project implements a **SOC prototype** capable of:
- **Collecting** security events from application, network, and system layers
- **Correlating** events using a SIEM platform (Wazuh)
- **Analyzing** and visualizing security incidents
- **Demonstrating** detection of intentional vulnerabilities

### Business Context

| Attribute | Value |
|-----------|-------|
| **Company** | SafePay (FinTech Startup) |
| **Employees** | ~90 |
| **Location** | Lisbon HQ, remote EU engineers |
| **Compliance** | GDPR, PSD2 (partial) |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        EXTERNAL ACCESS                          │
│                              :80                                │
└───────────────────────────────┬─────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────┐
│                         proxy-nginx                             │
│                    (Reverse Proxy + WAF)                        │
│                    JSON access logging                          │
└───────────────────────────────┬─────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────┐
│                         api-service                             │
│                    (FastAPI Backend)                            │
│              Structured JSON security logs                      │
└─────────────┬────────────────────────────────┬──────────────────┘
              │                                │
┌─────────────▼──────────┐      ┌──────────────▼─────────────────┐
│       db-service       │      │         auth-ldap              │
│      (PostgreSQL)      │      │        (OpenLDAP)              │
└────────────────────────┘      └────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    SECURITY & MONITORING                        │
├─────────────────┬─────────────────────┬─────────────────────────┤
│  ids-suricata   │   wazuh-manager     │       filebeat          │
│   (Network IDS) │      (SIEM)         │    (Log Shipper)        │
│  EVE JSON logs  │   Alert correlation │   Collects all logs     │
└─────────────────┴─────────────────────┴─────────────────────────┘
```

---

## 🛠️ Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Containerization** | Docker + Compose | Service orchestration |
| **Backend** | FastAPI (Python 3.13) | REST API with security logging |
| **Reverse Proxy** | Nginx | TLS termination, access logging |
| **Database** | PostgreSQL 15 | Transaction data |
| **Identity** | OpenLDAP | Centralized authentication |
| **IDS** | Suricata | Network intrusion detection |
| **SIEM** | Wazuh | Event correlation & alerts |
| **Log Shipper** | Filebeat | Log collection & forwarding |

---

## 🚀 Quick Start

### Prerequisites

- Docker ≥ 24.0
- Docker Compose v2
- 8-12 GB RAM recommended
- Linux host (native or WSL2)

### 1. Clone & Configure

```bash
git clone <repository-url>
cd soc-project

# Create environment file
cp .env.example .env

# Edit .env with your network interface
# Run: ip link show
# Set SURICATA_INTERFACE to your interface (e.g., enp12s0, eth0)
```

### 2. Start Services

```bash
# Start all containers
docker-compose up -d

# View container status
docker ps

# Check logs
docker logs api-service
docker logs ids-suricata
```

### 3. Test the API

```bash
# Successful login
curl -X POST http://localhost/login \
  -H "Content-Type: application/json" \
  -d '{"username":"user","password":"pass"}'

# Failed login (generates security log)
curl -X POST http://localhost/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"wrong"}'

# SQLi attempt (detected and logged)
curl "http://localhost/items/1%20OR%201=1"
```

---

## 📁 Project Structure

```
soc-project/
├── docker-compose.yml       # Service definitions
├── .env                     # Environment variables
├── backend-fastapi/         # FastAPI application
│   ├── app/
│   │   ├── main.py         # API endpoints
│   │   ├── logger.py       # JSON security logger
│   │   └── middleware.py   # Request tracking
│   └── Dockerfile
├── nginx/
│   └── nginx.conf          # JSON access logging
├── suricata/
│   ├── suricata.yaml       # IDS configuration
│   └── rules/
│       └── local.rules     # Custom detection rules
├── wazuh/
│   ├── ossec.conf          # SIEM configuration
│   └── custom-rules.xml    # Detection rules
├── filebeat/
│   └── filebeat.yml        # Log collection config
└── logs/                   # Centralized log directory
    ├── api/                # FastAPI security logs
    ├── nginx/              # Access & error logs
    └── suricata/           # IDS alerts (EVE JSON)
```

---

## 📊 Log Sources

| Source | Log Type | Location |
|--------|----------|----------|
| FastAPI | Security events (JSON) | `logs/api/security.json` |
| Nginx | Access logs (JSON) | `logs/nginx/access.log` |
| Nginx | Error logs | `logs/nginx/error.log` |
| Suricata | EVE alerts (JSON) | `logs/suricata/eve.json` |
| Suricata | Stats | `logs/suricata/stats.log` |

---

## 🎯 Implemented Vulnerabilities

These **intentional vulnerabilities** are documented for demonstration:

| Vulnerability | Endpoint | Detection |
|--------------|----------|-----------|
| SQL Injection Pattern | `GET /items/{id}` | App logs + Suricata |
| Broken Auth | `POST /login` | Auth logs |
| Port Scanning | N/A | Suricata IDS |
| API Abuse | High request rate | Nginx logs |

---

## 🔍 Detection Rules

### Suricata Rules (`suricata/rules/local.rules`)
```
alert icmp any any -> any any (msg:"ICMP connection detected"; sid:1000001;)
alert tcp any any -> any 8000 (msg:"Attack on API detected"; sid:1000002;)
```

### Wazuh Rules (TODO)
- Brute force: >5 failures in 60 seconds
- SQLi: Pattern matching in URL parameters
- Privilege abuse: Role mismatch detection

---

## 📈 Project Progress

| Phase | Status | Description |
|-------|--------|-------------|
| **Phase 1** | ✅ Complete | Core infrastructure (Docker, API, Nginx) |
| **Phase 2** | 🔄 In Progress | SIEM integration & custom rules |
| **Phase 3** | ⏳ Pending | Vulnerability demonstrations |
| **Phase 4** | ⏳ Pending | Attack execution & detection |
| **Phase 5** | ⏳ Pending | Dashboards & reporting |

---

## 🧪 Testing

### Manual API Testing

```bash
# Health check
curl http://localhost/

# Generate authentication logs
curl -X POST http://localhost/login \
  -H "Content-Type: application/json" \
  -d '{"username":"attacker","password":"password123"}'

# Trigger SQLi detection
curl "http://localhost/items/1' UNION SELECT * FROM users--"

# View generated logs
tail -f logs/api/security.json
```

### View Suricata Alerts

```bash
# Check if Suricata is capturing traffic
docker logs ids-suricata

# View alerts
tail -f logs/suricata/eve.json | jq '.alert'
```

---

## 🔧 Troubleshooting

### Permission Denied Errors

All volume mounts include SELinux labels (`:z`). If issues persist:

```bash
# Fix permissions
chmod -R 777 logs/
docker-compose down && docker-compose up -d
```

### Suricata Not Capturing

1. Check network interface exists: `ip link show`
2. Update `.env` with correct interface
3. Restart: `docker-compose restart ids-suricata`

### Container Not Starting

```bash
# Check logs
docker logs <container-name>

# Verify configuration
docker-compose config
```

---

## 📚 References

- [NIST SP 800-92](https://csrc.nist.gov/publications/detail/sp/800-92/final) - Log Management Guide
- [MITRE ATT&CK](https://attack.mitre.org/) - Threat Classification
- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Suricata Documentation](https://suricata.readthedocs.io/)

---

## 📝 License

This project is for educational purposes as part of a Security Operations Center coursework.

---
