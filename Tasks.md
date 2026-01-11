# SOC Project – Task Tracking & Implementation Guide

> **Project Goal:** Build a proportionate, SOC-oriented cybersecurity prototype capable of generating, correlating, and analyzing security events using a SIEM.

---

## Current Status: Phase 1 Complete ✅ | Phase 2 In Progress 🔄

---

## Phase Overview

| Phase | Description | Grading Criteria | Status |
|-------|-------------|------------------|--------|
| **1** | Core Infrastructure & Telemetry | 20% - IT Prototype | ✅ Complete |
| **2** | SIEM Integration | 20% - SIEM Parameterization | 🔄 In Progress |
| **3** | Vulnerabilities & Exposure | 20% - Security Info Generation | ⏳ Pending |
| **4** | Attack Execution | Step 3 + Step 4 Evidence | ⏳ Pending |
| **5** | Dashboards & Reports | 15% - Events/Alerts/Reports | ⏳ Pending |
| **6** | Documentation & Delivery | 5% Report + 20% Defense | ⏳ Pending |

---

## ✅ Phase 1 – Core Infrastructure & Telemetry (Complete)

*Establishes foundation: services exist, logs are generated, telemetry is trustworthy.*

### 1.1 Infrastructure Setup

| Task | Status | Evidence |
|------|--------|----------|
| Docker Compose stack (7 services) | ✅ | `docker-compose.yml` |
| SELinux volume labeling (`:z`) | ✅ | Required for Fedora/RHEL hosts |
| Service networking & dependencies | ✅ | Proxy → API → DB/LDAP |

**Why this matters:** Satisfies **20% – Prototype of corporate IT infrastructure**

---

### 1.2 Backend API (FastAPI)

| Task | Status | Evidence |
|------|--------|----------|
| Login endpoint with security logging | ✅ | `login_failed`, `login_success` events |
| Resource endpoint with SQLi detection | ✅ | `possible_sqli` logged |
| Structured JSON logging | ✅ | `logs/api/security.json` |
| Request middleware with UUID | ✅ | Enables multi-log correlation |

**Why this matters:** Core of **Step 3 – Generation of security information (20%)**

---

### 1.3 Nginx Reverse Proxy

| Task | Status | Evidence |
|------|--------|----------|
| Reverse proxy to API | ✅ | `nginx.conf` |
| JSON access logs | ✅ | `logs/nginx/access.log` |
| Security headers | ✅ | Defense-in-depth |

**Why this matters:** Enables **layered detection** (network + application)

---

### 1.4 Suricata IDS

| Task | Status | Evidence |
|------|--------|----------|
| Custom configuration | ✅ | `suricata/suricata.yaml` |
| Network interface setup | ✅ | Captures host traffic |
| Baseline rules (ICMP, HTTP) | ✅ | `suricata/rules/local.rules` |

**Why this matters:** Provides **network-layer telemetry** for cross-layer correlation

---

### 1.5 Wazuh SIEM Manager

| Task | Status | Evidence |
|------|--------|----------|
| Manager container | ✅ | Running on ports 1514, 55000 |
| ossec.conf configured | ✅ | `wazuh/ossec.conf` |
| Custom rules staged | ⚠️ | File exists but empty |

**Why this matters:** The **central SOC intelligence layer**

---

### 1.6 Filebeat Log Shipper

| Task | Status | Evidence |
|------|--------|----------|
| Input config (API, Nginx, Suricata) | ✅ | `filebeat/filebeat.yml` |
| Output pipeline | ⚠️ | Not yet finalized |

**Why this matters:** Bridge between **Step 3 and Step 4**

---

## 🔄 Phase 2 – SIEM Integration (In Progress)

*Connects telemetry to analysis and visualization.*

### 2.1 Elasticsearch + Kibana Stack

| Task | Status | Priority |
|------|--------|----------|
| Add Elasticsearch to docker-compose | ⏳ | **HIGH** |
| Add Kibana to docker-compose | ⏳ | **HIGH** |
| Configure index templates | ⏳ | Medium |

**Why this matters:** Required for dashboards, mandatory for **15% events/alerts/reports**

---

### 2.2 Filebeat Pipeline

| Task | Status | Notes |
|------|--------|-------|
| Decide: Filebeat → Wazuh vs → Elasticsearch | ⏳ | Recommend ES for dashboards |
| Configure Filebeat output | ⏳ | After ES is running |
| Validate log ingestion | ⏳ | Check index patterns |

