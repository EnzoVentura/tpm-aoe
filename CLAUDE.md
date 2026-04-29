# CLAUDE.md — fork perso `EnzoVentura/tpm-aoe`

This repository is **a personal fork of `Loulen/tpm-aoe`**, maintained by Enzo
Ventura for personal use. It is **not** a contribution staging area for the
upstream project. Everything you do here lands on `EnzoVentura/tpm-aoe`,
never on `Loulen/tpm-aoe`.

> If you are working in this repo as Claude Code, **read this file first**, then
> defer to [AGENTS.md](./AGENTS.md) for the inherited Rust / build / test
> conventions of the upstream project.

---

## Identity & remote topology

| Remote | URL | Purpose |
|---|---|---|
| `origin` | `git@github.com-perso:EnzoVentura/tpm-aoe.git` | The fork. **All pushes go here.** |
| `upstream` | `https://github.com/Loulen/tpm-aoe.git` | Read-only. **Fetch only**, used to pull improvements from Loulen. |

- Active branch: **`main`** (synced with `upstream/main`, currently at v1.5.0+).
- The legacy `tpm-mode` branch is preserved for historical reference (v1.4.1) but
  is not used for active development.
- Default branch on GitHub fork: `main`.

The binary built from this repo is symlinked at `/opt/homebrew/bin/aoe`, so
any successful `cargo build --release` is immediately the active `aoe`
on this user's machine.

---

## Hard rules for the agent (you)

These rules are **non-negotiable**. Violating them defeats the point of the
fork setup.

1. **NEVER open a pull request to `Loulen/tpm-aoe`.** No `gh pr create --repo
   Loulen/...`, no `--repo upstream`, nothing. This is a private workspace.
2. **NEVER push to `upstream`.** It is configured as fetch-only by convention
   (URL is the public HTTPS endpoint anyway).
3. **All changes go to `origin` (`EnzoVentura/tpm-aoe`)**, in feature branches
   that merge into `main`.
4. **Sync from upstream is allowed and encouraged** to keep up with Loulen's
   improvements:
   ```bash
   git fetch upstream
   git merge upstream/main          # or rebase, user's choice
   git push origin main
   ```
   But never the reverse.
5. **Ignore the `CONTRIBUTING.md`'s upstream-style "fork & PR" instructions** —
   they were inherited from Loulen and have been replaced. The current
   `CONTRIBUTING.md` describes the personal-fork workflow.
6. **Never use `--no-verify`** on commits (husky pre-commit hook is enforced).
7. **Never modify git config** without explicit user approval (per AGENTS.md).
8. The submodule `contrib/tpm-workflow/` points at `Loulen/tpm-workflow.git`.
   Do not change that URL without explicit permission.

---

## What "contributing" means here

Since there is no external collaborator, "contributing" means **making this
fork better for its single user**.

### Standard workflow

```bash
cd ~/Documents/Lab/tpm-aoe

# 1. Start from a fresh main
git checkout main
git pull origin main

# 2. Optional: pull upstream improvements first
git fetch upstream
git merge upstream/main          # if there's anything new

# 3. Branch off
git checkout -b feat/short-name  # or fix/, refactor/, docs/, chore/

# 4. Implement, then quality gates (per AGENTS.md)
cargo fmt
cargo clippy -- -D warnings
cargo test

# 5. Build and test the actual binary locally
~/Documents/Lab/cerveau/aoe-rebuild.sh

# 6. Commit (conventional commit style)
git add <files>
git commit -m "feat: short description"

# 7. Push to origin and (optionally) PR within the fork
git push -u origin feat/short-name
gh pr create --base main --head feat/short-name   # within EnzoVentura/tpm-aoe only

# 8. Merge, delete branch
gh pr merge --squash --delete-branch
git checkout main
git pull origin main
```

### Hotfix workflow (when a tiny change can go straight to main)

Acceptable for trivial doc tweaks, README typos, or urgent local fixes:
```bash
git checkout main
# edit
git commit -am "docs: fix typo"
git push origin main
```
For anything touching code, prefer the branch flow.

---

## Build & run

The user has a helper script that wraps everything:

```bash
~/Documents/Lab/cerveau/aoe-rebuild.sh           # pull + rebuild release with serve
~/Documents/Lab/cerveau/aoe-rebuild.sh --sync    # + merge upstream/main first
~/Documents/Lab/cerveau/aoe-rebuild.sh --dev     # build dev-release (faster, no LTO)
~/Documents/Lab/cerveau/aoe-rebuild.sh --no-serve # skip web dashboard build
```

Manual equivalent:

```bash
export PATH="$HOME/.cargo/bin:$PATH"      # rustup proxies live here
cargo build --release --features serve
```

The web dashboard (`aoe serve`) requires the `serve` feature (default in the
script). Node.js + npm must be installed for the React frontend build.

---

## Conventions inherited from upstream

For everything else — code style, module layout, testing pyramid,
migrations, web dashboard architecture — refer to **[AGENTS.md](./AGENTS.md)**.
The conventions there are good and we do not deviate from them. Specifically:

- Rust: `cargo fmt` + `cargo clippy` decide; fix warnings.
- Naming: `snake_case` modules/functions, `CamelCase` types,
  `SCREAMING_SNAKE_CASE` constants.
- No emdashes or `--` as separators in docs/comments.
- Conventional commit prefixes: `feat:`, `fix:`, `docs:`, `refactor:`,
  `chore:`, `test:`.
- Tests: unit in-module (`#[cfg(test)]`), integration in `tests/*.rs`, e2e in
  `tests/e2e/`. Use `cargo test --test e2e` for e2e.
- Husky pre-commit hook enforces `cargo fmt` and `cargo clippy`. Never bypass.
- OS-specific logic stays in `src/process/{macos,linux}.rs`.
- Settings: every configurable field must be editable in the settings TUI —
  see AGENTS.md `## Settings & Configuration` for the wiring checklist.
- Migrations: breaking storage changes go through `src/migrations/`, not
  inline compat shims. See AGENTS.md `## Data Migrations`.

---

## Repo cartography (quick reference)

```
src/
├── main.rs            binary entrypoint (`aoe`)
├── lib.rs             shared library code
├── cli/               clap command handlers
├── tui/               ratatui UI and input handling
├── session/           session storage, config, groups
├── tmux/              tmux integration
├── process/{macos,linux}.rs   OS-specific process handling
├── docker/            Docker sandboxing
├── git/               worktree operations
├── server/            web dashboard backend (axum + React via rust-embed)
├── update/            version checking against GitHub releases
└── migrations/        versioned data migrations

web/                   React + TS frontend (Vite + Tailwind v4 + xterm.js)
contrib/tpm-workflow/  git submodule → Loulen/tpm-workflow (the TPM plugin)
contribute/            <unused>
docs/                  user-facing docs (canonical source for website)
tests/                 integration + e2e
xtask/                 build automation workspace

.claude/skills/        repo-local skills (docs-review, ship)
target/release/aoe     the symlinked binary
```

---

## Submodule note: `contrib/tpm-workflow/`

This is **not** the same thing as the TPM plugin used by Claude Code.
- The submodule here is used internally by AoE to resolve the orchestrator
  prompt path when running TPM-mode sessions from inside this repo.
- The plugin used by Claude Code lives at
  `~/.claude/plugins/marketplaces/tpm-workflow/` and is managed independently.

If you want this fork's AoE to point at a different plugin source, set
`TPM_WORKFLOW_PATH` in the user's environment.

---

## Local docs (outside the repo)

The user keeps personal documentation about this setup in
`~/Documents/Lab/cerveau/`:

- **`AOE-FORK-SETUP.md`** — full explanation of how this fork is wired into
  the user's machine (symlinks, remotes, build flow, troubleshooting).
- **`TPM-AOE-TIPS.md`** — tips for using TPM workflow + AoE together.
- **`TPM-AOE-CHEATSHEET.html`** — visual one-pager for keybindings & commands.
- **`aoe-rebuild.sh`** — the helper build script referenced above.

If the user asks "where did I document X", check those files first.

---

## When in doubt

- Code question → AGENTS.md.
- Workflow question → this file.
- Build issue → run `~/Documents/Lab/cerveau/aoe-rebuild.sh`, then read
  `AOE-FORK-SETUP.md` if it fails.
- Anything mentioning Loulen, "PR upstream", or "contribute back" → **stop
  and re-read the Hard Rules section above**.
