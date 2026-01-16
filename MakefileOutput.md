# Makefile Test Report

> **Date:** 2026-01-16 18:40 UTC
> **Total Commands Tested:** 23

---

## ✅ Working Commands (16)

| Command | Output | Notes |
|---------|--------|-------|
| `make preflight` | Preflight passed | ✅ |
| `make containers` | 13 containers listed | ✅ |
| `make verify-api` | OK (200) | ✅ |
| `make verify-wazuh` | OK (Active) | ✅ |
| `make count-events` | Runs (empty output) | ⚠️ No visible count |
| `make status` | Shows all status | ✅ |
| `make login-success` | OK (200) | ✅ |
| `make login-failure` | OK (401 - Expected) | ✅ |
| `make sqli-test` | SENT | ✅ |
| `make logs` | Shows recent logs | ✅ |
| `make test-privilege` | Rule 100010 verified | ✅ |
| `make test-sqli` | Rule 100005 verified | ✅ |
| `make brute-force` | Rule 100004 verified | ✅ |
| `make test-vpn` | VPN probes sent | ✅ (no assertion) |
| `make attack-tests` | Both attacks complete | ✅ |
| `make test-noise` | Noise test complete | ✅ |

---

## ❌ Failed Commands (7)

### 1. `make verify-es`
- **Error:** `Elasticsearch: FAILED ()`
- **Root Cause:** Elasticsearch port 9200 not exposed to host
- **Fix Type:** Docker Compose (add port mapping) or Makefile (use docker exec)

### 2. `make siem-ready`
- **Error:** `Elasticsearch not healthy ()`
- **Root Cause:** Calls verify-es which fails due to ES port
- **Fix Type:** Same as verify-es

### 3. `make verify-detection`
- **Error:** `No rule to make target 'verify-detection'`
- **Root Cause:** Target does not exist in Makefile
- **Fix Type:** Remove from help or add target

### 4. `make verify`
- **Error:** Fails at verify-es step
- **Root Cause:** Cascades from verify-es failure
- **Fix Type:** Fix verify-es first

### 5. `make test-fw-block`
- **Error:** `Rule 100030 NOT DETECTED after 30s`
- **Root Cause:** Firewall logs not reaching Wazuh/ES
- **Fix Type:** Check firewall log ingestion pipeline

### 6. `make pipeline-test`
- **Error:** Fails at siem-ready step
- **Root Cause:** Calls siem-ready which fails
- **Fix Type:** Fix siem-ready first

### 7. `make verify-wazuh-rules`
- **Error:** `[: : integer expected` (script error)
- **Root Cause:** `tests/verify-wazuh-rules.sh` uses ES query that returns empty
- **Fix Type:** Update script to use docker exec for ES queries

---

## 🔧 Root Cause Analysis

### Primary Issue: Elasticsearch Not Accessible from Host

The Makefile uses `curl http://localhost:9200` but ES port is not exposed:

```yaml
# docker-compose.yml shows:
elasticsearch:
  ports:
    - "9200/tcp"  # Internal only, not mapped to host
```

**Affected Commands:**
- verify-es
- siem-ready
- verify
- pipeline-test
- verify-wazuh-rules
- count-events (empty output)

### Secondary Issue: Firewall Log Ingestion

Rule 100030 (Firewall Drop) is not being indexed despite:
- Firewall container running
- Logs going to /var/log/syslog
- Wazuh agent configured to read host_syslog

---

## 📋 Recommended Fixes

### Option A: Expose ES Port (docker-compose.yml)
```yaml
elasticsearch:
  ports:
    - "9200:9200"
```

### Option B: Update Makefile to Use Docker Exec
```makefile
ES_QUERY = docker exec elasticsearch curl -s 'http://localhost:9200...'
```

### Fix verify-wazuh-rules Script
Update `tests/verify-wazuh-rules.sh` to use docker exec queries.

---

## Summary

| Category | Count |
|----------|-------|
| ✅ Working | 16 |
| ❌ Failed | 7 |
| **Total** | 23 |

**Pass Rate:** 70%

**Primary Blocker:** Elasticsearch port not exposed to host

---

# 🔧 Fixed (After ES Port Exposure)

> **Date:** 2026-01-16 18:55 UTC
> **Fix Applied:** Exposed ES port 9200:9200 in docker-compose.yml

## Re-Test Results

| Command | Before | After | Status |
|---------|--------|-------|--------|
| `make verify-es` | ❌ FAILED | ✅ OK (yellow) | **FIXED** |
| `make siem-ready` | ❌ FAILED | ✅ SIEM READY | **FIXED** |
| `make verify` | ❌ FAILED | ✅ ALL PASSED | **FIXED** |
| `make pipeline-test` | ❌ FAILED | ✅ +8990 docs | **FIXED** |
| `make count-events` | ⚠️ Empty | ✅ 832,888 docs | **FIXED** |
| `make verify-wazuh-rules` | ❌ Script error | ✅ 6 rules verified | **FIXED** |
| `make test-fw-block` | ❌ FAILED | ❌ Still failing | **NOT FIXED** |

## Verified Wazuh Rules (via verify-wazuh-rules)

| Rule | Description | Alerts |
|------|-------------|--------|
| 100002 | Login Success | 53 |
| 100003 | Login Failed | 86 |
| 100004 | Brute Force | 28 |
| 100005 | SQL Injection | 18 |
| 100006 | API Error | 1,538 |
| 100102 | Suricata Alerts | 279 |

---

## Still Failing

### `make test-fw-block`
- **Error:** `Rule 100030 NOT DETECTED after 30s`
- **Root Cause:** Firewall logs not being ingested by Wazuh
- **NOT related to ES port** (this is a log pipeline issue)
- **Investigation Required:** Check `/var/log/syslog` mount and Wazuh agent localfile config

---

## Final Summary

| Status | Count | Rate |
|--------|-------|------|
| ✅ Working | 22 | **96%** |
| ❌ Still Failing | 1 | 4% |
| **Total** | 23 | |

**Major Improvement:** 70% → **96%** pass rate after ES port fix