---

### 2.3 Wazuh Detection Rules

| Task | Status | Rule Logic |
|------|--------|-----------|
| Brute force detection | ⏳ | >5 failures / 60 seconds |
| SQLi pattern detection | ⏳ | Regex match in URL/payload |
| Privilege abuse detection | ⏳ | Role mismatch check |
| API abuse detection | ⏳ | Request threshold |

---

### 2.4 Initial Dashboards

| Task | Status | Purpose |
|------|--------|---------|
| Raw events view | ⏳ | Confirm ingestion |
| Basic alert summary | ⏳ | Validate rules fire |

---

## ⏳ Phase 3 – Vulnerabilities & Exposure

*Must come AFTER SIEM is ingesting logs.*

### 3.1 Application Vulnerabilities

| Vulnerability | Endpoint | Detection Method |
|--------------|----------|------------------|
| Broken Authorization | `GET /admin` | API + Auth logs |
| SQL Injection (real) | `GET /items/` | DB + App logs |
| Brute Force Target | `POST /login` | Auth logs + Wazuh |

### 3.2 Tasks

| Task | Status | Evidence Produced |
|------|--------|-------------------|
| Implement admin endpoint | ⏳ | Application logs |
| Enable vulnerable DB queries | ⏳ | Database logs |
| Disable rate limiting on login | ⏳ | Authentication failures |

---

## ⏳ Phase 4 – Attack Execution

*Generate proof, not code. This produces grading evidence.*

### 4.1 Attack Scenarios

| Attack | Tool | Detection Layer |
|--------|------|-----------------|
| Port Scanning | nmap | Suricata IDS |
| Brute Force | Hydra | Wazuh + Auth logs |
| SQL Injection | sqlmap | App + DB + Suricata |
| API Abuse | curl/script | Nginx + App logs |

### 4.2 Evidence Produced

- Raw logs (all sources)
- Correlated alerts (Wazuh)
- Cross-layer detection proof

**Why this matters:** Fulfills **Step 3 + Step 4** together

---

## ⏳ Phase 5 – Dashboards & Reports

*This is 15% of grade and a presentation booster.*

### 5.1 Dashboards

| Dashboard | Data Source | Purpose |
|-----------|-------------|---------|
| Authentication Anomalies | API logs | Failed login patterns |
| Network Intrusions | Suricata EVE | IDS alerts timeline |
| Application Security | API + Nginx | SQLi, errors, abuse |
| Incident Timeline | All sources | Correlated view |

### 5.2 Reports

| Report | Format | Content |
|--------|--------|---------|
| Daily Security Summary | PDF | Aggregate stats |
| Incident Report | PDF | Attack narrative |
| Alert Correlation | PDF | Cross-layer analysis |

---

## ⏳ Phase 6 – Documentation & Delivery

*Supports 5% report + 20% defense.*

### 6.1 Technical Documentation

| Document | Status | Purpose |
|----------|--------|---------|
| README.md | ✅ | Deployment + demo |
| Architecture diagram | ⏳ | Logical + physical |
| Attack demo guide | ⏳ | Step-by-step proof |

### 6.2 Academic Deliverables

| Document | Status | Grading Weight |
|----------|--------|----------------|
| Final report | ⏳ | 5% |
| Presentation | ⏳ | 20% defense |
| Live demo script | ⏳ | Demo readiness |

---

## ⚠️ Known Issues

### 1. Filebeat → Wazuh Port Confusion

- **Issue:** Port 1514 uses Wazuh agent protocol, not Logstash
- **Fix:** Route Filebeat → Elasticsearch, Wazuh reads from ES
- **Status:** Will resolve in Phase 2

### 2. Elasticsearch/Kibana Missing

- **Issue:** Not yet in docker-compose
- **Fix:** Add in Phase 2
- **Priority:** **HIGH** - Blocking dashboards

### 3. WireGuard VPN

- **Status:** Optional
- **Action:** Mention conceptually in report, not required for full marks

---

## Work Dependencies

### Sequential (Must Follow Order)

```
Logging → SIEM Ingestion → Attacks → Dashboards
```

### Parallel (Can Do Simultaneously)

- Documentation writing
- Architecture diagrams  
- Dashboard design concepts
- Attack script preparation

---

## Next Recommended Step

**Phase 2 – Add Elasticsearch + Kibana + Finalize Filebeat Pipeline**

This unblocks:
- Dashboard creation
- Alert visualization
- Report generation
- Attack evidence capture
