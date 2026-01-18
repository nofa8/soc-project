# SOC Orchestration Architecture

## Overview

This document describes the architectural design of the SafePay SOC automation layer.

---

## Control Plane vs Execution Plane

| Layer | Responsibility | Implementation |
|-------|----------------|----------------|
| **Control Plane** | Sequencing, gating, UX | `Makefile` |
| **Execution Plane** | Logic, assertions, stimuli | `scripts/`, `attacks/` |

**Principle:** The Makefile never implements detection logic. It only orchestrates.

---

## Trust Boundaries

```
┌─────────────────────────────────────────────────────────┐
│                    Host System                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │  Makefile   │→→│  scripts/   │→→│  Docker Compose │ │
│  │ (orchestrate)│  │ (execute)   │  │  (containers)   │ │
│  └─────────────┘  └─────────────┘  └─────────────────┘ │
│         │                                    │          │
│         └────────────┬───────────────────────┘          │
│                      ▼                                  │
│              ┌───────────────┐                          │
│              │  Wazuh Manager │ ← Detection logic here  │
│              └───────────────┘                          │
└─────────────────────────────────────────────────────────┘
```

---

## Failure Domains

| Exit Code | Meaning | Recovery |
|-----------|---------|----------|
| 0 | Success | Continue |
| 1 | Detection failure | Investigate SIEM |
| 2 | Tool unavailable | Skip gracefully |
| ≥10 | Infrastructure down | Fix before proceeding |

---

## Why Makefile?

### Alternatives Considered

| Tool | Rejected Because |
|------|------------------|
| **Python** | Collapses control/execution planes |
| **Ansible** | Overkill for local orchestration |
| **Shell script** | No built-in dependency/target graph |
| **Docker Compose only** | No assertion/gating capability |

### Why Makefile Wins

1. **Explicit dependency graph** – targets can depend on gates
2. **Idempotent by design** – re-running is safe
3. **Universal** – available on any Unix system
4. **Transparent** – no hidden state, no magic

---

## Directory Structure

```
├── Makefile              # Control plane (orchestration only)
├── scripts/
│   ├── check_alert.sh    # Detection verification
│   ├── check_pipeline.sh # Health checks
│   └── lib/
│       ├── timing.sh     # Backoff utilities
│       └── colors.sh     # Terminal UX
├── attacks/
│   ├── brute_force.sh    # Deterministic stimulus
│   ├── brute_force_hydra.sh # Realistic stimulus (optional)
│   ├── sqli.sh
│   ├── vpn_noise.sh
│   └── firewall_scan.sh
└── docs/
    ├── architecture.md   # This file
    └── test-results.md   # Validation evidence
```

---

## MODE System

MODE controls **timing and strictness**, never detection semantics.

| MODE | ALERT_RETRIES | ALERT_INTERVAL | Use Case |
|------|---------------|----------------|----------|
| demo | 6 | 5s | Live demonstrations |
| assurance | 12 | 10s | CI/CD validation |

**Invariant:** MODE never changes rule IDs, queries, or thresholds.
