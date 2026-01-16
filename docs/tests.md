# Detection Validation & Testing Report

> **Purpose:** Systematic validation of all SOC detection rules through controlled attack simulation.

---

## 1. Testing Methodology

All detection rules are validated using:
- **Controlled attack simulation** (deterministic triggers)
- **One test per detection rule** (atomic validation)
- **Automated via Makefile** (repeatable)
- **Evidence collected via Wazuh + Kibana + MailHog**

### Quick Start
```bash
# Run ALL detection tests
make test-all

# Run full kill chain demo
make test-killchain
```

---

## 2. Rule Validation Matrix

| Rule ID | Description | Test Command | Assertion | Window |
|---------|-------------|--------------|-----------|--------|
| **100002** | Login Success | `make login-success` | MANUAL | - |
| **100003** | Login Failed | `make login-failure` | MANUAL | - |
| **100004** | Brute Force | `make brute-force` | ✅ AUTO | 5m |
| **100005** | SQL Injection | `make test-sqli` | ✅ AUTO | 5m |
| **100006** | API Error | `make server-error-test` | MANUAL | - |
| **100010** | Privilege Esc | `make test-privilege` | ✅ AUTO | 5m |
| **100020** | VPN Auth Fail | `make test-vpn` | MANUAL | - |
| **100021** | VPN Brute Force | `make test-vpn-bruteforce` | MANUAL | - |
| **100030** | Firewall Block | `make test-fw-block` | ✅ AUTO | 5m |
| **100031** | Firewall Scan | `make test-fw-scan` | MANUAL | - |

> **AUTO**: Test queries Elasticsearch and `exit 1` on detection failure.
> **MANUAL**: Test triggers attack; verification requires Kibana/MailHog inspection.


---

## 3. Detailed Test Cases

### 3.1 Privilege Escalation (Rule 100010)

**Attack:** Admin header bypass
```bash
curl http://localhost/admin/system_status -H "X-Admin-Override: true"
```

**Expected:**
- HTTP 200 with `"mode": "admin_privileged"`
- Wazuh Alert: Rule 100010 (Level 10)
- Email notification via MailHog

**Makefile:** `make test-privilege`

---

### 3.2 SQL Injection (Rule 100005)

**Attack:** Classic OR injection
```bash
curl "http://localhost/items/1'%20OR%20'1'='1"
```

**Expected:**
- API logs `raw_parameter` containing payload
- Wazuh Alert: Rule 100005 (Level 12)
- Email notification via MailHog

**Makefile:** `make test-sqli`

---

### 3.3 Brute Force (Rule 100004)

**Attack:** 5+ failed login attempts in 60 seconds
```bash
for i in {1..6}; do
  curl -X POST http://localhost/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"wrong"}'
done
```

**Expected:**
- 5x Rule 100003 (Level 5)
- 1x Rule 100004 (Level 10 - Correlation)
- Email notification

**Makefile:** `make brute-force`

---

### 3.4 VPN Brute Force (Rule 100021)

**Attack:** Multiple invalid VPN handshakes
```bash
for i in {1..6}; do echo "junk" | nc -u -w1 127.0.0.1 51820; done
```

**Expected:**
- Multiple Rule 100020 (Level 7)
- Rule 100021 correlation (Level 10)

**Makefile:** `make test-vpn-bruteforce`

---

### 3.5 Firewall Scan Detection (Rule 100031)

**Attack:** Port scan against blocked ports
```bash
nmap -p 22,3306 127.0.0.1
```

**Expected:**
- Syslog entries with `FIREWALL-DROP:`
- Multiple Rule 100030 (Level 7)
- Rule 100031 correlation (Level 10)

**Makefile:** `make test-fw-scan`

---

## 4. Coverage Analysis

| Metric | Value |
|--------|-------|
| **Total Rules** | 18 |
| **Rules with Makefile Tests** | 12 |
| **Coverage** | 67% |
| **Correlation Rules Tested** | 4 |

---

## 5. Known Limitations

- **False Positive Testing:** Not systematically validated
- **ML/Anomaly Detection:** Out of scope
- **VPN Rules:** Depend on WireGuard logging behavior
- **Suricata Rules:** Require network-level traffic generation

---

## 6. Verification Commands

### Check Recent Alerts (Elasticsearch)
```bash
curl -s "http://localhost:9200/soc-logs-*/_search?q=rule.id:100010" | jq '.hits.hits[]._source.rule'
```

### Check Email Notifications
```bash
curl -s http://localhost:8025/api/v2/messages | jq '.items[].Content.Headers.Subject'
```

### View API Logs
```bash
tail -f logs/api/security.json | jq '.'
```

---

## 7. References

- NIST SP 800-61r2: Computer Security Incident Handling
- NIST SP 800-92: Guide to Computer Security Log Management
- MITRE ATT&CK: Detection Mapping Guidelines
