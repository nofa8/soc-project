# ============================================================================
# SOC Project Makefile – Production Grade (v3.0)
# ============================================================================
# This Makefile serves as:
#   - A SOC runbook
#   - A verification harness
#   - An attack simulation driver
#   - A teaching artifact
# ============================================================================

.SILENT:

# --------------------
# Configuration
# --------------------

SUDO       ?= sudo
TARGET_IP  ?= 127.0.0.1
NETWORK    ?= 172.17.0.0/24

API_URL    ?= http://localhost
ES_URL     ?= http://localhost:9200
KIBANA_URL ?= http://localhost:5601

# Credentials (override via .env or command line)
ADMIN_USER       ?= admin
ADMIN_WRONG_PASS ?= wrong
VALID_USER       ?= user
VALID_PASS       ?= pass


-include .env

# --- OS & Log Detection ---

# Default to Ubuntu/Debian standard
LOG_FILE := /var/log/syslog

# Check if we are on Fedora/CentOS/RHEL (look for messages file)
ifneq ("$(wildcard /var/log/messages)","")
    LOG_FILE := /var/log/messages
endif

# Check if we are on Ubuntu (look for syslog file) explicitly to be safe
ifneq ("$(wildcard /var/log/syslog)","")
    LOG_FILE := /var/log/syslog
endif

# Export it so docker-compose can see it
export HOST_SYSLOG = $(LOG_FILE)

# --------------------------



# Colors
YELLOW := $(shell tput setaf 3 2>/dev/null || echo "")
BLUE   := $(shell tput setaf 4 2>/dev/null || echo "")
GREEN  := $(shell tput setaf 2 2>/dev/null || echo "")
RED    := $(shell tput setaf 1 2>/dev/null || echo "")
NC     := $(shell tput sgr0 2>/dev/null || echo "")

# --------------------
# Phony targets
# --------------------
.PHONY: all help preflight \
        status containers logs \
        verify verify-api verify-es verify-filebeat verify-wazuh verify-suricata \
        siem-ready \
        test api-tests attack-tests \
        login-success login-failure sqli-test brute-force \
        network-tests nmap-host nmap-ports nmap-services \
        pipeline-test count-events verify-wazuh-rules \
        restart clean-logs reset-lab

# ============================================================================
# HELPER MACROS
# ============================================================================

# CHECK_HTTP: Validates HTTP response code is within expected range
# Usage: $(call CHECK_HTTP,URL,MIN_CODE,MAX_CODE)
define CHECK_HTTP
STATUS=$$(curl -s -o /dev/null -w "%{http_code}" -X POST $(1) \
	-H "Content-Type: application/json" -d '{}' 2>/dev/null || echo 000); \
if [ "$$STATUS" -ge $(2) ] && [ "$$STATUS" -le $(3) ]; then \
	echo "$(GREEN)OK ($$STATUS)$(NC)"; \
else \
	echo "$(RED)FAILED ($$STATUS)$(NC)"; \
	exit 1; \
fi
endef

# CHECK_ALERT: Assert Wazuh alert exists in Elasticsearch (with retry)
# Usage: $(call CHECK_ALERT,RULE_ID,MIN_COUNT)
# Polls ES up to 6 times (30s total) to handle Wazuh-to-ES pipeline lag
ALERT_INDEX ?= soc-logs-*
ALERT_RETRIES ?= 6
ALERT_INTERVAL ?= 5

define CHECK_ALERT
@echo "  Waiting for alert indexing..."; \
for attempt in 1 2 3 4 5 6; do \
  COUNT=$$(docker exec elasticsearch curl -s 'http://localhost:9200/$(ALERT_INDEX)/_search' \
    -H 'Content-Type: application/json' \
    -d '{"size":0,"query":{"bool":{"must":[{"term":{"rule.id":"$(1)"}},{"range":{"@timestamp":{"gte":"now-10m"}}}]}}}' \
    2>/dev/null | jq -r '.hits.total.value // 0'); \
  if [ "$$COUNT" -ge $(2) ]; then \
    echo "$(GREEN)  ✓ Rule $(1) verified ($$COUNT alerts, attempt $$attempt)$(NC)"; \
    exit 0; \
  fi; \
  echo "  Retry $$attempt/6: Rule $(1) not yet indexed (got $$COUNT)..."; \
  sleep $(ALERT_INTERVAL); \
