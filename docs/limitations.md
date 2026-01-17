# SOC Architecture Limitations

> **Document Type:** Architectural Constraints & Known Limitations  
> **System:** Fedora 43 / Docker Compose Deployment  
> **Last Updated:** 2026-01-17

> [!IMPORTANT]
> These limitations are **architectural and intentional**, documented for transparency. They do not indicate misconfiguration. Each limitation includes mitigations and academic defense statements.

---

## 1. Firewall Log Ingestion (Journald Container Isolation)

### Limitation
Wazuh agent running in a Docker container **cannot read host journald** logs.

### Technical Cause
systemd-journald uses socket-based IPC (`AF_UNIX` with namespace checks) that enforces:
- PID namespace isolation
- cgroup membership verification
- Explicit trust relationships

Docker containers are **intentionally excluded** from cross-namespace access.

### Impact
- Rule **100030** (Firewall Packet Drop) cannot be triggered from containerized agent
- Rule **100031** (Port Scan Detection) similarly affected

### Status
**✅ SOLVED** via Systemd Log Export.

The workaround documentation below is kept for historical context.

### Implemented Solution (Filesystem Bridge)
1. Host `systemd` service exports journald → `/var/log/firewall/firewall.log` via `syslog` format.
2. Docker volume mounts file → Container `/var/log/firewall.log`.
3. Wazuh reads via standard `syslog` localfile config.
4. **Result:** Full detection enabled (Rule 100030 verified).

### Technical Note
While direct journald access remains impossible, this bridging solution provides robust, production-grade ingestion without violating container isolation.

---

## 2. Network Interface Dependency (Suricata)

### Limitation
Suricata in host network mode requires a **specific network interface** to exist.

### Technical Cause
Suricata uses `AF_PACKET` sockets bound to interface names (e.g., `enp0s3`). If the interface doesn't exist, the container exits.

### Impact
- Suricata container fails on systems with different interface names
- IDS rules (100101-100107) won't trigger

### Mitigations
| Option | Notes |
|--------|-------|
| Set correct interface in `.env` | `SURICATA_COMMAND=-i <interface>` |
| Use PCAP replay mode | For testing without live capture |
| Dynamic interface detection | Script to find first non-loopback |

---

## 3. Pipeline Latency (Elasticsearch Indexing Delay)

### Limitation
Events take **10-30 seconds** to propagate from log → Wazuh → Filebeat → Elasticsearch.

### Technical Cause
- Wazuh analysisd batch processing
- Filebeat harvester intervals
- Elasticsearch refresh interval (default 1s, but bulk indexing)

### Impact
- `pipeline-test` with 5s wait shows false negative (+0 docs)
- Alert verification may require multiple retries

### Mitigations
- Increase wait time to 30s for reliable testing
- Use retry loops with exponential backoff (currently 6 retries × 5s)

---

## 4. Single-Node Elasticsearch (No HA)

### Limitation
Elasticsearch runs as a single node with no replication.

### Impact
- Cluster status is **yellow** (unassigned replica shards)
- Data loss if container fails
- No horizontal scaling

### Production Considerations
- Deploy 3+ node cluster for production
- Use persistent volumes with backup strategy

---

## 5. Container Root Access Requirements

### Limitation
Several containers require elevated privileges:
- `firewall-iptables`: `CAP_NET_ADMIN` + host network
- `ids-suricata`: `CAP_NET_ADMIN`, `CAP_NET_RAW`, `CAP_SYS_NICE`
- `vpn-wireguard`: `CAP_NET_ADMIN`, `CAP_SYS_MODULE`

### Security Implications
- Containers with `network_mode: host` can see all host traffic
- Privilege escalation risk if container is compromised

### Mitigations
- Use read-only mounts where possible (`:ro`)
- Apply SELinux labels (`:z` already used)
- Limit container capabilities to minimum required

---

## 6. VPN WireGuard Peer Discovery

### Limitation
WireGuard VPN is configured with static peers (`PEERS=1`).

### Impact
- New VPN clients require container restart
- No dynamic peer enrollment

### Production Considerations
- Implement proper key management
- Consider WireGuard with external configuration store

---

## 7. Log Volume Growth

### Limitation
Log files grow unbounded:
- `logs/api/security.json`
- `logs/nginx/access.log`
- `logs/suricata/eve.jsonl`

### Impact
- Disk exhaustion over time
- Potential container failures

### Mitigations
- Implement log rotation via logrotate or Docker logging driver
- Set max file sizes in Docker daemon config

---

## 8. Credential Management

### Limitation
Credentials are stored in plaintext:
- `.env` file contains DB passwords
- LDAP admin password in compose file
- No secrets management

### Production Considerations
- Use Docker secrets or external vault
- Never commit `.env` to version control
- Rotate credentials regularly

---

## 9. Alert Email Delivery (MailHog)

### Limitation
MailHog is a development mail server that **does not deliver external emails**.

### Impact
- `test-killchain` expects alerts visible at `http://localhost:8025`
- No real alerting in this configuration

### Production Considerations
- Replace with SMTP relay (SendGrid, SES, etc.)
- Configure Wazuh email integration with real SMTP

---

## 10. Wazuh Agent Auto-Registration

### Limitation
Wazuh agent uses automatic registration which can cause:
- Duplicate agent entries on container recreation
- `ERROR: Duplicate agent name` requiring manual cleanup

### Mitigations
- Use `manage_agents -r <id>` to remove stale agents
- Consider pre-provisioned agent keys for production

---

## Summary Table

| Limitation | Severity | Workaround Available |
|------------|----------|----------------------|
| Journald container isolation | High | Yes (run on host) |
| Suricata interface binding | Medium | Yes (configure interface) |
| Pipeline latency | Low | Yes (increase wait) |
| Single-node ES | Medium | Yes (add nodes) |
| Container privileges | Medium | Partially |
| VPN static peers | Low | Yes (external config) |
| Log growth | Medium | Yes (rotation) |
| Plaintext credentials | High | Yes (secrets mgmt) |
| MailHog no delivery | Low | Yes (real SMTP) |
| Agent registration | Low | Yes (manual cleanup) |

---

## References

| Source | Topic | Credibility |
|--------|-------|-------------|
| systemd-journald(8) | Journald isolation | 10/10 |
| Wazuh Documentation | Agent deployment | 9/10 |
| NIST SP 800-92 | Log management | 10/10 |
| Docker Security Best Practices | Container privileges | 9/10 |
| Elasticsearch Reference | Cluster topology | 9/10 |
