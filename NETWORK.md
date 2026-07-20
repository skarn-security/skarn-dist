# Skarn network contract

This document is normative. It enumerates every outbound network operation the `skarn` binary can perform. Any change to this surface is a breaking change to this contract and must update this document, the telemetry statement at https://getskarn.com/trust/telemetry/, and the CI no-egress gate in the same change.

## The complete egress surface

The binary makes an outbound network connection in exactly two cases. Both are explicit, user-invoked commands. Neither runs as a side effect of any other command.

| Invocation | Protocol | Destination | Payload |
|---|---|---|---|
| `skarn check --update-rules` | HTTPS GET | `--feed-url` value, if configured | The optional bearer token from `$SKARN_FEED_TOKEN`. Nothing about the machine, its sessions, or any finding. |
| `skarn license renew` | HTTPS POST | `https://api.getskarn.com/v1/license/renew`, or `$SKARN_LICENSE_RENEW_URL` | The installed license token, to receive a re-signed artifact. A licensing credential, never session content or a found secret. |

Everything else is offline: `check` (without `--update-rules`), `assess`, `vet`, `guard` (all events, all hosts), `setup`, `doctor`, `baseline`, `eula`, `taxonomies`, `completion`, `license` (bare, status, and install forms), and every recall command (`search`, `recent`, `stats`, `tools`, `mcps`, `cmds`, `export`).

## Listener, not caller

`skarn serve` binds a listener on `127.0.0.1` only. It accepts connections; it never initiates one. This is the only place in the binary a socket is opened outside the two commands above.

## Transport properties

Both egress calls execute through a single subprocess transport (`curl`), with the request body delivered on stdin, never on the command line where it could appear in a process list or shell history. `skarn license renew` refuses a plain-http endpoint (loopback excepted), so a poisoned `$SKARN_LICENSE_RENEW_URL` cannot ship the token in cleartext, and it verifies the returned artifact against the trust bundle embedded in the binary before writing a single byte.

## What is never sent, by construction

No telemetry, no crash reporting, no usage analytics, no update check, no license phone-home. Scan findings, session content, file paths, and redacted previews have no code path to any network operation. The scan works identically with the network cable unplugged.

## Verify this yourself

Run any scan under a syscall or packet trace and observe zero outbound traffic:

```
strace -f -e trace=network skarn assess          # Linux
sudo tcpdump -i any -n & skarn assess; kill %1    # macOS/Linux
```

Or enforce the contract instead of trusting it - everything except the two opt-in commands works identically with the network denied:

```
unshare -n skarn assess                           # Linux, no network namespace
firejail --net=none skarn check                   # Linux, firejail
```

## Continuous enforcement

CI runs the full integration suite - every command surface, including the mock-served renew and feed paths on loopback - inside a network-denied namespace (`scripts/ci/no-egress-integration.sh`). A change that introduces an outbound connection outside this contract fails the build.
