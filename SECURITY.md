# Security Policy

## Scope

This repository is a **Claude Code skill wrapper** around the
[Keygraph Shannon](https://github.com/KeygraphHQ/shannon) pentesting engine.
It contains Markdown instructions and two installer/sync helper scripts —
no network services, no credentials, no exploit payloads of its own.

The skill orchestrates **real attacks** via Shannon's Docker containers.
Only run pentests against systems you own or have **explicit written
authorization** to test. Never target production.

## Reporting a vulnerability

If you find a security issue in this skill (e.g. a script that could be
abused to run unintended commands, a prompt-injection vector in the skill
instructions, unsafe handling of credentials):

- **Do not** open a public issue with exploit details.
- Contact the maintainer via a private channel
  (GitHub private vulnerability reporting on this repo, if enabled,
  or a direct message to [@Benqxc](https://github.com/Benqxc)).
- Include: affected file + version/commit, impact, and steps to reproduce.

We aim to acknowledge reports within 72 hours.

## What is in scope

- `SKILL.md` instructions (authorization bypasses, prompt-injection,
  unsafe defaults)
- `scripts/setup-shannon.sh`, `scripts/sync.sh` (command injection,
  path traversal, unsafe writes outside the intended targets)

## Out of scope

- Vulnerabilities in Shannon itself → report to
  [KeygraphHQ/shannon](https://github.com/KeygraphHQ/shannon/security)
- Vulnerabilities found **by** Shannon in third-party targets
- Social engineering, physical attacks, spam

## Safe harbor

Security research conducted in good faith against this repository,
without attacking production systems or accessing other users' data,
will not result in legal action from the maintainer.
