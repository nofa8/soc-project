# Changelog

## v4.1 (2026-01-18)
- Makefile refactored to orchestration-only layer
- Script modularization (attacks/, scripts/)
- Formal contracts added to all scripts
- Exit code standard documented (0/1/2/≥10)
- Hydra-based brute-force stimulus added
- lib/ skeleton created (timing.sh, colors.sh)
- docs/architecture.md added

## v4.0 (2026-01-17)
- Firewall log ingestion fixed (systemd export service)
- Rule 100030/100031 verified working
- Comprehensive test validation completed
- Keycloak identity provider integrated

## v3.0 (2026-01-16)
- Initial production-grade Makefile
- 10 custom Wazuh detection rules
- Full 13-service Docker Compose stack
