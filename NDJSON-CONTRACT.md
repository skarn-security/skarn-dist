# Skarn NDJSON event contract

`skarn check --format ndjson` writes one JSON document per line and no outer array, and `skarn inventory --format ndjson` writes one line of the same stream. This file is the field contract for that stream: which datasets exist, which keys each line carries, where each value comes from, and what a consumer can rely on across releases. Field names follow the Elastic Common Schema (ECS) where an ECS field fits, and use the `skarn.` prefix where none does.

## Version

This is contract version 1. A key is added without a version change; a key that is renamed or removed, or a value whose meaning changes, would start contract version 2. The binary that wrote a line is named by `skarn.version` on that line.

## Event envelope

Every line of every dataset carries these keys.

| Key | Value |
|-----|-------|
| `@timestamp` | The end of the run in UTC, or on a finding line the last time the finding was seen in its session when the session recorded one. |
| `ecs.version` | `1.0.0`. |
| `event.kind` | `event` on `skarn.scan` and `skarn.coverage` lines, `alert` on `skarn.findings` lines, `state` on the `skarn.inventory` line. |
| `event.category` | An array: `configuration` on the summary and the inventory line, `file` on coverage lines, `threat` on findings. |
| `event.type` | An array: `info`. |
| `event.outcome` | `success`, except `failure` on a coverage line and on an inventory line whose collection failed. |
| `event.dataset` | `skarn.scan`, `skarn.coverage`, `skarn.findings` or `skarn.inventory`. |
| `event.action` | `scan-completed` on the summary, `records-skipped` on a coverage line, the rule id on a finding, `inventory-collected` on the inventory line. |
| `message` | A one-sentence description of the line. |
| `skarn.run_id` | The run's identifier, equal to the trailing component of the SARIF `automationDetails.id` of the same run. |
| `skarn.version` | The Skarn version that wrote the line. |

## Scanner identity

Scanner identity names the machine and the account that ran the scan. Every line of every dataset carries these keys when the value is known; an unknown value omits its key, and no key is ever written as an empty string.

| Key | Source |
|-----|--------|
| `host.name` | The host name of the scanning machine: `gethostname` on macOS and Linux, `COMPUTERNAME` on Windows. It is the same value the `--drop` artifact carries. |
| `skarn.identity` | The `SKARN_IDENTITY` environment variable. |
| `skarn.org` | The `SKARN_ORG` environment variable. |
| `skarn.scanner_user` | The operating system account that ran the scan: `USER`, then `LOGNAME`, on macOS and Linux; `USERNAME` on Windows. A value that contains `@` is written as `****`. |

Skarn does not authenticate any of these values. `SKARN_IDENTITY` and `SKARN_ORG` are tags the operator supplies for attribution and are written exactly as supplied, so an email address placed in `SKARN_IDENTITY` reaches the stream unmasked. The account name is read from the environment the scan ran in. The mask covers the `skarn.scanner_user` key only: `file.path`, `skarn.project_root` and the other path keys are written as recorded, so on a machine whose home directory embeds the account name (`/home/dev.person@example.com`, for example) those paths carry it unmasked.

The account that ran the scan is never written as `user.name` or `user.id`. A scan can run as SYSTEM, as a CI principal or as an administrator, so the account that ran it is not the person whose session holds the finding. The ECS `user.*` keys are kept for subject identity.

## Subject identity

Subject identity names the person whose session holds the finding. Each key below is written when the transcript recorded its value and omitted otherwise. Today only a Claude Enterprise Compliance API export records the session's user; no local session store records one, so a line read from a local store carries none of these keys.

| Key | Lines | Value |
|-----|-------|-------|
| `user.id` | findings, coverage | The user id the export recorded, as recorded. Omitted when the export recorded none. |
| `user.email` | findings, coverage | Always `****` when the export recorded an email address, and omitted when it recorded none. The mask says an address exists and is withheld. |
| `skarn.workspace_id` | findings | The workspace id the export recorded, as recorded. |
| `skarn.user_id` | coverage | The same value as `user.id`, kept on coverage lines for consumers written before `user.id` existed there. |
| `skarn.subject_host` | findings, coverage | `export` on every line read from a Compliance API export, and absent on every other line. |

