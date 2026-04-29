# Contributing — personal fork edition

> This is `EnzoVentura/tpm-aoe`, a personal fork of `Loulen/tpm-aoe`. It is
> **not** open to external contributions and does not feed PRs back upstream.
> If you arrived here looking to contribute to the original Agent of Empires
> project, please head to <https://github.com/njbrake/agent-of-empires>
> instead.

The rest of this file describes how the maintainer (Enzo) works on this fork
locally. It is also the operational reference for any AI agent (Claude Code)
opened in this repo — see [`CLAUDE.md`](./CLAUDE.md) for the agent-facing
version of these rules.

---

## Topology

| Remote | URL | Direction |
|---|---|---|
| `origin` | `git@github.com-perso:EnzoVentura/tpm-aoe.git` | push + fetch |
| `upstream` | `https://github.com/Loulen/tpm-aoe.git` | **fetch only** — never push, never PR |

- Default branch: `main` (synced with `upstream/main`).
- `tpm-mode` is preserved as a historical checkpoint (v1.4.1).

---

## Prerequisites

| Tool | Why |
|---|---|
| Rust (via rustup) | Build the binary |
| Node.js + npm | Build the React frontend (`web/`, only needed for `--features serve`) |
| tmux | Runtime requirement of `aoe` |
| Docker (optional) | Sandboxed sessions |
| `cloudflared` (optional) | `aoe serve --remote` (web dashboard via tunnel) |

If `cargo` is missing from PATH despite rustup being installed, the proxies
in `~/.cargo/bin/` may be broken. Repair with:

```bash
ln -sf /opt/homebrew/bin/rustup ~/.cargo/bin/cargo
ln -sf /opt/homebrew/bin/rustup ~/.cargo/bin/rustc
ln -sf /opt/homebrew/bin/rustup ~/.cargo/bin/rustdoc
```

The `aoe-rebuild.sh` helper (in `~/Documents/Lab/cerveau/`) already handles
this PATH issue automatically.

---

## Daily workflow

```bash
cd ~/Documents/Lab/tpm-aoe

# 1. Sync from upstream when there's something new
git fetch upstream
git merge upstream/main          # or rebase, depending on preference
git push origin main

# 2. Branch off
git checkout -b feat/my-change   # or fix/, refactor/, docs/, chore/

# 3. Write code
# ... edits ...

# 4. Quality gates (enforced by husky pre-commit)
cargo fmt
cargo clippy -- -D warnings
cargo test

# 5. Build & run the binary you just modified
~/Documents/Lab/cerveau/aoe-rebuild.sh --dev   # fast iteration
# or
~/Documents/Lab/cerveau/aoe-rebuild.sh         # release build

# 6. Commit (conventional commit prefix)
git add <files>
git commit -m "feat: short description"

# 7. Push to your fork
git push -u origin feat/my-change

# 8. Optional: PR within the fork itself, then squash-merge
gh pr create --base main --head feat/my-change
gh pr merge --squash --delete-branch
```

For trivial doc/typo fixes, committing directly to `main` is acceptable.
For anything touching code, prefer the branch flow so CI (and your future
self) can review.

---

## Code conventions

Inherited from upstream's [AGENTS.md](./AGENTS.md). Highlights:

- `cargo fmt` and `cargo clippy -- -D warnings` are enforced by husky. Never
  pass `--no-verify`.
- Conventional commit prefixes: `feat:`, `fix:`, `docs:`, `refactor:`,
  `chore:`, `test:`.
- No emdashes or `--` as separators in docs/comments.
- Snake_case for functions/modules, CamelCase for types, SCREAMING_SNAKE_CASE
  for constants.
- Keep OS-specific logic in `src/process/{macos,linux}.rs`, not sprinkled
  `#[cfg]` checks across the codebase.
- Settings: every configurable field must be wired into the settings TUI —
  see AGENTS.md `## Settings & Configuration` for the full checklist.
- Tests: unit in-module (`#[cfg(test)]`), integration in `tests/*.rs`, e2e in
  `tests/e2e/`. Use `cargo test --test e2e` for e2e.
- Migrations: breaking storage changes go through `src/migrations/`, not
  inline compat shims.

---

## Build flavors

| Command | Output | Use case |
|---|---|---|
| `cargo build --release --features serve` | `target/release/aoe` (LTO, full features) | The "real" binary, what's symlinked at `/opt/homebrew/bin/aoe` |
| `cargo build --profile dev-release --features serve` | `target/dev-release/aoe` | Faster compile, near-release perf, for iteration |
| `cargo build` | `target/debug/aoe` | Dev-only, slow runtime |
| `cargo build --release --no-default-features` | smaller binary | TUI only, no web dashboard |

The `aoe-rebuild.sh` helper covers the common cases.

---

## Publishing changes

Since this is a personal fork, "publishing" means `git push origin <branch>`.
There is no release pipeline, no crates.io publish, no Homebrew formula
update. The user's machine pulls and rebuilds locally via the helper script.

If you ever want to share a change with upstream, that is a deliberate
exception — open the PR manually against `Loulen/tpm-aoe` from a separate
checkout, not from this workspace.

---

## Pulling upstream improvements

Loulen ships frequently. To stay current:

```bash
git fetch upstream
git log HEAD..upstream/main --oneline    # see what's new
git merge upstream/main                  # bring it in
git push origin main
```

If a merge conflicts, resolve normally. If the conflict is in a file you
modified locally on your fork (e.g. `CLAUDE.md`, `CONTRIBUTING.md`), prefer
your version (`git checkout --ours <file>`).

---

## Don'ts

- Do NOT `gh pr create --repo Loulen/tpm-aoe ...` (no PRs upstream).
- Do NOT `git push upstream ...` (read-only).
- Do NOT `git commit --no-verify` (skip the hook = ship broken code).
- Do NOT modify git config without explicit user approval.
- Do NOT touch the submodule URL without explicit permission.

If you find yourself doing any of the above, stop.
