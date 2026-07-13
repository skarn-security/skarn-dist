# Skarn editions - the free/paid boundary

Generated from docs/cli-model.toml by docs/build_manpage.py (regenerate with `zig build man`); do not edit by hand. skarn 0.17.2.

One binary for every tier. The free tier is the full local product, not a trial: the entire detection engine, every output format, and redaction are free for an individual on their own machines. Paid tiers unlock org capabilities: distributing policy and accepted-findings baselines across a team, compliance evidence, the maintained feed, and real-time enforcement.

A paid flag requested without a covering license refuses fail-closed (exit 5) before any scan runs; the free core does not exit 5. Licenses are Ed25519-signed tokens verified locally against a key embedded in the binary - no activation, no callback, no kill switch. Tiers are cumulative: Team includes Free; Enterprise includes Team.

## Free

| Capability | Why it is free |
|---|---|
| skarn assess - the zero-config machine-scan wedge | One command scans every AI session on the machine and prints a friendly risk summary plus an optional shareable redacted report; no flags, no config, no license. |
| skarn vet - static vetting of the local AI assistant configuration | A read-only, offline pass over the operator's own hooks, MCP servers, permission grants, and installed extensions. The entire local detection engine is free; the paid asset is org distribution and the maintained feed, not the engine. |
| skarn check - the full local scan | Every bundled detection rule, behavioral attack-chain correlation, the risk score, decode-then-rescan, canary checks. The scanner is not crippled. |
| All output formats: text, json, sarif, ndjson | Output formats are not a paid line; CI and SIEM ingest work on the free tier. |
| Redaction, in every format | Safety is not a tier. |
| CI gating: --fail-on-severity, --fail-on-risk, --fail-on-scan-error, the exit-code contract | A scanner that cannot fail CI is crippled; individual CI use is free. |
| Personal baseline: --baseline <file>, --baseline-create | Accept-and-diff is the single-developer workflow. |
| Custom rules and local detectors: --rules, --no-default-rules, --check-code, --check-packages | The entire local detection engine is free; the paid asset is the maintained feed, not the engine. |
| All recall commands: search, recent, stats, tools, mcps, cmds, export, messages, restore | The daily-use surface: session search, browsing, and analytics need no license. |
| skarn serve - the localhost web UI | Single-user, 127.0.0.1 only; the paid surface is the future fleet console, not your own browser. |
| skarn guard - audit mode | Reports would-be verdicts and does not block; a lapsed license does not break an editor. |
| skarn setup and skarn guard --self-test - guided onboarding and wiring verification | The path TO the guard: agent detection, merge-based hook install with backups, and the end-to-end self-test work unlicensed. |
| skarn taxonomies and --audit-verify | Auditors verify evidence and the standards crosswalk without a license. |

## Team

| Capability | Why it is paid |
|---|---|
| --feed, --update-rules, --feed-url | The maintained feed is the renewal engine: signed detection-rule and AI-attack updates between releases, verified locally against an embedded key. |
| --policy | Policy-as-code distributed across an org is centralization; the embedded default policy is free. |
| --baseline-merge | Org-distributed accepted-findings sets with per-entry provenance; a personal baseline file is free. |
| --audit-log | Tamper-evident scan records are org compliance evidence. |
| --baseline <directory> (org union) | Unions every member's accepted-findings set at scan time; a personal baseline file is free. |
| skarn guard - enforce mode | Real-time blocking (deny/ask verdicts); any paid tier unlocks it. |

## Enterprise

| Capability | Why it is paid |
|---|---|
| --profile | Count-aware dedup and reshape for fleet-scale reporting. |
| Fleet console, SSO/RBAC, central reporting (roadmap) | Org-scale centralization, reserved in the entitlement layer. |
