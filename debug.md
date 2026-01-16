# Debugging Manual

> **Scope**: Troubleshooting failed Makefile targets and log pipeline issues.
> **Context**: `make test-fw-block` failure analysis.

---

## 🚨 Problem: `test-fw-block` Fails
**Symptom**: `Rule 100030 NOT DETECTED` after 30 seconds.

### Root Cause Analysis

The detection pipeline for firewall events is complex and relies on the **HOST** kernel logging:

1.  **Attack**: `curl` -> Host Kernel (iptables)
2.  **Logging**: Kernel -> Host Syslog Daemon (`rsyslog` / `journald`) -> `/var/log/syslog` (on Host)
3.  **Transport**: `/var/log/syslog` (Host) -> Mounted to `/var/log/host_syslog` (Container)
4.  **Ingestion**: Wazuh Agent reads `/var/log/host_syslog` -> Wazuh Manager

**Failure Point**: Step 2 or 3 is the likely culprit. Modern Linux systems (Ubuntu 20.04+, Debian 11+) often default to `journald` and may **NOT** write to `/var/log/syslog` by default unless `rsyslog` is installed and running.

### 🛠️ Debugging Steps

#### 1. Verify Host Logging
Check if firewall events are actually appearing in the host's log file:

```bash
# Run this on your host machine while running 'make test-fw-block'
tail -f /var/log/syslog | grep "FIREWALL-DROP"
```
**If empty**: Your host is not writing headers to syslog.
**Try**: `dmesg | grep "FIREWALL-DROP"` or `journalctl -f | grep "FIREWALL-DROP"`.

#### 2. Verify Container Mount
Check if the Wazuh agent can see the file:

```bash
docker exec wazuh-agent head -n 5 /var/log/host_syslog
```
**If "No such file" or empty**: The volume mount is invalid.

#### 3. Fix: Point to Correct Log File
If your host logs to `kern.log` or another file, update `docker-compose.yml`:

```yaml
  wazuh-agent:
    volumes:
      # Change /var/log/syslog to where YOUR host actually logs (e.g., /var/log/kern.log)
      - /var/log/kern.log:/var/log/host_syslog:ro
```

---

## 🚨 Problem: `verify-es` / `siem-ready` Fails
**Symptom**: `Elasticsearch: FAILED ()`
**Status**: **FIXED** (via Port Exposure)

If this recurs:
1.  Check `docker-compose.yml` has `ports: - "9200:9200"`.
2.  Run `curl -v localhost:9200`.

---

## 🚨 Problem: `verify-wazuh-rules` Script Error
**Symptom**: `[: : integer expected`
**Root Cause**: The script `tests/verify-wazuh-rules.sh` tries to curl localhost:9200 inside the script context (host), but possibly receives empty/malformed output if ES isn't ready or compatible.

**Fix**: Ensure `curl` output is valid JSON before parsing with `jq`.

```bash
# Debug the query manually
curl -s -X GET "http://localhost:9200/soc-logs-*/_count?q=rule.id:100030"
```