`skarn.subject_host` is set from the file format Skarn parsed, never inferred from the other subject keys, because a valid export can carry a null or missing user id. On a line read from an export, `host.name` still names the machine that scanned the export, not a machine the exported session ran on.

## Assistant identity

| Key | Lines | Value |
|-----|-------|-------|
| `skarn.cli` | findings, coverage | The assistant whose session the line was read from, such as `claude`, `codex` or `cursor`. On a finding line it is omitted when the assistant is unknown; on a coverage line it is always written, empty when the assistant is unknown. |
| `skarn.clis` | summary | An array of the distinct assistants whose sessions the run read in scope. Order is not significant. It is always present, and `[]` means no session was read in scope. |

An export's `skarn.cli` is a Claude family label taken from the export's product surface: `claude` for a Claude Code session, `cowork` for a Cowork session, and `claude_enterprise` for every other surface. `claude` is the same label a local Claude Code store carries, so `skarn.subject_host` is the marker that tells an export line apart.

## Dataset `skarn.scan`

One summary line per run, written first, so a SIEM has a record of the run even when it found nothing. Beside the envelope and scanner identity it carries `skarn.clis` and these counters, each an integer: `skarn.sessions_scanned`, `skarn.findings` (findings not suppressed), `skarn.suppressed`, `skarn.chain_count`, `skarn.risk_score`, `skarn.verdict` (the exit code the run computed), `skarn.tools_dropped`, `skarn.stores_unreadable`, `skarn.sessions_incomplete`, `skarn.sessions_truncated`, `skarn.turns_unavailable`, `skarn.turns_unverified`, `skarn.compliance_withheld`, `skarn.records_skipped`, `skarn.records_truncated`, `skarn.records_shortened`, `skarn.records_depth_cut` and `skarn.records_uncaptured`.

## Dataset `skarn.coverage`

One line per session file that holds at least one record Skarn could not parse, one string value it shortened, or one value nested too deep to scan. Other coverage gaps (a session whose behavioral parse was partial, a truncated or compacted transcript, a turn the export withheld or did not verify, an unreadable store) are counted only in the summary counters and produce no coverage line. Beside the envelope and scanner identity it carries `file.path`, `skarn.cli`, `skarn.project` and `skarn.project_root` when known, the subject keys above when the file is an export, and the per-file counters `skarn.records_skipped`, `skarn.records_truncated`, `skarn.records_shortened`, `skarn.records_depth_cut` and `skarn.records_uncaptured`.

## Dataset `skarn.findings`

One alert per finding, suppressed findings included. Beside the envelope, scanner identity and `skarn.cli` it carries:

| Key | Value |
|-----|-------|
| `event.id` | The finding fingerprint, the same value as `skarn.fingerprint`. |
| `event.severity` | 25 low, 50 medium, 75 high, 99 critical. |
| `file.path` | The session file, when known. |
| `log.file.line` | The first line of the session file that holds the finding, when known. |
| `skarn.project`, `skarn.project_root` | The project of the session, when known. |
| `skarn.rule_id` | The rule that matched. |
| `skarn.fingerprint` | The finding fingerprint (see the check JSON section). |
| `skarn.product_surface`, `skarn.exported_at` | On an export line only: the product surface the export recorded, and the export time when it is a valid UTC timestamp. |
| `user.id`, `user.email`, `skarn.workspace_id`, `skarn.subject_host` | Subject identity, as the Subject identity section describes. |
| `skarn.match_preview` | The matched value, always redacted; absent on a finding with no matched value. |
| `skarn.risk_score` | The run's risk score. |
| `skarn.chain_id` | The attack chain the finding belongs to, as an integer, when it belongs to one. |
| `skarn.suppressed` | `true` when a baseline or policy suppressed the finding. |
| `skarn.confidence` | `high`, `medium` or `low`. |
| `skarn.likely_test_value` | `true` when the matched value looks like a test value. |
| `skarn.also_matched`, `skarn.grouped_under` | Other rules that matched the same value, and the finding this one is grouped under, when either applies. |
| `skarn.taxonomy` | An array of the OWASP LLM Top 10, MITRE ATLAS and CWE identifiers the rule maps to. |

