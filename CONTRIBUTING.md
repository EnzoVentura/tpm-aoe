# Contribuer — édition fork personnel

> Ce dépôt est `EnzoVentura/tpm-aoe`, un fork personnel de `Loulen/tpm-aoe`.
> Il n'est **pas** ouvert aux contributions externes et n'envoie pas de PR
> en retour vers le projet upstream. Si tu cherchais à contribuer au projet
> Agent of Empires original, va plutôt sur
> <https://github.com/njbrake/agent-of-empires>.

Le reste de ce fichier décrit comment le mainteneur (Enzo) travaille sur ce
fork en local. Il sert également de référence opérationnelle pour tout agent
IA (Claude Code) ouvert dans ce dépôt — voir [`CLAUDE.md`](./CLAUDE.md) pour
la version centrée agent de ces règles.

---

## Langue du projet

Tout ce qui est écrit dans ce dépôt par le mainteneur ou par un agent IA est
**en français**. Cela inclut la documentation, les messages de commit, et
les nouveaux commentaires de code que l'agent ajoute.

Restent en anglais : le code Rust (identifiants, fonctions, types), les
docs strings techniques, le fichier `AGENTS.md` (hérité d'upstream), et les
préfixes conventional commit (`feat:`, `fix:`, etc.).

---

## Topologie

| Remote | URL | Direction |
|---|---|---|
| `origin` | `git@github.com-perso:EnzoVentura/tpm-aoe.git` | push + fetch |
| `upstream` | `https://github.com/Loulen/tpm-aoe.git` | **fetch uniquement** — pas de push, pas de PR |

- Branche par défaut : `main` (synced avec `upstream/main`).
- `tpm-mode` est conservée comme checkpoint historique (v1.4.1).

---

## Prérequis

| Outil | Pourquoi |
|---|---|
| Rust (via rustup) | Build du binaire |
| Node.js + npm | Build du frontend React (`web/`, nécessaire seulement pour `--features serve`) |
| tmux | Dépendance runtime de `aoe` |
| Docker (optionnel) | Sessions sandboxées |
| `cloudflared` (optionnel) | `aoe serve --remote` (web dashboard via tunnel) |

Si `cargo` est introuvable dans le PATH alors que rustup est installé, les
proxies dans `~/.cargo/bin/` peuvent être cassés. Réparation :

```bash
ln -sf /opt/homebrew/bin/rustup ~/.cargo/bin/cargo
ln -sf /opt/homebrew/bin/rustup ~/.cargo/bin/rustc
ln -sf /opt/homebrew/bin/rustup ~/.cargo/bin/rustdoc
```

Le helper `aoe-rebuild.sh` (dans `~/Documents/Lab/cerveau/`) gère déjà cette
question de PATH automatiquement.

---

## Workflow quotidien

```bash
cd ~/Documents/Lab/tpm-aoe

# 1. Sync depuis upstream quand il y a du nouveau
git fetch upstream
git merge upstream/main          # ou rebase, selon préférence
git push origin main

# 2. Créer une branche
git checkout -b feat/mon-changement   # ou fix/, refactor/, docs/, chore/

# 3. Écrire le code
# ... édits ...

# 4. Quality gates (forcés par le hook husky pre-commit)
cargo fmt
cargo clippy -- -D warnings
cargo test

# 5. Build et test du binaire qu'on vient de modifier
~/Documents/Lab/cerveau/aoe-rebuild.sh --dev   # itération rapide
# ou
~/Documents/Lab/cerveau/aoe-rebuild.sh         # build release

# 6. Commit (préfixe conventional commit, message en français)
git add <fichiers>
git commit -m "feat: description courte du changement"

# 7. Push sur le fork
git push -u origin feat/mon-changement

# 8. Optionnel : PR à l'intérieur du fork, puis squash-merge
gh pr create --base main --head feat/mon-changement
gh pr merge --squash --delete-branch
```

Pour les corrections triviales (typos doc), le commit direct sur `main` est
acceptable. Pour tout ce qui touche le code, préférer le flow par branche
pour que la CI (et toi-même plus tard) puissiez review.

---

## Conventions de code

Héritées de l'[AGENTS.md](./AGENTS.md) d'upstream. Highlights :

- `cargo fmt` et `cargo clippy -- -D warnings` sont forcés par husky. Ne
  jamais passer `--no-verify`.
- Préfixes conventional commit : `feat:`, `fix:`, `docs:`, `refactor:`,
  `chore:`, `test:`.
- Pas d'em-dashes ou `--` comme séparateurs dans la doc/les commentaires.
- Snake_case pour fonctions/modules, CamelCase pour types,
  SCREAMING_SNAKE_CASE pour les constantes.
- La logique OS-specific reste dans `src/process/{macos,linux}.rs`, pas
  dispersée en `#[cfg]` partout dans le codebase.
- Settings : tout champ configurable doit être câblé dans la TUI settings —
  voir AGENTS.md `## Settings & Configuration` pour la checklist complète.
- Tests : unitaires in-module (`#[cfg(test)]`), intégration dans
  `tests/*.rs`, e2e dans `tests/e2e/`. `cargo test --test e2e` pour les e2e.
- Migrations : les changements de stockage breaking passent par
  `src/migrations/`, pas par des shims inline.

---

## Variantes de build

| Commande | Sortie | Cas d'usage |
|---|---|---|
| `cargo build --release --features serve` | `target/release/aoe` (LTO, full features) | Le « vrai » binaire, celui qui est symlinké à `/opt/homebrew/bin/aoe` |
| `cargo build --profile dev-release --features serve` | `target/dev-release/aoe` | Build plus rapide, perf proche du release, pour itérer |
| `cargo build` | `target/debug/aoe` | Dev uniquement, runtime lent |
| `cargo build --release --no-default-features` | binaire plus petit | TUI seulement, pas de web dashboard |

Le helper `aoe-rebuild.sh` couvre les cas les plus fréquents.

---

## Publier des changements

Comme c'est un fork personnel, « publier » signifie `git push origin <branche>`.
Pas de pipeline de release, pas de publish crates.io, pas de mise à jour de
formule Homebrew. La machine de l'utilisateur fait pull et rebuild en local
via le script helper.

Si tu veux un jour partager un changement avec upstream, c'est une
exception délibérée : ouvrir la PR manuellement contre `Loulen/tpm-aoe`
depuis un autre checkout, pas depuis cet espace de travail.

---

## Récupérer les améliorations upstream

Loulen ship fréquemment. Pour rester à jour :

```bash
git fetch upstream
git log HEAD..upstream/main --oneline    # voir le nouveau
git merge upstream/main                  # ramener
git push origin main
```

Si un merge a des conflits, résoudre normalement. Si le conflit concerne un
fichier modifié localement sur le fork (ex. `CLAUDE.md`, `CONTRIBUTING.md`),
préférer ta version :

```bash
git checkout --ours CLAUDE.md CONTRIBUTING.md
git add CLAUDE.md CONTRIBUTING.md
```

---

## À ne jamais faire

- NE PAS `gh pr create --repo Loulen/tpm-aoe ...` (pas de PR upstream).
- NE PAS `git push upstream ...` (lecture seule).
- NE PAS `git commit --no-verify` (skip du hook = ship du code cassé).
- NE PAS modifier la config git sans approbation explicite.
- NE PAS toucher l'URL du submodule sans permission explicite.

Si tu te surprends en train de faire un de ces trucs, stop.
