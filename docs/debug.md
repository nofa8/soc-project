# Debugging Manual

> **System:** Fedora 43  
> **Logging:** systemd-journald (no rsyslog file output)  
> **Updated:** 2026-01-17

---

## Architecture

Fedora 43 uses **systemd-journald** as the sole log sink:

```
iptables LOG → kernel → journald → (no file output)
```

**Key Constraint:** Wazuh agent in Docker cannot read host journald due to socket-based IPC isolation.

---

## � `test-fw-block` Fails

**Root Cause:** Docker container isolation prevents reading host journald.

### What Works
- iptables LOG rules are active (verified via `iptables -L SOC_ALLOW -v -n`)
- Journald receives FIREWALL-DROP events (verified via `journalctl -k | grep FIREWALL`)

### What Doesn't Work
- Wazuh agent in container cannot read host journald
- Mounted journal directories + machine-id are insufficient

### Workarounds
1. **Run Wazuh agent on host** (not in container)
2. **Use journald export to file** via systemd service

---

## 🚨 `pipeline-test` Shows +0

**Not a real failure.** Pipeline works; 5s wait is too short.

### Verification
```bash
# Get baseline
PRE=$(curl -s 'http://localhost:9200/soc-logs-*/_count' | jq '.count')

# Generate traffic
make brute-force

# Wait longer
sleep 30

# Check delta
POST=$(curl -s 'http://localhost:9200/soc-logs-*/_count' | jq '.count')
echo "Delta: $((POST - PRE))"
```

---

## ✅ Working Tests

| Test | Rule | Status |
|------|------|--------|
| verify | - | All components OK |
| brute-force | 100004 | ✅ |
| test-sqli | 100005 | ✅ |
| test-privilege | 100010 | ✅ |
| verify-wazuh-rules | Multiple | 6 rules verified |

---

## Debugging Commands

```bash
# Check iptables packets hit
docker exec firewall-iptables iptables -L SOC_ALLOW -v -n | grep LOG

# Check journald for firewall
journalctl -k | grep "FIREWALL-DROP" | tail -10

# Check Wazuh agent status
docker exec wazuh-manager /var/ossec/bin/agent_control -l

# Check ES document count
curl -s 'http://localhost:9200/soc-logs-*/_count' | jq '.count'
```
