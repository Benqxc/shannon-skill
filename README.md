<div align="center">

# 🔐 Shannon Skill for Claude Code

[![Skill](https://img.shields.io/badge/Claude_Code-skill-7B61FF?style=for-the-badge)](https://github.com/Benqxc/shannon-skill)
[![License](https://img.shields.io/badge/license-AGPL--3.0-blue?style=for-the-badge)](LICENSE)
[![Shannon](https://img.shields.io/badge/powered_by-Keygraph_Shannon-00d4aa?style=for-the-badge)](https://github.com/KeygraphHQ/shannon)

**Autonomous AI pentester as a Claude Code skill.** Wraps [KeygraphHQ/Shannon](https://github.com/KeygraphHQ/shannon) — the white-box security testing framework that analyzes source code, identifies attack vectors, and executes real exploits to prove vulnerabilities before they reach production.

**96.15% exploit success rate** on the [XBOW security benchmark](https://github.com/KeygraphHQ/shannon#benchmarks) (100/104 exploits).

> ⚠️ Shannon executes **real attacks**. Only test systems you own or have explicit written authorization to test. Never run against production.

</div>

---

## Contents

- [Install](#install)
- [Quick start](#quick-start)
- [Usage examples](#usage-examples)
- [Prerequisites](#prerequisites)
- [What Shannon tests](#what-shannon-tests)
- [How it works](#how-it-works)
- [Authentication configuration](#authentication-configuration)
- [Testing local applications](#testing-local-applications)
- [Skill structure](#skill-structure)
- [Development](#development)
- [Troubleshooting](#troubleshooting)
- [Safety](#safety)
- [Credits](#credits)
- [License](#license)

---

## Install

```bash
npx skills add Benqxc/shannon-skill -g -y
```

Or per-project:

```bash
npx skills add Benqxc/shannon-skill
```

Verify prerequisites any time:

```bash
bash scripts/setup-shannon.sh
```

Options: `--repo URL` (fork/mirror), `--branch NAME`, custom install dir as
positional arg or `SHANNON_HOME` env var. See `bash scripts/setup-shannon.sh --help`.

## Quick Start

Once installed, run from Claude Code:

```
/shannon http://localhost:3000 myapp
```

Shannon will:

1. Confirm you have authorization to test the target
2. Clone/update the Shannon framework if not already installed
3. Link your source code into Shannon's workspace
4. Check Docker and API credentials
5. Launch a full autonomous pentest across 5 OWASP categories
6. Report findings with reproducible proof-of-concept exploits

## Usage Examples

Full pentest of a local app:

```
/shannon http://localhost:3000 myapp
```

Pentest a staging environment with a named workspace (resumable):

```
/shannon --workspace=audit-q1 http://staging.example.com backend-api
```

Target specific vulnerability categories:

```
/shannon --scope=xss,injection http://localhost:8080 frontend
```

Check running pentests / view latest report / stop a running pentest:

```
/shannon status
/shannon results
/shannon stop
```

## Prerequisites

### Required

- **Docker** (daemon running) — Shannon runs entirely in containers.
  Install: [docker.com/products/docker-desktop](https://docker.com/products/docker-desktop)
- **Git** — to clone the Shannon framework
- **AI provider credentials** (one of the following):

| Provider | Environment variable |
|----------|---------------------|
| Anthropic API (recommended) | `ANTHROPIC_API_KEY` |
| Anthropic OAuth | `CLAUDE_CODE_OAUTH_TOKEN` |
| AWS Bedrock | `CLAUDE_CODE_USE_BEDROCK=1` + AWS credentials |
| Google Vertex AI | `CLAUDE_CODE_USE_VERTEX=1` + GCP service account |

### Recommended

```bash
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000
```

## What Shannon Tests

Shannon covers **50+ vulnerability types** across 5 OWASP categories, all tested with real exploits:

| Category | What's tested |
|----------|---------------|
| **Injection** | SQL injection (union, blind, time-based), command injection, server-side template injection (SSTI), NoSQL injection, LDAP injection |
| **Cross-Site Scripting** | Reflected XSS, stored XSS, DOM-based XSS, XSS via file upload, mutation XSS |
| **SSRF** | Internal service access, cloud metadata extraction (AWS/GCP/Azure), DNS rebinding, protocol smuggling |
| **Broken Authentication** | Default credentials, JWT flaws (none algorithm, weak signing), session fixation, CSRF, MFA bypass, brute force, account lockout flaws |
| **Broken Authorization** | IDOR, horizontal/vertical privilege escalation, path traversal, forced browsing, mass assignment |

## How It Works

Shannon operates as a multi-agent system with 5 phases:

```
Phase 1: Pre-Recon
├── Static source code analysis
└── External scans (Nmap, Subfinder, WhatWeb)

Phase 2: Recon
└── Live attack surface mapping via headless browser

Phase 3: Vulnerability Analysis (5 parallel agents)
├── Injection agent
├── XSS agent
├── SSRF agent
├── Authentication agent
└── Authorization agent

Phase 4: Exploitation (parallel)
├── Each vuln agent spawns an exploitation agent
└── Real attacks executed to validate findings

Phase 5: Reporting
├── Executive summary
└── Reproducible PoC for every finding
```

**No exploit, no report** — Shannon only reports vulnerabilities it can prove with a working proof-of-concept, which minimizes false positives.

### Integrated security tools (bundled in Docker)

- **Nmap** — port scanning and service detection
- **Subfinder** — subdomain enumeration
- **WhatWeb** — web technology fingerprinting
- **Schemathesis** — API schema-based fuzzing
- **Chromium/Playwright** — headless browser for automated exploitation

### Runtime

- **Duration**: ~1–1.5 hours for a full pentest
- **Cost**: ~$50 using Claude Sonnet

## Authentication Configuration

For targets that require login, the skill helps you create a YAML config:

```yaml
# configs/target-config.yaml
authentication:
  type: form                    # "form" or "sso"
  login_url: "http://localhost:3000/login"
  credentials:
    username: "testuser"
    password: "testpass123"
    totp_secret: "BASE32SECRET"  # optional, for 2FA
  flow: "Navigate to login page, enter username and password, click Sign In"
  success_condition:
    url_contains: "/dashboard"

rules:
  avoid:
    - "/logout"
    - "/admin/dangerous-action"
  focus:
    - "/api/"
    - "/auth/"

pipeline:
  max_concurrent_pipelines: 5   # 1-5, default 5
  retry_preset: subscription    # extended backoff for rate-limited API plans
```

## Testing Local Applications

Shannon runs inside Docker, so `localhost` on your machine isn't reachable from the container. The skill automatically handles this, but for reference:

| Platform | Use this instead of localhost |
|----------|------------------------------|
| macOS / Windows | `http://host.docker.internal:PORT` |
| Linux | `http://host.docker.internal:PORT` (may need `--add-host` flag) |

## Skill Structure

```
shannon-skill/
├── SKILL.md                    # Skill definition (metadata + Claude instructions)
├── CLAUDE.md                   # Project contributor instructions
├── README.md                   # This file
├── LICENSE                     # AGPL-3.0 (same as Shannon)
├── SECURITY.md                 # Security policy
└── scripts/
    ├── setup-shannon.sh        # Installs/updates Shannon, checks prerequisites
    └── sync.sh                 # Deploys skill to ~/.claude, ~/.agents, ~/.codex
```

## Development

Deploy locally after edits:

```bash
bash scripts/sync.sh
```

This syncs the skill to `~/.claude/skills/shannon/`, `~/.agents/skills/shannon/`,
and `~/.codex/skills/shannon/`. Use `bash scripts/sync.sh --target DIR` to
sync a single directory, or `--list` to print the defaults.

Run the setup script standalone:

```bash
bash scripts/setup-shannon.sh
```

Checks Docker (CLI + daemon), Git, clones/updates Shannon, and validates
that AI credentials are present (presence only — validity is not tested).

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `docker ... daemon is not reachable` | Docker Desktop stopped | Start Docker Desktop / `dockerd`, then re-run |
| `git pull failed` in existing checkout | Local changes / diverged branch | Resolve in `$SHANNON_HOME` or move it aside and re-run |
| `... exists but is not a Shannon git checkout` | Stale or unrelated dir at install path | Move it aside or set `SHANNON_HOME` elsewhere |
| `No AI credentials detected` | Env vars not exported | Export one provider key (see table above) |
| Target on `localhost` unreachable | Container can't see host loopback | Use `http://host.docker.internal:PORT` |
| `sync.sh` reports `N failed` | Missing permissions on a target dir | Check ownership of `~/.claude` / `~/.agents` / `~/.codex`, or use `--target` for one dir |

## Safety

Shannon executes **real attacks** against targets. The skill enforces safety at every step:

- **Authorization gate** — asks for confirmation before every pentest
- **Environment check** — warns against production targets
- **Scope control** — lets you limit which vulnerability categories to test
- **Avoid rules** — config option to exclude sensitive paths (e.g. `/logout`, `/admin/delete`)
- **Containerized** — all attack tools run inside Docker, not on your host

**Never run Shannon against systems you don't own or have explicit written authorization to test.**

## Credits

- **Shannon** by [KeygraphHQ](https://github.com/KeygraphHQ/shannon) — the autonomous pentesting engine (AGPL-3.0)
- **Skill wrapper** — converts Shannon into a Claude Code `/shannon` slash command

## License

AGPL-3.0 — same as Shannon itself. See [LICENSE](LICENSE).
