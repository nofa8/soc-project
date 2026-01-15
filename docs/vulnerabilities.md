# Vulnerability Specification Document
> **Phase 3:** Controlled Vulnerability Introduction

 This document defines **intentional, controlled vulnerabilities** introduced to evaluate the SOC’s ability to detect, correlate, and alert on realistic attack scenarios. Each vulnerability is explicitly mapped to **OWASP Top 10**, **MITRE ATT&CK**, expected **log sources**, and **SIEM response behavior**.

---

## 1. Broken Authentication (Admin Override)
**Concept:**
A logic flaw in the API allows a non-admin user to bypass role-based access control by injecting a forbidden request header, resulting in unauthorized administrative access **without authentication failure**.

| Field | Definition |
|-------|------------|
| **Vulnerability Name** | Broken Access Control – Admin Override |
| **OWASP Category** | **A01:2021 – Broken Access Control** |
| **MITRE ATT&CK Tactic** | **TA0004 – Privilege Escalation** |
| **Related Technique** | **T1078 – Valid Accounts (Abuse)** |
| **Mechanism** | Header Injection: `X-Admin-Override: true` |
| **Attack Type** | Successful but unauthorized access |
| **Expected Logs** | `api-service` (FastAPI structured JSON logs) |
| **Baseline Rule Triggered** | **100002 – Login Success (Level 3)** |
| **Detection Strategy** | Correlation of `login_success` with:<br>• Forbidden header presence<br>• Role mismatch (user ≠ admin)<br>• Access to admin-only endpoint |
| **Escalated Alert Level** | **≥ Level 10 (Critical)** |
| **Email Notification** | **Yes** |

> **Goal:** Demonstrate detection of **illegitimate successful authentication**, validating the SOC’s ability to identify **privilege escalation without brute force or failure signals**.

---

## 2. Data Layer Abuse (Real SQL Injection)
**Concept:**
A vulnerable API endpoint executes unsanitized user input directly in a SQL query, enabling SQL injection and potential data disclosure.

| Field | Definition |
|-------|------------|
| **Vulnerability Name** | SQL Injection (SQLi) |
| **OWASP Category** | **A03:2021 – Injection** |
| **MITRE ATT&CK Tactic (Primary)** | **TA0001 – Initial Access** |
| **MITRE Technique** | **T1190 – Exploit Public-Facing Application** |
| **Secondary Tactic (Impact)** | **TA0010 – Exfiltration** |
| **Mechanism** | Payload in URL path: `/items/1' OR '1'='1` |
| **Expected Logs** | `api-service` (request logs)<br>`db-service` (PostgreSQL query logs) |
| **Expected Rule** | **100005 – SQL Injection Attempt** |
| **Alert Level** | **Level 12 (Critical)** |
| **Email Notification** | **Yes** |

> **Goal:** Demonstrate **multi-layer correlation** between application-layer exploitation and database-layer execution, validating the SOC’s ability to detect **data-oriented attacks**.

---

## Execution & Control Roadmap

1.  **Activate ONE vulnerability at a time**
2.  Implement **Broken Authentication**
3.  Execute controlled attack
4.  Capture evidence:
    *   Attack request
    *   Kibana alert
    *   Email notification
5.  Freeze results
6.  Implement **SQL Injection**
7.  Repeat verification process

> No overlapping vulnerabilities are enabled simultaneously to preserve forensic clarity and experimental control.

---

### Supporting References
*   OWASP Top 10 (2021)
*   MITRE ATT&CK (Enterprise Matrix)
*   NIST SP 800-61r2 (Incident Handling)
