# SOC Project – State Report

> **Audit Date:** 2026-01-13  
> **Purpose:** Document current project state, identify errors, and define cleanup actions

---

## Executive Summary

| Metric | Value |
|--------|-------|
| **Total Containers** | 9 (excluding unrelated) |
| **Healthy** | 6 ✅ |
| **Erroring** | 3 ❌ |
| **Orphaned Files** | 5 |
| **Config Issues** | 4 |

---

## Container Health Status

| Container | Status | Health |
|-----------|--------|--------|
| api-service | Up | ✅ Healthy |
| proxy-nginx | Up | ✅ Healthy |
| db-service | Up | ✅ Healthy |
| auth-ldap | Up | ✅ Healthy |
| elasticsearch | Up (healthy) | ✅ Healthy |
| kibana | Up | ✅ Healthy |
| wazuh-manager | Up | ⚠️ HTTPS/HTTP mismatch in logs |
| wazuh-agent | Up | ❌ **CRITICAL** - Config error |
| filebeat | Up | ⚠️ No files being harvested |
| ids-suricata | **Exited (1)** | ❌ **CRITICAL** - Wrong interface |

---

## Critical Errors

### 1. ids-suricata – Wrong Network Interface

**Error:**
```
Error: af-packet: enp0s3: failed to find interface: No such device
```

**Cause:** `.env` file specifies `enp0s3` but system has `enp12s0`

**Fix:** Update `.env` file:
```bash
SURICATA_COMMAND="-i enp12s0"
```

---

### 2. wazuh-agent – Invalid Configuration

**Error:**
```
ERROR: (1235): Invalid value for element 'port': CHANGE_MANAGER_PORT.
ERROR: (1215): No client configured. Exiting.
```

**Cause:** Agent config has unresolved placeholder `CHANGE_MANAGER_PORT`

**Location:** Likely in Docker image default or incorrect `ossec.conf` override

**Fix:** Ensure `config/agent/ossec.conf` is correctly mounted and contains:
```xml
<port>1514</port>
```

---

### 3. wazuh-manager – HTTPS/HTTP Protocol Mismatch

**Error (from logs, attributed wrongly):**
```
Get "https://wazuh.indexer:9200": http: server gave HTTP response to HTTPS client
```

**Cause:** This error is from Wazuh Manager internal Filebeat trying to connect to Elasticsearch with HTTPS, but ES has security disabled (HTTP only)

**Note:** This is actually Wazuh Manager's internal log forwarding, NOT the Filebeat container

**Fix:** Configure Wazuh Manager to use HTTP for indexer connection, or disable internal Filebeat

---

### 4. filebeat – No Active Harvesters

**Observation:**
```json
"harvester": {"open_files": 0, "running": 0}
```

**Cause:** Either log files don't exist or paths are wrong

**Issues Found:**
- `eve.jsonl` referenced but file is `eve.json`
- Wazuh alerts path may not have data yet

---

## Configuration Cleanup Needed

### Orphaned/Duplicate Files in `wazuh/` Directory

| File | Status | Action |
|------|--------|--------|
| `Dockerfile` | Unused | DELETE |
| `agent_entrypoint.sh` | Unused | DELETE |
| `agent_ossec.conf` | Duplicate (same as `config/agent/ossec.conf`) | DELETE |
| `custom-rules.xml.bak` | Backup file | DELETE |
| `custom-rules.yml` | Wrong format | DELETE |
| `ossec.conf` | Old config (replaced by `config/wazuh_cluster/`) | DELETE |

### Files to Keep in `wazuh/`

| File | Purpose |
|------|---------|
| `custom-rules.xml` | Custom detection rules (active) |
| `local_internal_options.conf` | Wazuh internal settings |

---

### Scattered Configuration Locations

**Current State (Confusing):**
```
config/
├── agent/
│   └── ossec.conf          # Agent config
└── wazuh_cluster/
    └── wazuh_manager.conf  # Manager config

wazuh/
├── custom-rules.xml        # Active
├── ossec.conf              # OLD - should delete
├── agent_ossec.conf        # DUPLICATE - should delete
└── ... (other orphans)
```

**Proposed Clean State:**
```
config/
├── agent/
│   └── ossec.conf
└── wazuh_manager/
    ├── ossec.conf
    └── custom-rules.xml
```

---

## Other Issues Found

### 1. Suricata EVE File Extension

- **Filebeat expects:** `/logs/suricata/eve.jsonl`
- **Suricata creates:** `/logs/suricata/eve.json`

**Fix:** Update `filebeat/filebeat.yml` line 23:
```yaml
- /logs/suricata/eve.json   # was eve.jsonl
```

### 2. Orphaned Root-Level Files

| File | Purpose | Action |
|------|---------|--------|
| `brute_force.sh` | Test script | KEEP (move to `scripts/`) |
| `client.keys` | Old Wazuh key | DELETE if unused |
| `manual_alert.json` | Test data | KEEP (move to `scripts/`) |

---

## Cleanup Action Plan

### Phase 1: Fix Critical Errors (Immediate)

1. **Fix Suricata interface**
   - Update `.env`: `SURICATA_COMMAND="-i enp12s0"`
   - Restart: `docker-compose restart ids-suricata`

2. **Fix Wazuh Agent config**
   - Verify `config/agent/ossec.conf` has correct port (1514)
   - Ensure no placeholder values exist
   - Rebuild: `docker-compose up -d --force-recreate wazuh-agent`

3. **Fix Filebeat paths**
   - Change `eve.jsonl` → `eve.json` in `filebeat/filebeat.yml`
   - Restart: `docker-compose restart filebeat`

### Phase 2: Clean Orphaned Files

```bash
# Remove orphaned wazuh files
rm wazuh/Dockerfile
rm wazuh/agent_entrypoint.sh
rm wazuh/agent_ossec.conf
rm wazuh/custom-rules.xml.bak
rm wazuh/custom-rules.yml
rm wazuh/ossec.conf

# Clean root orphans
rm client.keys

# Organize scripts
mkdir -p scripts
mv brute_force.sh scripts/
mv manual_alert.json scripts/
```

### Phase 3: Reorganize Config Structure (Optional)

Consider moving all Wazuh configs to single directory for clarity.

---

## Verification Commands

After cleanup, verify with:

```bash
# Check all containers running
docker ps -a --format "table {{.Names}}\t{{.Status}}"

# Check Suricata capturing
docker logs ids-suricata 2>&1 | tail -5

# Check Wazuh agent connected
docker logs wazuh-agent 2>&1 | grep -i "connected\|error"

# Check Filebeat harvesting
docker logs filebeat 2>&1 | grep "harvester"

# Test API
curl -X POST http://localhost/login -H "Content-Type: application/json" -d '{"username":"test","password":"test"}'
```

---

## Summary

| Category | Count |
|----------|-------|
| Critical fixes needed | 3 |
| Files to delete | 7 |
| Files to move | 2 |
| Config changes | 2 |

**Priority:** Fix critical errors first, then clean up files.
