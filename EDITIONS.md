# Skarn editions - the free/paid boundary

Generated from docs/cli-model.toml by docs/build_manpage.py (regenerate with `zig build man`); do not edit by hand. skarn 0.22.0.

One binary for every tier. The free tier is the full local product, not a trial: the entire detection engine, every output format except the Team evidence pack, and redaction, under a free license available to anyone who registers - an individual or an organization alike. Paid tiers unlock org capabilities: distributing policy and accepted-findings baselines across a team, compliance evidence, the maintained feed, and real-time enforcement.

skarn check and the serve security view require a license; the free license is issued at https://getskarn.com/free after a quick email confirmation, needs no payment, and is verified offline against a key embedded in the binary - no activation call, no callback, no kill switch. skarn assess scans this machine with no license at all, and check --audit-verify (verifying an audit log, not scanning) needs none either. A paid flag requested without a covering license refuses fail-closed (exit 5) before any scan; a missing license refuses with exit 7. Tiers are cumulative: Team includes Free; Enterprise includes Team.

## Free

| Capability | Why it is free |
|---|---|
| skarn assess - the zero-config machine-scan wedge | One command scans every AI session on the machine and prints a friendly risk summary plus an optional shareable redacted report; no flags, no config, no license. Add --dossier to scope a shareable incident dossier to one finding or session. |
| skarn vet - static vetting of the local AI assistant configuration | A read-only, offline pass over the operator's own hooks, MCP servers, permission grants, and installed extensions. The entire local detection engine is free; the paid asset is org distribution and the maintained feed, not the engine. |
| skarn check - the full local scan | Every bundled detection rule, behavioral attack-chain correlation, the risk score, decode-then-rescan, canary checks - under the free license, issued at https://getskarn.com/free after a quick email confirmation. The scanner is not crippled. |
| Output formats text, json, sarif, ndjson | Output formats are not a paid line; CI and SIEM ingest work on the free tier. The one exception is --format evidence, the Team evidence pack. |
| Redaction, in every format | Safety is not a tier. |
| CI gating: --fail-on-severity, --fail-on-risk, --fail-on-scan-error, the exit-code contract | A scanner that cannot fail CI is crippled; individual CI use is free. |
| Personal baseline: --baseline <file>, --baseline-create | Accept-and-diff is the single-developer workflow. |
| Custom rules and local detectors: --rules, --no-default-rules, --check-code, --check-packages, --sbom | The entire local detection engine is free; the paid asset is the maintained feed, not the engine. Reconciling your own SBOM against your own sessions on your own machine is local surfacing, not distribution. |
| All recall commands: search, recent, stats, tools, mcps, cmds, export, messages, restore | The daily-use surface: session search, browsing, and analytics need no license. |
| skarn serve - the localhost web UI | Single-user, 127.0.0.1 only; the paid surface is the future fleet console, not your own browser. The recall views need no license; the security view requires the free license, exactly like check. |
| skarn guard - audit mode | Reports would-be verdicts and does not block; a lapsed license does not break an editor. |
| skarn guard accept and the guard's baseline consult | The audit-to-enforce ramp needs an accept path or a pilot with recurring false positives can never reach a flippable window; the personal baseline is already free, and the guard only ever reads its file form. |
| skarn setup and skarn guard --self-test - guided onboarding and wiring verification | The path TO the guard: agent detection, merge-based hook install with backups, and the end-to-end self-test work unlicensed. |
| skarn taxonomies and --audit-verify | Auditors verify evidence and the standards crosswalk without a license. |

## Team

| Capability | In the free tier | Why it is paid |
|---|---|---|
| skarn guard - enforce mode | No - an unlicensed guard is forced to audit mode (reports the would-be verdict without blocking, exits 0; a license problem never breaks an editor) | Real-time blocking (deny/ask verdicts); any paid tier unlocks it. |
| --feed, --update-rules, --feed-url | No - refuses fail-closed with exit 5 before any scan | The maintained feed is the renewal engine: signed detection-rule and AI-attack updates between releases, verified locally against an embedded key. |
| --policy | No - refuses fail-closed with exit 5 before any scan | Policy-as-code distributed across an org is centralization; the embedded default policy is free. |
| --baseline-merge | No - refuses fail-closed with exit 5 before any scan | Org-distributed accepted-findings sets with per-entry provenance; a personal baseline file is free. |
| --audit-log | No - refuses fail-closed with exit 5 before any scan | Tamper-evident scan records are org compliance evidence. |
| --baseline <directory> (org union) | No - refuses fail-closed with exit 5 before any scan | Unions every member's accepted-findings set at scan time; a personal baseline file is free. |
| Evidence pack: check --format evidence | No - with a registered free license, check --format evidence refuses fail-closed with exit 5 before any scan runs (a machine with no usable license is refused earlier, at exit 7); the free formats text, json, sarif, and ndjson are unaffected | A redacted Markdown record of one scan - coverage, findings and dispositions, baseline triage, and the audit-chain reference - shaped to file into a product technical file, with release-lineage fields (--product, --product-version, --build-id, --sbom-ref) binding it to a build. Org compliance evidence, the same class as the Team audit log it references. It is tamper-evident against in-place edits and reordering of the referenced audit records; it is NOT signed and does NOT provide cryptographic non-repudiation. |

## Enterprise

| Capability | In the free tier | Why it is paid |
|---|---|---|
| --profile | No - refuses fail-closed with exit 5 before any scan | Count-aware dedup and reshape for fleet-scale reporting. |
| --fleet | No - refuses fail-closed with exit 5 before any scan | Fleet aggregation across machines is the org console surface; every single-machine view stays free. |
| Fleet roster view: serve --fleet (preview) | No - refuses fail-closed with exit 5 before any scan | Renders an org-produced aggregate of per-machine redacted scan artifacts - roster, compliance strip, auditor evidence. Skarn neither collects nor transmits fleet data; the aggregate is assembled from artifacts each machine drops on an org-controlled store. |
| Fleet console, SSO/RBAC, central reporting (roadmap) | No - not built yet | Org-scale centralization, reserved in the entitlement layer. |