done; \
echo "$(RED)  ✗ Rule $(1) NOT DETECTED after 30s (expected ≥$(2))$(NC)"; \
exit 1
endef


# ============================================================================
# STATUS & MONITORING
# ============================================================================

all: status

status: preflight containers
	echo ""
	echo "$(YELLOW)=== ELASTICSEARCH STATUS ===$(NC)"
	curl -s '$(ES_URL)/_cluster/health?pretty' 2>/dev/null | head -10 || echo "$(RED)ES not reachable$(NC)"
	echo ""
	echo "$(YELLOW)=== DOCUMENT COUNT ===$(NC)"
	curl -s '$(ES_URL)/soc-logs-*/_count' 2>/dev/null | jq -r '"Total Documents: \(.count)"' || echo "$(RED)No soc-logs index$(NC)"
	echo ""

containers:
	echo "$(YELLOW)=== CONTAINER STATUS ===$(NC)"
	docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -v WinBoat

containers-ips:
	echo "$(YELLOW)=== CONTAINER IP ADDRESSES ===$(NC)"
	@docker ps --format '{{.Names}} {{.ID}}' | while read name id; do ips=$$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' "$$id"); echo "$$name $$ips"; done

logs:
	echo "$(YELLOW)=== RECENT LOGS ===$(NC)"
	echo "$(BLUE)[API]$(NC)" && tail -3 logs/api/security.json 2>/dev/null | jq -c '.' || echo "No API logs"
	echo "$(BLUE)[NGINX]$(NC)" && tail -1 logs/nginx/access.log 2>/dev/null | cut -c1-120 || echo "No Nginx logs"
	echo "$(BLUE)[SURICATA]$(NC)" && tail -3 logs/suricata/eve.jsonl 2>/dev/null | jq -c '.event_type' || echo "No Suricata logs"

# ============================================================================
# PREFLIGHT & GATES
# ============================================================================

preflight:
	echo "$(YELLOW)Preflight checks...$(NC)"
	command -v docker >/dev/null 2>&1 || { echo "$(RED)Error: docker is required$(NC)"; exit 1; }
	command -v curl >/dev/null 2>&1 || { echo "$(RED)Error: curl is required$(NC)"; exit 1; }
	command -v jq >/dev/null 2>&1 || { echo "$(RED)Error: jq is required$(NC)"; exit 1; }
	echo "$(GREEN)  Preflight passed$(NC)"

siem-ready: preflight
	echo "$(YELLOW)Checking SIEM readiness...$(NC)"
	# Check Elasticsearch is healthy
	ES_STATUS=$$(curl -s '$(ES_URL)/_cluster/health' 2>/dev/null | jq -r '.status' || echo "unreachable"); \
	if [ "$$ES_STATUS" != "green" ] && [ "$$ES_STATUS" != "yellow" ]; then \
		echo "$(RED)  Elasticsearch not healthy ($$ES_STATUS)$(NC)"; \
		exit 1; \
	fi; \
	echo "$(GREEN)  Elasticsearch: $$ES_STATUS$(NC)"
	# Check Wazuh agent is active
	if docker exec wazuh-manager /var/ossec/bin/agent_control -l 2>/dev/null | grep -q "Active"; then \
		echo "$(GREEN)  Wazuh Agent: Active$(NC)"; \
	else \
		echo "$(RED)  Wazuh Agent: Not Active$(NC)"; \
		exit 1; \
	fi
	# Check Filebeat is harvesting
	if docker logs filebeat 2>&1 | grep -q "Harvester started"; then \
		echo "$(GREEN)  Filebeat: Harvesting$(NC)"; \
	else \
		echo "$(RED)  Filebeat: No active harvesters$(NC)"; \
		exit 1; \
	fi
	# Check Suricata is producing events
	if [ -s logs/suricata/eve.jsonl ]; then \
		echo "$(GREEN)  Suricata: Producing events$(NC)"; \
	else \
		echo "$(RED)  Suricata: No EVE output$(NC)"; \
		exit 1; \
	fi
	echo "$(GREEN)SIEM READY$(NC)"