## Fields by dataset

Y means the key is on every line of that dataset, K means it is present when its value is known or applies, and a dash means it is never present. The check JSON column names the key `skarn check --format json` uses for the same value on each incident.

| Key | skarn.scan | skarn.coverage | skarn.findings | skarn.inventory | check JSON |
|-----|-----------|----------------|----------------|-----------------|------------|
| envelope keys | Y | Y | Y | Y | - |
| `host.name` | K | K | K | K | - |
| `skarn.identity` | K | K | K | K | - |
| `skarn.org` | K | K | K | K | - |
| `skarn.scanner_user` | K | K | K | K | - |
| `skarn.cli` | - | Y | K | - | `cliName` |
| `skarn.clis` | Y | - | - | - | - |
| `file.path` | - | Y | K | - | `sessionFile` |
| `skarn.project` | - | K | K | - | `project` |
| `skarn.project_root` | - | K | K | - | `projectRoot` |
| `user.id` | - | K | K | - | `userId` |
| `user.email` | - | K | K | - | `userEmail` |
| `skarn.user_id` | - | K | - | - | `userId` on `skippedRecords` |
| `skarn.workspace_id` | - | - | K | - | `workspaceId` |
| `skarn.subject_host` | - | K | K | - | - |
| `skarn.fingerprint` | - | - | Y | - | `fingerprint` |
| `skarn.chain_id` | - | - | K | - | `chainId` |
| summary counters | Y | - | - | - | top-level counters |
| per-file counters | - | Y | - | - | `skippedRecords` |

## Check JSON fingerprint and chainId

Each incident in `skarn check --format json` carries `fingerprint`, equal to the `skarn.fingerprint` of the same finding in the NDJSON stream, and `chainId`, equal to its `skarn.chain_id`, as an integer and only when the finding belongs to an attack chain. A finding with no chain has no `chainId` key, never a null.

The fingerprint of a finding with a matched value is the SHA-256 of the rule id, a NUL byte, and the lowercase hex SHA-256 of the ASCII-lowercased value. The fingerprint of a finding with no matched value is the SHA-256 of the rule id, a NUL byte, the literal text `session:`, and the lowercase hex SHA-256 of the session file path exactly as written, so it is stable per rule per session file. The hash is deterministic and unkeyed, so a guessable value can be recovered from it by testing candidates wherever the output travels.

When several sightings of the same value are merged into one finding, the finding keeps the first chain association it saw, so a value that took part in several chains shows one `chainId`.

## Compatibility

New keys are additive. No key is renamed or removed within a contract version, and `skarn.user_id` on coverage lines stays beside `user.id`. A consumer that ignores keys it does not know keeps working across releases.

A key keeps one type within a dataset, but `skarn.suppressed` changes type across datasets: it is an integer count on the summary line and a boolean on a finding line. A store that maps one type per field across the whole stream routes or renames by `event.dataset` before indexing.

`skarn.project`, `skarn.project_root` and `file.path` are written whether or not the run declared `--project`, so a stream sent to a shared SIEM names the projects and session files present on the scanning machine.

A store with a fixed column list drops keys it does not declare. The Microsoft Sentinel direct data collection rule passes the stream through unchanged, so a key the custom table does not declare is dropped until the table adds the column; the agent data collection rule and the `jq` sender carry only the keys their projection names. Adding a key to the stream therefore reaches those paths only when the kit projects it.

## Dataset `skarn.inventory`

One line per run that says which assistants this machine has, how completely Skarn could observe each one, which MCP servers their configuration declares and their sessions called, and which guard mode is configured. `skarn check --format ndjson` writes it directly after the `skarn.scan` summary, and `skarn inventory --format ndjson` writes it alone; `skarn inventory --format json` prints the same object indented. No other `check` format carries the inventory.

