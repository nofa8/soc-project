# --------------------
# Configuration (defaults)
# --------------------
SUDO      ?= sudo
TARGET_IP ?= 192.0.2.10
NETWORK   ?= 192.0.2.0/24
API_URL   ?= http://192.0.2.10

-include .env

# --------------------
# Phony targets
# --------------------
.PHONY: all api-tests network-tests \
		login-success login-failure sqli-test \
		nmap-host nmap-ports nmap-services help

all: api-tests network-tests


# API SECURITY TESTS
api-tests: login-success login-failure sqli-test

login-success:
	@echo "[API] Successful login test"
	curl -s -X POST $(API_URL)/login \
		-H "Content-Type: application/json" \
		-d '{"username":"user","password":"pass"}'
	@echo ""

login-failure:
	@echo "[API] Failed login test (should log security event)"
	curl -s -X POST $(API_URL)/login \
		-H "Content-Type: application/json" \
		-d '{"username":"admin","password":"wrong"}'
	@echo ""

sqli-test:
	@echo "[API] SQL injection detection test"
	curl -s "$(API_URL)/items/1%20OR%201=1"
	@echo ""


# NETWORK SECURITY TESTS
network-tests: nmap-host nmap-ports nmap-services

nmap-host:
	@echo "[NMAP] Host discovery on $(NETWORK)"
	nmap -sn $(NETWORK)
	@echo ""

nmap-ports:
	@echo "[NMAP] TCP port scan on $(TARGET_IP)"
	$(SUDO) nmap -sS $(TARGET_IP)
	@echo ""

nmap-services:
	@echo "[NMAP] Service and version detection on $(TARGET_IP)"
	$(SUDO) nmap -sV $(TARGET_IP)
	@echo ""


# HELP
help:
	@echo "Available targets:"
	@echo "  make                Run all API and network tests"
	@echo "  make api-tests      Run API security tests only"
	@echo "  make network-tests  Run Nmap-based network tests"
	@echo "  make nmap-ports     Run TCP port scan"
	@echo ""
	@echo "Configurable variables:"
	@echo "  SUDO      (default: sudo)"
	@echo "  TARGET_IP (default: 192.0.2.10)"
	@echo "  NETWORK   (default: 192.0.2.0/24)"
	@echo "  API_URL   (default: http://192.0.2.10)"