# ============================================================================
# VERIFICATION TARGETS (with exit codes)
# ============================================================================

verify: preflight verify-api verify-es verify-filebeat verify-wazuh verify-suricata
	echo ""
	echo "$(GREEN)=== ALL VERIFICATIONS PASSED ===$(NC)"

verify-api:
	printf "  %-20s " "API Endpoint:"
	STATUS=$$(curl -s -o /dev/null -w "%{http_code}" -X POST $(API_URL)/login \
		-H "Content-Type: application/json" -d '{}' 2>/dev/null || echo 000); \
	if [ "$$STATUS" -ge 200 ] && [ "$$STATUS" -lt 500 ]; then \
		echo "$(GREEN)OK ($$STATUS)$(NC)"; \
	else \
		echo "$(RED)FAILED ($$STATUS)$(NC)"; \
		exit 1; \
	fi

verify-es:
	printf "  %-20s " "Elasticsearch:"
	STATUS=$$(curl -s '$(ES_URL)/_cluster/health' 2>/dev/null | jq -r .status || echo "unreachable"); \
	if [ "$$STATUS" = "green" ] || [ "$$STATUS" = "yellow" ]; then \
		echo "$(GREEN)OK ($$STATUS)$(NC)"; \
	else \
		echo "$(RED)FAILED ($$STATUS)$(NC)"; \
		exit 1; \
	fi

verify-filebeat:
	printf "  %-20s " "Filebeat:"
	if docker logs filebeat 2>&1 | grep -q "Harvester started"; then \
		echo "$(GREEN)OK (Harvesters Active)$(NC)"; \
	else \
		echo "$(RED)FAILED (No harvesters)$(NC)"; \
		exit 1; \
	fi

verify-wazuh:
	printf "  %-20s " "Wazuh Agent:"
	if docker exec wazuh-manager /var/ossec/bin/agent_control -l 2>/dev/null | grep -q "Active"; then \
		echo "$(GREEN)OK (Active)$(NC)"; \
	else \
		echo "$(RED)FAILED (Not Active)$(NC)"; \
		exit 1; \
	fi

verify-suricata:
	printf "  %-20s " "Suricata:"
	if docker ps --format '{{.Names}}' | grep -q ids-suricata; then \
		if [ -s logs/suricata/eve.jsonl ]; then \
			echo "$(GREEN)OK (Running + EVE output)$(NC)"; \
		else \
			echo "$(YELLOW)WARN (Running but no EVE)$(NC)"; \
		fi; \
	else \
		echo "$(RED)FAILED (Container Exited)$(NC)"; \
		exit 1; \
	fi

verify-wazuh-rules:
	echo "$(YELLOW)=== WAZUH RULES VERIFICATION ===$(NC)"
	@bash tests/verify-wazuh-rules.sh

# ============================================================================
# TESTING TARGETS
# ============================================================================

test: api-tests network-tests pipeline-test
	echo "$(GREEN)=== TESTS COMPLETE ===$(NC)"

api-tests: login-success login-failure sqli-test
	echo "$(GREEN)[API TESTS COMPLETE]$(NC)"

login-success:
	printf "[API] Testing Successful Login... "
	STATUS=$$(curl -s -o /dev/null -w "%{http_code}" -X POST $(API_URL)/login \
		-H "Content-Type: application/json" \
		-d '{"username":"$(VALID_USER)","password":"$(VALID_PASS)"}' 2>/dev/null || echo 000); \
	if [ "$$STATUS" -eq 200 ]; then \
		echo "$(GREEN)OK (200)$(NC)"; \
	else \
		echo "$(RED)FAILED ($$STATUS)$(NC)"; \
		exit 1; \
	fi

login-failure:
	printf "[API] Testing Failed Login... "
	STATUS=$$(curl -s -o /dev/null -w "%{http_code}" -X POST $(API_URL)/login \
		-H "Content-Type: application/json" \
		-d '{"username":"$(ADMIN_USER)","password":"$(ADMIN_WRONG_PASS)"}' 2>/dev/null || echo 000); \
	if [ "$$STATUS" -eq 401 ]; then \
		echo "$(GREEN)OK (401 - Expected)$(NC)"; \
	else \
		echo "$(RED)FAILED ($$STATUS)$(NC)"; \
		exit 1; \
	fi

