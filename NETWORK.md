# Skarn network contract

This document is normative. It enumerates every outbound network operation the `skarn` binary can perform. Any change to this surface is a breaking change to this contract and must update this document, the telemetry statement at https://getskarn.com/trust/telemetry/, and the CI no-egress gate in the same change.

## The complete egress surface

The binary makes an outbound network connection in exactly two cases. Both are explicit, user-invoked commands. Neither runs as a side effect of any other command.

| Invocation | Protocol | Destination | Payload |
|---|---|---|---|
| `skarn check --update-rules` | HTTPS GET, or plain HTTP to loopback | `--feed-url` value, if configured | The optional bearer token from `$SKARN_FEED_TOKEN`. Nothing about the machine, its sessions, or any finding. |
| `skarn license renew` | HTTPS POST, or plain HTTP to loopback | `https://api.getskarn.com/v1/license/renew`, or `$SKARN_LICENSE_RENEW_URL` | The installed license token, to receive a re-signed artifact. A licensing credential, never session content or a found secret. |

Everything else is offline: `check` (without `--update-rules`), `assess`, `vet`, `guard` (all events, all hosts), `setup`, `doctor`, `baseline`, `eula`, `taxonomies`, `completion`, `license` (bare, status, and install forms), and every recall command (`search`, `recent`, `stats`, `tools`, `mcps`, `cmds`, `export`), plus `mcp` and every tool it exposes.

## Listener, not caller

`skarn serve` binds a listener on `127.0.0.1` only. It accepts connections; it never initiates one. This is the only place in the binary a socket is opened outside the two commands above.

`skarn mcp` opens no socket at all, in either direction. It reads stdin and writes stdout of the process that spawned it, and its tools read the same local files `assess` and `vet` read.

## Transport properties

Both egress calls execute through a single subprocess transport (`curl`), with the request body delivered on stdin, never on the command line where it could appear in a process list or shell history. Neither call reaches a destination the other would refuse: both `--feed-url`/`$SKARN_FEED_URL` and `$SKARN_LICENSE_RENEW_URL` must name an `https` endpoint, or an `http` one whose authority is a bare loopback host (`127.0.0.1`, `localhost`, or `[::1]`, with an optional numeric port). Under either scheme the authority must carry no userinfo, since curl would send `https://user:pass@host/` as Basic credentials. A refusal names the rule rather than the URL, so a rejected endpoint's credentials are never echoed to the terminal or a CI log; the messages that do name the endpoint are reachable only after it passed this check. Every other scheme is refused, `file:` included, and so is any URL carrying a control byte, which curl's config-file syntax cannot escape. The refusal happens before the request is built, so a poisoned URL never receives the subscriber bearer token or the license token. `skarn license renew` additionally verifies the returned artifact against the trust bundle embedded in the binary before writing a single byte.

The URL policy is the whole policy, so nothing ambient may override it. Both calls pass `-q` as curl's first argument, which stops curl from reading `~/.curlrc` (or `$CURL_HOME/.curlrc`), where a `resolve`, `proxy`, `insecure`, or `output` directive would otherwise redirect the request or write a file. A call whose destination is loopback - the authority is `127.0.0.1`, `localhost`, or `[::1]`, compared case-insensitively, with an optional numeric port and no userinfo - additionally passes `--noproxy localhost,127.0.0.1,::1`, because `$http_proxy` otherwise routes even a loopback request through a proxy and puts the credential on the wire to a third host. That exclusion is added only for a loopback destination: curl's `--noproxy` replaces `$NO_PROXY` rather than adding to it, so applying it to every call would break an enterprise proxy policy that `skarn license renew` is documented to honor.

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

CI runs the full integration suite - every command surface, including the mock-served renew and feed paths on loopback (`tests/fixtures/mock-renew-server.py` and `tests/fixtures/mock-feed-server.py`) - inside a network-denied namespace (`scripts/ci/no-egress-integration.sh`). A change that introduces an outbound connection outside this contract fails the build.
