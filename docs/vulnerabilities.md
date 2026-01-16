# Vulnerability Specification Document

> **Phase 3:** Controlled Vulnerability Introduction

This document defines **intentional, controlled vulnerabilities** to evaluate the SOC's detection capabilities. Each vulnerability is mapped to **OWASP Top 10**, **MITRE ATT&CK**, and corresponding **Wazuh detection rules**.

---

## 1. Privilege Escalation (Admin Override)

| Field | Value |
|-------|-------|
| **OWASP** | A01:2021 – Broken Access Control |
| **MITRE Tactic** | TA0004 – Privilege Escalation |
| **MITRE Technique** | T1078 – Valid Accounts |
| **Mechanism** | Header: `X-Admin-Override: true` |
| **Endpoint** | `GET /admin/system_status` |
| **Detection Rule** | **100010** (Level 10) |
| **Test Command** | `make test-privilege` |

---

## 2. SQL Injection

| Field | Value |
|-------|-------|
| **OWASP** | A03:2021 – Injection |
| **MITRE Tactic** | TA0001 – Initial Access |
| **MITRE Technique** | T1190 – Exploit Public-Facing Application |
| **Mechanism** | Payload: `1' OR '1'='1` |
| **Endpoint** | `GET /items/{id}` |
| **Detection Rule** | **100005** (Level 12) |
| **Test Command** | `make test-sqli` |

---

## 3. Brute Force Attack (API)

| Field | Value |
|-------|-------|
| **OWASP** | A07:2021 – Identification and Authentication Failures |
| **MITRE Tactic** | TA0006 – Credential Access |
| **MITRE Technique** | T1110 – Brute Force |
| **Mechanism** | 5+ failed logins in 60 seconds |
| **Endpoint** | `POST /login` |
| **Detection Rule** | **100004** (Level 12, correlation) |
| **Test Command** | `make brute-force` |

---

## 4. VPN Brute Force

| Field | Value |
|-------|-------|
| **OWASP** | N/A (Network Layer) |
| **MITRE Tactic** | TA0006 – Credential Access |
| **MITRE Technique** | T1110 – Brute Force |
| **Mechanism** | 5+ invalid handshakes in 60 seconds |
| **Endpoint** | UDP :51820 |
| **Base Rule** | **100020** (Level 4, single event) |
| **Correlation Rule** | **100021** (Level 10) |
| **Test Command** | `make test-vpn-bruteforce` |

---

## 5. Port Scan Detection (Firewall)

| Field | Value |
|-------|-------|
| **OWASP** | N/A (Network Layer) |
| **MITRE Tactic** | TA0043 – Reconnaissance |
| **MITRE Technique** | T1046 – Network Service Discovery |
| **Mechanism** | 15+ blocked connections in 60 seconds |
| **Blocked Ports** | 22 (SSH), 3306 (MySQL) |
| **Base Rule** | **100030** (Level 3, single event) |
| **Correlation Rule** | **100031** (Level 10) |
| **Test Command** | `make test-fw-scan` |

---

## Detection Coverage Matrix

| Vulnerability | Rule | Level | Layer | Verified |
|---------------|------|-------|-------|----------|
| Privilege Escalation | 100010 | 10 | Application | ✅ |
| SQL Injection | 100005 | 12 | Application | ✅ |
| Brute Force (API) | 100004 | 12 | Application | ✅ |
| VPN Brute Force | 100021 | 10 | Network | ✅ |
| Port Scan | 100031 | 10 | Perimeter | ✅ |

---

## References

- OWASP Top 10 (2021)
- MITRE ATT&CK Enterprise Matrix
- NIST SP 800-61r2 (Incident Handling)