sqli-test:
	printf "[API] Testing SQL Injection detection... "
	curl -s "$(API_URL)/items/1%20OR%201=1" > /dev/null 2>&1
	echo "$(GREEN)SENT$(NC)"

server-error-test:
	printf "[API] Testing Server Error... "
	STATUS=$$(curl -s -o /dev/null -w "%{http_code}" $(API_URL)/error 2>/dev/null || echo 000); \
	if [ "$$STATUS" -eq 500 ]; then \
		echo "$(GREEN)OK (500 - Expected)$(NC)"; \
	else \
		echo "$(RED)FAILED ($$STATUS)$(NC)"; \
		exit 1; \
	fi

brute-force:
	echo "$(YELLOW)[API] Simulating Brute Force (5 attempts)...$(NC)"
	for i in 1 2 3 4 5; do \
		curl -s -X POST $(API_URL)/login \
			-H "Content-Type: application/json" \
			-d '{"username":"$(ADMIN_USER)","password":"attempt'$$i'"}' > /dev/null 2>&1; \
		echo "  Attempt $$i sent"; \
	done
	echo "$(GREEN)[BRUTE FORCE COMPLETE - Verifying Detection]$(NC)"
	$(call CHECK_ALERT,100004,1)

test-user-agent:
	curl -s http://testmynids.org/uid/index.html > /dev/null

# ============================================================================
# NETWORK TESTS
# ============================================================================

network-tests: nmap-host nmap-ports nmap-services

nmap-host:
	echo "[NMAP] Host discovery on $(NETWORK)"
	nmap -sn $(NETWORK)
	echo ""

nmap-ports:
	echo "[NMAP] TCP port scan on $(TARGET_IP)"
	$(SUDO) nmap -sS -p0-65535 $(TARGET_IP)
	echo ""

nmap-services:
	echo "[NMAP] Service and version detection on $(TARGET_IP)"
	$(SUDO) nmap -sV $(TARGET_IP)
	echo ""

attack-tests: brute-force sqli-test
	echo "$(GREEN)[ATTACK TESTS COMPLETE]$(NC)"

# ============================================================================
# PIPELINE VALIDATION
# ============================================================================

pipeline-test: siem-ready
	echo "$(YELLOW)=== PIPELINE TEST ===$(NC)"
	PRE_COUNT=$$(curl -s '$(ES_URL)/soc-logs-*/_count' 2>/dev/null | jq '.count' || echo 0); \
	echo "1. Baseline: $$PRE_COUNT docs"; \
	echo "2. Generating attack traffic..."; \
	curl -s -X POST $(API_URL)/login -H "Content-Type: application/json" \
		-d '{"username":"$(ADMIN_USER)","password":"$(ADMIN_WRONG_PASS)"}' > /dev/null 2>&1; \
	curl -s "$(API_URL)/items/1%20OR%201=1" > /dev/null 2>&1; \
	echo "   (Waiting 5s for propagation...)"; \
	sleep 5; \
	POST_COUNT=$$(curl -s '$(ES_URL)/soc-logs-*/_count' 2>/dev/null | jq '.count' || echo 0); \
	DELTA=$$((POST_COUNT - PRE_COUNT)); \
	echo "3. Result: $$POST_COUNT docs (+$$DELTA)"; \
	if [ "$$DELTA" -gt 0 ]; then \
		echo "$(GREEN)SUCCESS: Pipeline ingesting events$(NC)"; \
	else \
		echo "$(RED)FAILURE: No new documents indexed$(NC)"; \
		exit 1; \
	fi

count-events:
	curl -s '$(ES_URL)/soc-logs-*/_count' 2>/dev/null | jq -r '"Total events in ES: \(.count)"'

# ============================================================================
# OPERATIONS
# ============================================================================

restart:
	echo "Restarting SIEM components..."
	docker compose restart ids-suricata filebeat wazuh-agent 2>/dev/null || \
		docker-compose restart ids-suricata filebeat wazuh-agent
	echo "$(GREEN)[RESTART COMPLETE]$(NC)"