Both commands build the line with the same code from their own read of the machine, so for the same `--hours`, `--cli`, `--project`, `--user` and `--rules` the two lines are identical except `@timestamp`, `skarn.collected_at` and `skarn.run_id`. A rule that `check` loads through `--feed` or `--update-rules` does not reach the inventory line. To build it, both commands read the session stores, the assistant configuration files `skarn vet` reads, the guard configuration layers and the installed license, all read-only; so `check --format ndjson` reads configuration files that the other `check` formats do not.

Beside the envelope and scanner identity, where `event.kind` is `state`, `event.category` is `["configuration"]` and `event.action` is `inventory-collected`, the line carries:

| Key | Value |
|-----|-------|
| `skarn.collected_at` | The time the collection finished, in UTC, as `YYYY-MM-DDTHH:MM:SSZ`. |
| `skarn.window_hours` | The `--hours` window as an integer; `0` means the whole history. |
| `skarn.scope.declared` | `true` when the run declared `--project`. |
| `skarn.scope.resolved` | On a scoped run only: up to 16 project names of sessions that passed every filter, in byte order. Omitted when no session matched. |
| `skarn.scope.project_roots_truncated` | On a scoped run only: `true` when more than 16 project roots matched, in which case only the first 16 in byte order were read. |
| `skarn.assistants_truncated` | `true` when more than 32 assistants were found and the list stops at 32. |
| `skarn.compliance_withheld` | Compliance API export sessions withheld because no Enterprise license covers that source, the same count the summary carries. |
| `skarn.guard_mode` | `enforce`, `audit` or `none`: the mode the configured guard hooks ask for. Omitted when the hook configuration could not be resolved. |
| `skarn.guard_effective` | The mode the guard runs in: `audit` when `skarn.guard_mode` is `enforce` and no paid license is installed, otherwise `skarn.guard_mode`. Omitted together with `skarn.guard_mode`. |
| `skarn.assistants` | An array of assistant objects, one per assistant, ordered by name. |

Each assistant object carries:

| Key | Value |
|-----|-------|
| `name` | The assistant's built-in name, such as `claude`, `codex` or `copilot-code`. A custom tool from `~/.skarn.json` is reported under the built-in assistant it is based on, never under its own name. Sessions read from a Compliance API export are reported under `claude`, `cowork` or `claude_enterprise`, the label `skarn.cli` carries for them. |
| `state` | How completely the session side was observed, from the closed set below. |
| `state_reason` | The condition that decided `state`, from the closed set below. Omitted when `state` is `observed`. |
| `config_state` | How completely the declared configuration was observed, from the same closed set. |
| `store_roots` | Up to 8 declared session store roots, rendered as anchors. A root is declared, not proven to exist. |
| `store_roots_truncated` | `true` when the store root list was cut at 8. |
| `custom_sources` | The number of custom-tool store roots, each rendered `<custom>`. |
| `versions` | Up to 8 objects `{component, version, observed_at}`, newest first: a client version observed in a session at `observed_at`, the latest start time of the sessions that recorded it, omitted when none parses. `component` is `copilot`, `vscode` or `opencode`. `version` is the numeric core only, one to four dot-separated groups of one to five digits; a suffix that starts with `-` or `+` is dropped. This is never an installed version. |
| `versions_supported` | `true` when this build reads a client version from that assistant's sessions; an empty `versions` list on an assistant with `false` says nothing about versions. |
| `versions_rejected` | Observed values with no numeric core, dropped. |
| `versions_suffix_dropped` | Observed values whose suffix was dropped. |
| `versions_truncated` | `true` when more than 8 distinct versions were observed. |
| `declared_servers` | The MCP servers the assistant's configuration declares, described below. |
| `called_servers` | `count`, the distinct MCP servers called in sessions in the window and scope, at most 16, counted by the name the session recorded; `truncated`, `true` when a seventeenth distinct server was called; and on a scoped run `names`, which can be shorter than `count` when masking makes two names identical. |
| `last_activity` | The latest session end time among those sessions, in UTC. Omitted when none parses. |
| `session_count` | The number of those session files. A file reachable through two store roots counts once. |

