# SOC Project – State Report

> **Last Updated:** 2026-01-13 21:15 UTC  
> **Status:** ✅ **PROFESSIONAL GRADE & VERIFIED**

---

## Executive Summary

| Metric | Value |
|--------|-------|
| **Containers** | 10/10 Running |
| **Pipeline** | ✅ **Verified** (Agent → Manager → ES) |
| **Ruleset** | ✅ **Enhanced V2 (MITRE Mapped)** |
| **Alerts** | **150+** Verified in Elasticsearch |

---

## Enhanced Ruleset Verification (V2)

The ruleset has been upgraded to include MITRE ATT&CK mapping and stricter correlation logic (`same_source_ip`).

| Rule ID | Description | MITRE | Status | Behavior (New Logic) |
|---------|-------------|-------|--------|----------------------|
| **100001** | Login Success | - | ✅ | Standard detection |
| **100002** | Login Failed | **T1110** | ✅ | Mapped to "Brute Force" |
| **100003** | Brute Force | **T1110** | ✅ | Enforces `same_source_ip` (Robust) |
| **100004** | SQL Injection | **T1190** | ✅ | Mapped to "Exploit Public-Facing App" |
| **100005** | API Error 500 | - | ✅ | Corrected component name |
| **100006** | IDS Alert | **T1046** | ✅ | Uses `<if_matched_group>suricata` (High Confidence) |

---

## Pipeline Data Flow

```
[API] --(json)--> [Filebeat] --(raw logs)--> [Elasticsearch]
                      ^
                      |
[Suricata] --(eve.jsonl)--+--> [Wazuh Agent 002] --> [Wazuh Manager] --(alerts.json)--> [Filebeat] --(alerts)--> [Elasticsearch]
```

- **Wazuh Agent:** ID 002 (Active)
- **Config persistence:** Secured via direct volume mounts.

---

## Next Steps

1. **Kibana Visualization:**
   - Create dashboards filtering by `mitre.id` (New capability!).
   - Visualize Attack Vectors (SQLi vs Brute Force).

2. **Phase 3:** Vulnerability Implementation
   - Proceed with broken authentication checks.