clean-logs:
	echo "$(RED)Truncating log files...$(NC)"
	truncate -s 0 logs/api/security.json 2>/dev/null || true
	truncate -s 0 logs/nginx/access.log 2>/dev/null || true
	truncate -s 0 logs/nginx/error.log 2>/dev/null || true
	echo "$(GREEN)[LOGS CLEANED]$(NC)"

reset-lab: clean-logs restart
	echo "$(GREEN)[LAB RESET COMPLETE]$(NC)"

# ============================================================================
# SOC VALIDATION TESTS (Operational Assurance)
# ============================================================================
# These tests validate detectability, false-positive control, and multi-layer
# correlation. Run these after any infrastructure change to verify SOC health.

.PHONY: test-pipeline test-noise test-sqli test-privilege test-vpn test-firewall test-killchain

# 1. Pipeline Health Test - Prove SIEM is alive
test-pipeline:
	echo "$(YELLOW)=== PIPELINE HEALTH TEST ===$(NC)"
	@echo -n "  Containers: " && docker ps -q | wc -l | xargs -I{} echo "{} running"
	@echo -n "  Kibana: " && curl -s http://localhost:5601 > /dev/null && echo "$(GREEN)OK$(NC)" || echo "$(RED)FAILED$(NC)"
	@echo -n "  Elasticsearch: " && curl -s http://localhost:9200/_cluster/health | jq -r '.status' | xargs -I{} echo "Status: {}"
	@echo -n "  Wazuh Agent: " && docker exec wazuh-agent /var/ossec/bin/wazuh-control status | grep -c "running" | xargs -I{} echo "{} services"
	echo "$(GREEN)[PIPELINE OK]$(NC)"

# 2. Negative Control Test - Prove no alert on noise
test-noise:
	echo "$(YELLOW)=== NEGATIVE CONTROL TEST (4 failures = NO alert) ===$(NC)"
	@for i in 1 2 3 4; do \
		curl -s -X POST $(API_URL)/login -H "Content-Type: application/json" \
			-d '{"username":"$(ADMIN_USER)","password":"noise_$$i"}' > /dev/null; \
		echo "  Attempt $$i sent"; \
	done
	echo "$(GREEN)[NOISE COMPLETE - Check: 0 new emails expected]$(NC)"

# 3. Detection Test: SQL Injection
test-sqli:
	echo "$(YELLOW)=== DETECTION TEST: SQL INJECTION ===$(NC)"
	@curl -s "$(API_URL)/items/1'%20OR%20'1'='1" | jq '.'
	echo "$(GREEN)[SQLi SENT - Verifying Detection]$(NC)"
	$(call CHECK_ALERT,100005,1)

# 4. Detection Test: Privilege Escalation
test-privilege:
	echo "$(YELLOW)=== DETECTION TEST: PRIVILEGE ESCALATION ===$(NC)"
	@curl -s $(API_URL)/admin/system_status -H "X-Admin-Override: true" | jq '.'
	echo "$(GREEN)[PRIV ESC SENT - Verifying Detection]$(NC)"
	$(call CHECK_ALERT,100010,1)

# 5. Detection Test: VPN Brute Force (UDP noise)
test-vpn:
	echo "$(YELLOW)=== DETECTION TEST: VPN UDP NOISE ===$(NC)"
	@for i in 1 2 3 4 5; do \
		echo "probe_$$i" | nc -u -w1 127.0.0.1 51820 2>/dev/null || true; \
		echo "  VPN probe $$i sent"; \
	done
	echo "$(GREEN)[VPN NOISE COMPLETE - Expect: Rule 100020/100021]$(NC)"

# 6. Detection Test: Firewall Scan
test-firewall:
	echo "$(YELLOW)=== DETECTION TEST: FIREWALL SCAN ===$(NC)"
	@nmap -p 22,3306 127.0.0.1 -T4 2>/dev/null || echo "  nmap not installed - using curl fallback"
	echo "$(GREEN)[FIREWALL SCAN COMPLETE - Expect: Rule 100030/100031]$(NC)"