`declared_servers` carries `sources`, up to 16 rows `{path, state, reason}`, one per configuration file the assistant's `skarn vet` sources name, with `path` rendered as an anchor, `state` one of `observed`, `absent`, `unreadable` or `filtered`, and `reason` on an `unreadable` row only, one of `NetworkPathRefused`, `AccessDenied`, `SymlinkNotFollowed`, `HardLinked` (a project file with more than one link), `NotAFile` (a path that is not a regular file, or not a directory where one was expected) or `ReadFailed` (any other read error); `sources_truncated`; `count`, the declared servers, never capped; `by_transport`, `{stdio, http}`, whose two values sum to `count`; `truncated`, `true` when more than 16 names qualified for `names`; and on a scoped run `names`. A server name counts once per assistant per configuration root (the home directory, one project root, one Copilot in Code profile, the system root), however many files under that root declare it, and a server declared with both a URL and a command counts once, as `http`. Project rows collapse to one row per relative path, rendered `<project>/<path>`, and profile rows to one row per relative path, rendered `<copilot-code-profile>/<path>`.

Counts and booleans are always present, `0` and `false` included. A string or array with no value is omitted, never written empty.

### Anchors

A path on the line is an anchor, never an expanded value: `~` for the home directory, `$COPILOT_HOME` and `$GROK_HOME` when that variable named the directory (otherwise `~/.copilot` and `~/.grok`), `<system>` for the managed configuration root, `<project>` for a matched project root and `<copilot-code-profile>` for a Copilot in Code profile, each followed by the fixed relative path the vet sources name. A store root is the built-in pattern as compiled into Skarn, such as `~/.claude/projects/*/`, or the environment variable that added it, such as `$CODEX_HOME` or `$SKARN_CLAUDE_DIRS[0]` with a zero-based index into the list. A user-named hook file or plugin directory is written as a `<custom>` source row, and a custom-tool store root as `<custom>`, counted in `custom_sources`. A custom tool that is based on no built-in assistant is reported under the name `custom`. No project directory, profile name, account name or override value reaches a path on the line.

### States

`state` and `config_state` take one value from the closed set `observed`, `absent`, `unreadable`, `truncated`, `filtered` and `unsupported`. When several conditions hold, the least complete wins, in the order `unsupported`, `unreadable`, `truncated`, `filtered`, `observed`, `absent`.

| `state` | `state_reason` | Condition |
|---------|----------------|-----------|
| `unsupported` | `no_session_reader` | Skarn vets the assistant's configuration but has no reader for its sessions. |
| `unreadable` | `store_unreadable` | A session store of the assistant could not be read. |
| `unreadable` | `session_unreadable` | A session file could not be parsed. A run with `--project` or `--user` does not count it, because an unparsed session cannot be tied to the scope. |
| `truncated` | `store_truncated` | Discovery stopped at its file limit in a store of the assistant. |
| `truncated` | `tools_dropped` | A store of the assistant was left out of discovery. |
| `truncated` | `records_incomplete` | A session in scope has a record skipped, cut, shortened, cut by depth, not captured or exempted, or a truncated content block. |
| `truncated` | `turns_incomplete` | A session in scope has a turn that is unavailable or not verified. |
| `truncated` | `compacted` | A session in scope carries a compaction marker. |
| `truncated` | `mcp_read_failed` | The MCP calls of a session in scope could not be read. |
| `truncated` | `session_changed` | On a run with `--project`, a session in scope changed between discovery and masking, so it was left out; a later run includes it. |
| `truncated` | `list_capped` | The called-server, version or store root list reached its limit. |
| `filtered` | `cli_filter` | `--cli` named another assistant. |
| `filtered` | `scope_filter` | Sessions exist in the window, but none passed `--project` or `--user`. |
| `absent` | `no_sessions` | No session file was found in the window and nothing was unreadable. This does not claim the store directory is missing. |

