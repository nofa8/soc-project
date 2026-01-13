# SOC Project – State Report

> **Last Updated:** 2026-01-13 13:28 UTC  
> **Status:** ✅ **ALL SYSTEMS OPERATIONAL**

---

## Executive Summary

| Metric | Value |
|--------|-------|
| **Containers** | 10/10 Running |
| **ES Documents** | 1,357+ |
| **Pipeline** | ✅ **FULLY VERIFIED** |
| **Detection** | ✅ **WORKING** |

---

## Verification Results

```
make siem-ready
  Elasticsearch: yellow
  Wazuh Agent: Active
  Filebeat: Harvesting
  Suricata: Producing events
SIEM READY
```

```
make verify
  API Endpoint:        OK (200)
  Elasticsearch:       OK (yellow)
  Filebeat:            OK (Harvesters Active)
  Wazuh Agent:         OK (Active)
  Suricata:            OK (Running + EVE output)
=== ALL VERIFICATIONS PASSED ===
```

```
make pipeline-test
1. Baseline: 1355 docs
2. Generating attack traffic...
3. Result: 1357 docs (+2)
SUCCESS: Pipeline ingesting events
```

---

## Detection Verification ✅

```
make verify-detection
  Login Failed Events:           1 found    ✅
  SQLi Attempts:                 1 found    ✅
  Suricata Alerts:               22 found   ✅
```

**All security events now reaching Elasticsearch!**

---

## Fix Applied: soc_event Field

**Issue:** ECS reserves `event` as object type, conflicting with API string values.

**Resolution:**
1. Renamed `event` → `soc_event` in:
   - `logger.py`
   - `main.py` (all occurrences)
   - `custom-rules.xml`
2. **Rebuilt API container** (`docker-compose build api-service`)
3. Deleted ES data stream to clear mapping
4. Updated Makefile `verify-detection` to query `soc_event`

---

## Data Flow Diagram

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ API Service  │────▶│   Filebeat   │────▶│ Elasticsearch│
│ soc_event:   │     │              │     │ soc-logs-*   │
│ login_failed │     │              │     │              │
│ possible_sqli│     │              │     │ 1,357+ docs  │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │
       ▼                    ▼
┌──────────────┐     ┌──────────────┐
│    Nginx     │     │   Suricata   │
│ access.log   │     │  eve.jsonl   │
└──────────────┘     └──────────────┘
```

---

## Makefile v3.0 Status

| Target | Status |
|--------|--------|
| `preflight` | ✅ Passed |
| `siem-ready` | ✅ All gates open |
| `verify` | ✅ All checks passed |
| `pipeline-test` | ✅ +2 docs indexed |
| `verify-detection` | ✅ Events found |

---

## Next Steps

1. **Kibana:** Create index pattern `soc-logs-*`
2. **Dashboards:** Build visualizations for `soc_event` distribution
3. **Phase 3:** Implement additional vulnerabilities
4. **Phase 4:** Execute full attack demonstrations