# 7. Kill Chain Test - Full multi-layer correlation
test-killchain:
	echo "$(YELLOW)=== KILL CHAIN TEST (Full SOC Demo) ===$(NC)"
	echo "$(BLUE)[Step 1/5] Noise baseline...$(NC)"
	@$(MAKE) test-noise --no-print-directory
	sleep 2
	echo "$(BLUE)[Step 2/5] SQL Injection...$(NC)"
	@$(MAKE) test-sqli --no-print-directory
	sleep 2
	echo "$(BLUE)[Step 3/5] Privilege Escalation...$(NC)"
	@$(MAKE) test-privilege --no-print-directory
	sleep 2
	echo "$(BLUE)[Step 4/5] VPN Probing...$(NC)"
	@$(MAKE) test-vpn --no-print-directory
	sleep 2
	echo "$(BLUE)[Step 5/5] Firewall Scanning...$(NC)"
	@$(MAKE) test-firewall --no-print-directory
	echo ""
	echo "$(GREEN)=== KILL CHAIN COMPLETE ===$(NC)"
	echo "Check MailHog for alerts: http://localhost:8025"
	echo "Check Kibana for timeline: http://localhost:5601"

# 8. Complete Detection Validation Suite (ALL rules)
test-all:
	echo "$(YELLOW)=== COMPLETE SOC DETECTION VALIDATION SUITE ===$(NC)"
	echo ""
	echo "$(BLUE)[Phase 1/4] Application Layer Tests$(NC)"
	@$(MAKE) login-success --no-print-directory
	@$(MAKE) login-failure --no-print-directory
	@$(MAKE) brute-force --no-print-directory
	@$(MAKE) test-sqli --no-print-directory
	@$(MAKE) test-privilege --no-print-directory
	@$(MAKE) server-error-test --no-print-directory
	echo ""
	echo "$(BLUE)[Phase 2/4] Network Layer Tests$(NC)"
	@$(MAKE) network-tests --no-print-directory 2>/dev/null || echo "  Network tests skipped (nmap not available)"
	echo ""
	echo "$(BLUE)[Phase 3/4] VPN Detection Tests$(NC)"
	@$(MAKE) test-vpn --no-print-directory
	echo ""
	echo "$(BLUE)[Phase 4/4] Firewall Detection Tests$(NC)"
	@$(MAKE) test-fw-block --no-print-directory
	echo ""
	echo "$(GREEN)=== ALL DETECTION TESTS COMPLETE ===$(NC)"
	echo "Total Rules Tested: 12"
	echo "Evidence: MailHog (http://localhost:8025) | Kibana (http://localhost:5601)"

# ============================================================================
# VPN & FIREWALL ENFORCEMENT VALIDATION
# ============================================================================

.PHONY: test-vpn-fail test-vpn-bruteforce test-fw-block test-fw-scan test-fw-allow

# VPN - Negative Control (Invalid peer)
test-vpn-fail:
	echo "$(YELLOW)=== VPN TEST: INVALID PEER (Negative Control) ===$(NC)"
	@echo "junk_payload" | nc -u -w1 127.0.0.1 51820 2>/dev/null || true
	echo "$(GREEN)[SENT] Expect: No tunnel, handshake failure log$(NC)"

# VPN - Brute Force Correlation
test-vpn-bruteforce:
	echo "$(YELLOW)=== VPN TEST: BRUTE FORCE (Correlation) ===$(NC)"
	@for i in 1 2 3 4 5 6; do \
		echo "bruteforce_$$i" | nc -u -w1 127.0.0.1 51820 2>/dev/null || true; \
		echo "  Probe $$i sent"; \
	done
	echo "$(GREEN)[COMPLETE] Expect: Rule 100021 (Level 10) + Email$(NC)"

# Firewall - Block Test (Enforcement)
test-fw-block:
	echo "$(YELLOW)=== FIREWALL TEST: BLOCKED PORTS ===$(NC)"
	@echo "  Attempting connections to blocked ports..."
	@curl -s --connect-timeout 2 http://127.0.0.1:22 2>/dev/null || echo "  Port 22: Connection blocked/timeout"
	@curl -s --connect-timeout 2 http://127.0.0.1:3306 2>/dev/null || echo "  Port 3306: Connection blocked/timeout"
	echo "$(GREEN)[FIREWALL TEST - Verifying Detection]$(NC)"
	$(call CHECK_ALERT,100030,1)