When several reasons of the same state hold, `state_reason` names the first in the table. On a run with `--project` or `--user` the store-level reasons (`store_unreadable`, `store_truncated`, `tools_dropped`) do not apply, because a store cannot be tied to a project or a user before it is read; a Compliance API export store cannot be tied to a surface before it is read either, so its store-level gaps never set a `state_reason`; the summary counters carry them for the whole machine. `state` is a coarse roll-up: the `skarn.scan` counters say more, and an assistant can read `observed` while the summary counts a gap in a store that holds no session in scope.

`config_state` is `unsupported` when Skarn reads the assistant's sessions but vets no configuration file for it, `filtered` when `--cli` named another assistant (its configuration is still read and counted, but no name is emitted and every row reads `filtered`), and otherwise the least complete of its source rows: `unreadable`, then `truncated` when a source or name list hit its limit, then `observed`, then `absent`. A file that is read but declares no server is `observed`.

`filtered` means the assistant is present on the machine and the run's filters excluded it; it does not say the client has no sessions.

### Scope and redaction

An unscoped run, one with no `--project`, emits no server name, no project name and no `skarn.scope.resolved`, and its declared-server discovery reads no project-local configuration. The guard mode is resolved from the managed, user and current-directory project hook layers exactly as `skarn check --drop` resolves it, and contributes only the mode. A scoped run adds names under two rules. Called server names come from sessions that passed `--cli`, `--hours`, `--project` and `--user`, including a server that a user-global file also declares, because the session that called it belongs to the declared scope. Declared server names come only from the project-local configuration of a project root that a session in scope recorded; user-global, managed and profile declarations stay counts. A project file that is the same file as a global source is reported once, as its global row. Otherwise a project file names servers only when it is a regular file with a single link, reached with no symbolic link below the project root, whose canonical path lies inside the canonical project root; a project file that fails any of these names nothing and adds no count, and its source row stays and reads `unreadable` with reason `SymlinkNotFollowed`, `HardLinked` or `ReadFailed`. A hook file is judged by its own path, not its directory's. On a scoped run every session-derived key (`called_servers`, `versions`, `last_activity`, `session_count`, `skarn.scope.resolved`) comes from sessions in scope only.

A matched project root that is a network path is never opened: every assistant that reads project-local configuration reports one `unreadable` row `<project>` with reason `NetworkPathRefused`. A configuration file under a local project root whose path links to a network location gets its own `unreadable` row with the same reason.

Every server name and project name on the line passes the credential masking `skarn vet` applies to its locators, the detection rules (including a custom pack named by `--rules`), home-directory masking and a 64-byte limit, which cuts on a character boundary, appends `...` and never splits a mask. A name is never replaced by a hash, because an unkeyed hash of a guessable client name is recoverable by testing candidates. Version and timestamp values are written only in their validated forms.

### Failure line

When the collection fails, the line carries the envelope with `event.outcome` `failure`, scanner identity, `skarn.run_id`, `skarn.collected_at`, `skarn.version` and `error.code`, one of `HomeNotResolvable`, `RedactionUnavailable`, `RulesUnavailable`, `InjectedFailure` or `CollectionFailed`, and no other `skarn.` key. `check` still writes it in second place, prints `inventory could not be collected` on stderr and counts the failure as a scan-infrastructure gap, so `--fail-on-scan-error` turns it into exit 6. Every other verdict (1 for a finding, 2 for the risk score, 3 for a triggered canary, 4 for a policy precondition) takes precedence over that 6, so an exit code alone never shows that the collection completed; read `event.outcome` on the line. `skarn inventory` writes the failure line and exits 6.

## Fields a Defender join needs

Joining a Skarn line with Microsoft Defender data is a design target, not a tested integration. A join needs the machine (`host.name`), the account that ran the scan (`skarn.scanner_user`, which cannot serve as a join key when it is written as `****`) or the operator tags (`skarn.identity`, `skarn.org`), the subject identity on export lines (`user.id`, `skarn.workspace_id`, `skarn.subject_host`), and the assistant (`skarn.cli`). No Defender table has been read for its column names, so the mapping from these keys to Defender columns belongs to the SIEM kit, not to this contract.
