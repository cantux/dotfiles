# Component map

Root: `/home/ctuk/Projects/dotfiles/dns`.

| Component | Role |
| --- | --- |
| [README.md](README.md) | Application command, Brave settings, and activation status. |
| [PLAN.md](PLAN.md) | Work units, completion checks, and remaining host work. |
| [ARCH.md](ARCH.md) | DNS paths, TLS enforcement, persistence, and restoration. |
| [INSTR.md](INSTR.md) | Application, verification, debugging, and restoration. |
| [WORKLOG.md](WORKLOG.md) | Chronological work and validation record. |
| [EVIDENCE_INSPIRATION_REFERENCE.md](EVIDENCE_INSPIRATION_REFERENCE.md) | Local evidence and primary references. |
| [networkmanager.conf](networkmanager.conf) | Prevents NetworkManager from replacing DNS or supplying per-interface servers. |
| [resolved.conf](resolved.conf) | Requires authenticated TLS to Cloudflare and selects the local stub. |
| [brave-policy.json](brave-policy.json) | Selects the operating system DNS client for Brave. |
| [configure.py](configure.py) | Installs, verifies, and restores configuration. |
| [test_configure.py](test_configure.py) | Exercises installation, restoration, repeat execution, and runtime verification in isolation. |
| [../sync.sh](../sync.sh) | Dispatches `--dns` to the configuration helper. |

The helper stores original files and resolver service state under
`/var/lib/dotfiles-dns/baseline`. Each application attempt creates a separate
transaction snapshot of the current state.