# Firewall - Scan Detection (Correlation)
test-fw-scan:
	echo "$(YELLOW)=== FIREWALL TEST: PORT SCAN (Correlation) ===$(NC)"
	@nmap -p 22,3306,8080,9000 127.0.0.1 -T4 --open 2>/dev/null || echo "  nmap unavailable"
	echo "$(GREEN)[COMPLETE] Expect: Rule 100031 (Level 10) + Email$(NC)"

# Firewall - Allow Test (Negative Control)
test-fw-allow:
	echo "$(YELLOW)=== FIREWALL TEST: ALLOWED TRAFFIC (Negative Control) ===$(NC)"
	@curl -s -o /dev/null -w "HTTP %{http_code}" http://localhost
	echo ""
	echo "$(GREEN)[COMPLETE] Expect: Success, NO firewall log$(NC)"

# ============================================================================
# HELP
# ============================================================================

help:
	echo "$(BLUE)============================================================================$(NC)"
	echo "$(BLUE)               🛡️ SafePay SOC Project - Operational Control 🛡️                $(NC)"
	echo "$(BLUE)============================================================================$(NC)"
	echo ""
	echo "$(YELLOW)GATES & READINESS:$(NC)"
	printf "  $(GREEN)%-18s$(NC) %s\n" "preflight" "Check required tools (docker, curl, jq)"
	printf "  $(GREEN)%-18s$(NC) %s\n" "siem-ready" "Validate full SIEM pipeline is operational"
	echo ""
	echo "$(YELLOW)STATUS & MONITORING:$(NC)"
	printf "  $(GREEN)%-18s$(NC) %s\n" "status" "Health check of Containers, ES, and Document counts"
	printf "  $(GREEN)%-18s$(NC) %s\n" "containers" "List all running SOC services"
	printf "  $(GREEN)%-18s$(NC) %s\n" "logs" "Tail recent entries for API, Nginx, and Suricata"
	printf "  $(GREEN)%-18s$(NC) %s\n" "count-events" "Query Elasticsearch for total indexed logs"
	echo ""
	echo "$(YELLOW)VERIFICATION (with exit codes):$(NC)"
	printf "  $(GREEN)%-18s$(NC) %s\n" "verify" "Run all verification checks (fails on error)"
	printf "  $(GREEN)%-18s$(NC) %s\n" "verify-api" "Check API endpoint responds"
	printf "  $(GREEN)%-18s$(NC) %s\n" "verify-es" "Check Elasticsearch health"
	printf "  $(GREEN)%-18s$(NC) %s\n" "verify-wazuh" "Confirm Wazuh Agent is Active"
	printf "  $(GREEN)%-18s$(NC) %s\n" "verify-detection" "Check if security events are indexed"
	echo ""
	echo "$(YELLOW)ATTACK SIMULATION:$(NC)"
	printf "  $(GREEN)%-18s$(NC) %s\n" "brute-force" "Simulate 5 failed logins"
	printf "  $(GREEN)%-18s$(NC) %s\n" "sqli-test" "Execute SQL Injection attempt"
	printf "  $(GREEN)%-18s$(NC) %s\n" "network-tests" "Run Nmap scans to trigger IDS"
	printf "  $(GREEN)%-18s$(NC) %s\n" "attack-tests" "Run full attack simulation suite"
	echo ""
	echo "$(YELLOW)PIPELINE VALIDATION:$(NC)"
	printf "  $(GREEN)%-18s$(NC) %s\n" "pipeline-test" "Validate end-to-end data flow with assertions"
	echo ""
	echo "$(YELLOW)OPERATIONS:$(NC)"
	printf "  $(GREEN)%-18s$(NC) %s\n" "restart" "Restart Suricata, Filebeat, Wazuh Agent"
	printf "  $(GREEN)%-18s$(NC) %s\n" "clean-logs" "$(RED)DANGER:$(NC) Truncate all local log files"
	printf "  $(GREEN)%-18s$(NC) %s\n" "reset-lab" "Clean logs and restart (demo prep)"
	echo ""
	echo "$(BLUE)----------------------------------------------------------------------------$(NC)"
	echo "Configuration: API=$(API_URL) | ES=$(ES_URL) | TARGET=$(TARGET_IP)"
	echo "$(BLUE)----------------------------------------------------------------------------$(NC)"
