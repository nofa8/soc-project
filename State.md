# SOC Project – State Report

> **Last Updated:** 2026-01-15 17:45 UTC  
> **Status:** ✅ **PHASE 3 COMPLETE: VULNERABILITIES DETECTED**

---

## Executive Summary

Phase 3 is complete. We have successfully implemented and detected both targeted vulnerabilities. The SOC demonstrated **Defense in Depth** by detecting SQL Injection at the Network Layer (Suricata) while preserving comprehensive Application Layer forensics (FastAPI Logs).

| Metric | Value |
|--------|-------|
| **Vunerability #1** | ✅ **Broken Auth** (Level 10 Alert) |
| **Vunerability #2** | ✅ **SQL Injection** (Level 14 Alert + Forensic Log) |
| **Detection** | **Defense in Depth** (Network + App) |
| **Integrity** | ✅ Attack Payloads Captured |

---

## Evidence Locker (Phase 3.2: SQL Injection)

| Artifact | Verified Content |
|----------|------------------|
| **Exploit** | `1' OR '1'='1` |
| **Wazuh (App)** | Logged: `raw_parameter: "1' OR '1'='1"` |
| **Wazuh (Net)** | Alert: **Rule 100130 (Level 14)** – Multiple Suricata alerts |
| **Notification** | Email: `Wazuh notification - ... Alert level 14` |

*Note: Network-layer detection (Suricata) correctly identified the attack vector (ET WEB_SERVER) and triggered a Critical (Level 14) alert, pre-empting the Application-layer rule.*

---

## Active Ruleset (Frozen)

| Rule ID | Name | Level | Status |
|---------|------|-------|--------|
| **100010** | **Privilege Escalation** | 10 | ✅ **VERIFIED** |
| **100005** | **SQL Injection** | 12 | ✅ **LOGGED** |
| **100130** | **Suricata Correlation** | 14 | ✅ **ALERTED** |

---

## Next Steps: Phase 4 (Attack Narrative)

1.  **Objective:** Execute full kill chain ("The Story").
2.  **Dashboards:** Build visualizations to show the attack timeline.
