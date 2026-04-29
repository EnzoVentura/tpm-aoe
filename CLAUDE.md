# CLAUDE.md — fork perso `EnzoVentura/tpm-aoe`

Ce dépôt est **un fork personnel de `Loulen/tpm-aoe`**, maintenu par Enzo
Ventura pour son usage personnel. Ce n'est **pas** une zone de pré-contribution
vers le projet upstream. Tout ce que tu fais ici est destiné à
`EnzoVentura/tpm-aoe`, jamais à `Loulen/tpm-aoe`.

> Si tu travailles dans ce dépôt en tant que Claude Code, **lis ce fichier en
> premier**, puis réfère-toi à [AGENTS.md](./AGENTS.md) pour les conventions
> Rust / build / test héritées du projet upstream (volontairement laissé en
> anglais pour limiter les conflits de merge avec upstream).

---

## Langue du projet

**Tout ce que tu écris dans ce dépôt et toute communication avec
l'utilisateur doivent être en français.** Cela inclut :

- Les messages adressés à l'utilisateur dans la session.
- Les fichiers de documentation que tu créés ou modifies (`CLAUDE.md`,
  `CONTRIBUTING.md`, tout nouveau fichier `.md` que tu crées).
- Les messages de commit (le préfixe conventionnel reste en anglais :
  `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `test:` — mais la suite
  du message est en français).
- Les commentaires que tu ajoutes dans du code que tu modifies *si tu en
  ajoutes*. Ne traduis pas en masse les commentaires existants ; ne touche
  qu'à ceux que tu ajoutes ou réécris.
- Les nouveaux noms de branches `git` peuvent rester en anglais minimaliste
  (`feat/short-name`) parce qu'ils sont conventionnels.

**Ce qui reste en anglais :**

- Le code Rust : identifiants, fonctions, types, doc strings techniques.
- `AGENTS.md` (vient d'upstream, on n'y touche pas).
- Les noms de fichiers, de modules, de tests.
- Les conventional commit prefixes (`feat:`, `fix:`, etc.).

L'utilisateur a explicitement demandé le français pour ce projet. Si jamais
tu lis cette instruction et qu'elle te semble en conflit avec un réflexe
d'écrire en anglais, suis cette instruction.

---

## Identité et topologie des remotes

| Remote | URL | Usage |
|---|---|---|
| `origin` | `git@github.com-perso:EnzoVentura/tpm-aoe.git` | Le fork. **Tous les push vont ici.** |
| `upstream` | `https://github.com/Loulen/tpm-aoe.git` | Lecture seule. **Fetch uniquement**, pour récupérer les améliorations de Loulen. |

- Branche active : **`main`** (synced avec `upstream/main`, actuellement à v1.5.0+).
- La branche legacy `tpm-mode` est conservée pour référence historique
  (v1.4.1) mais n'est plus utilisée pour le développement.
- Branche par défaut sur le fork GitHub : `main`.

Le binaire compilé depuis ce dépôt est symlinké à `/opt/homebrew/bin/aoe`,
donc tout `cargo build --release` réussi devient immédiatement le `aoe`
actif sur la machine de l'utilisateur.

---

## Règles strictes pour l'agent (toi)

Ces règles sont **non-négociables**. Les violer revient à invalider tout
l'intérêt du fork.

1. **Ne JAMAIS ouvrir une pull request vers `Loulen/tpm-aoe`.** Pas de
   `gh pr create --repo Loulen/...`, pas de `--repo upstream`, rien. C'est
   un espace de travail privé.
2. **Ne JAMAIS push vers `upstream`.** Configuré comme fetch-only par
   convention (l'URL est en HTTPS public de toute façon).
3. **Tous les changements vont sur `origin` (`EnzoVentura/tpm-aoe`)**, dans
   des branches de feature qui mergent vers `main`.
4. **Le sync depuis upstream est autorisé et encouragé** pour suivre les
   améliorations de Loulen :
   ```bash
   git fetch upstream
   git merge upstream/main          # ou rebase, au choix
   git push origin main
   ```
   Mais jamais l'inverse.
5. **Ignorer les instructions « fork & PR upstream » de l'ancien
   `CONTRIBUTING.md`** — elles venaient de Loulen et ont été remplacées.
   Le `CONTRIBUTING.md` actuel décrit le workflow personal-fork.
6. **Ne jamais utiliser `--no-verify`** sur les commits (le hook husky
   pre-commit est obligatoire).
7. **Ne jamais modifier la config git** sans approbation explicite de
   l'utilisateur (cf. AGENTS.md).
8. Le submodule `contrib/tpm-workflow/` pointe sur `Loulen/tpm-workflow.git`.
   Ne pas changer cette URL sans permission explicite.

---

## Ce que « contribuer » signifie ici

Comme il n'y a pas de collaborateur externe, « contribuer » signifie
**améliorer ce fork pour son unique utilisateur**.

### Workflow standard

```bash
cd ~/Documents/Lab/tpm-aoe

# 1. Repartir d'une main fraîche
git checkout main
git pull origin main

# 2. Optionnel : récupérer les améliorations upstream avant
git fetch upstream
git merge upstream/main          # s'il y a du nouveau

# 3. Créer une branche
git checkout -b feat/nom-court   # ou fix/, refactor/, docs/, chore/

# 4. Implémenter, puis quality gates (cf. AGENTS.md)
cargo fmt
cargo clippy -- -D warnings
cargo test

# 5. Build et test du binaire en local
~/Documents/Lab/cerveau/aoe-rebuild.sh

# 6. Commit (style conventional commit, message en français)
git add <fichiers>
git commit -m "feat: description courte du changement"

# 7. Push sur origin et (optionnel) PR à l'intérieur du fork
git push -u origin feat/nom-court
gh pr create --base main --head feat/nom-court   # uniquement dans EnzoVentura/tpm-aoe

# 8. Merge, suppression de la branche
gh pr merge --squash --delete-branch
git checkout main
git pull origin main
```

### Workflow hotfix (changement minime direct sur main)

Acceptable pour des corrections triviales de doc, typos README, ou fixes
locaux urgents :

```bash
git checkout main
# édite
git commit -am "docs: corrige une typo"
git push origin main
```

Pour tout ce qui touche du code, préfère le flow par branche.

---

## Build et utilisation

L'utilisateur a un script helper qui enveloppe tout :

```bash
~/Documents/Lab/cerveau/aoe-rebuild.sh           # pull + rebuild release avec serve
~/Documents/Lab/cerveau/aoe-rebuild.sh --sync    # + merge upstream/main avant
~/Documents/Lab/cerveau/aoe-rebuild.sh --dev     # build dev-release (rapide, sans LTO)
~/Documents/Lab/cerveau/aoe-rebuild.sh --no-serve # sans web dashboard
```

Équivalent manuel :

```bash
export PATH="$HOME/.cargo/bin:$PATH"      # les proxies rustup vivent ici
cargo build --release --features serve
```

La web dashboard (`aoe serve`) requiert la feature `serve` (par défaut dans
le script). Node.js + npm doivent être installés pour le build du frontend
React.

---

## Conventions héritées d'upstream

Pour tout le reste — style de code, organisation des modules, pyramide de
tests, migrations, architecture de la web dashboard — réfère-toi à
**[AGENTS.md](./AGENTS.md)** (en anglais, ne pas traduire). Les conventions
qui y sont définies sont valides et nous ne les contournons pas.
Spécifiquement :

- Rust : `cargo fmt` + `cargo clippy` font foi ; corriger les warnings.
- Nommage : `snake_case` pour modules/fonctions, `CamelCase` pour types,
  `SCREAMING_SNAKE_CASE` pour les constantes.
- Pas d'em-dashes ou `--` comme séparateurs dans la doc/les commentaires.
- Préfixes conventional commit : `feat:`, `fix:`, `docs:`, `refactor:`,
  `chore:`, `test:`.
- Tests : unitaires in-module (`#[cfg(test)]`), intégration dans
  `tests/*.rs`, e2e dans `tests/e2e/`. `cargo test --test e2e` pour les e2e.
- Le hook husky pre-commit force `cargo fmt` et `cargo clippy`. Ne jamais
  bypass.
- La logique OS-specific reste dans `src/process/{macos,linux}.rs`.
- Settings : tout champ configurable doit être éditable dans la TUI settings —
  voir AGENTS.md `## Settings & Configuration` pour la checklist de wiring.
- Migrations : les changements de stockage breaking passent par
  `src/migrations/`, pas par des shims inline. Voir AGENTS.md
  `## Data Migrations`.

---

## Espace d'idées (`ideas/`)

Le dossier **`ideas/`** à la racine du repo héberge les idées d'évolution
du fork. Chaque idée vit dans un fichier `.md` numéroté, suivant un format
imposé par `ideas/_template.md`.

**Quand l'utilisateur évoque une idée nouvelle** :

1. Vérifier si elle existe déjà avec un quick `grep -l <mot-clé> ideas/`.
2. Si elle est nouvelle :
   - Trouver le prochain numéro libre :
     `ls ideas/[0-9]*.md 2>/dev/null | sort | tail -1`
   - Copier le template : `cp ideas/_template.md ideas/NNNN-slug.md`
   - Remplir les 4 sections : **Idée**, **But**, **Fonctionnement
     technique**, **Besoin** (en respectant les longueurs suggérées dans
     le template — l'idée doit tenir sur un écran).
   - Compléter le frontmatter (`id`, `title`, `status: idée`,
     `priority`, `created`, `tags`).
   - Mettre à jour le tableau "Index" dans `ideas/README.md`.
   - Commit : `docs(ideas): NNNN — titre court`.

3. Si elle existe déjà : ouvrir le fichier existant et l'enrichir, plutôt
   que d'en créer un nouveau.

**Quand l'utilisateur veut "piocher" dans la liste pour bosser sur une
idée** :

1. Lire le fichier de l'idée concernée.
2. Modifier son frontmatter : `status: en-cours`, ajouter `branch: ...`.
3. Créer la branche correspondante et implémenter.
4. À la fin, passer le statut à `terminé` (avec `closed: YYYY-MM-DD`).

**Règles spécifiques à `ideas/`** :

- Le numéro `NNNN` est **immuable** une fois assigné. On ne le réutilise
  jamais, même pour une idée abandonnée.
- Les fichiers d'idées **terminées ou abandonnées restent en place** — ce
  sont des archives, utiles pour grep et pour comprendre les décisions
  passées.
- Tags suggérés (liste libre) : `tui`, `cli`, `web`, `tpm`, `serve`,
  `sandbox`, `worktree`, `tmux`, `events`, `performance`, `refactor`,
  `dx`, `ux`, `serveur`, `mobile`.
- Voir `ideas/README.md` pour la doc complète du système.

---

## Cartographie rapide du repo

```
src/
├── main.rs            point d'entrée du binaire (`aoe`)
├── lib.rs             code de bibliothèque partagé
├── cli/               handlers de commandes clap
├── tui/               UI ratatui et gestion des inputs
├── session/           stockage des sessions, config, groupes
├── tmux/              intégration tmux
├── process/{macos,linux}.rs   gestion process OS-specific
├── docker/            sandboxing Docker
├── git/               opérations sur les worktrees
├── server/            backend web dashboard (axum + React via rust-embed)
├── update/            vérification de version contre les releases GitHub
└── migrations/        migrations de données versionnées

web/                   frontend React + TS (Vite + Tailwind v4 + xterm.js)
contrib/tpm-workflow/  submodule git → Loulen/tpm-workflow (le plugin TPM)
docs/                  doc utilisateur (source canonique pour le site web)
tests/                 tests d'intégration + e2e
xtask/                 workspace d'automatisation de build

ideas/                 espace d'idées de fonctionnalités (fork-only)
.claude/skills/        skills locaux au repo (docs-review, ship)
target/release/aoe     le binaire symlinké
```

---

## Note sur le submodule `contrib/tpm-workflow/`

Ce **n'est pas** la même chose que le plugin TPM utilisé par Claude Code.

- Le submodule ici est utilisé en interne par AoE pour résoudre le path du
  prompt orchestrator quand on lance des sessions TPM-mode depuis ce dépôt.
- Le plugin utilisé par Claude Code vit dans
  `~/.claude/plugins/marketplaces/tpm-workflow/` et est géré indépendamment.

Si tu veux que ce fork pointe sur une autre source de plugin, définis
`TPM_WORKFLOW_PATH` dans l'environnement de l'utilisateur.

---

## Doc locale (hors du repo)

L'utilisateur garde sa doc personnelle sur ce setup dans
`~/Documents/Lab/cerveau/` :

- **`AOE-FORK-SETUP.md`** — explication complète du wiring du fork sur la
  machine de l'utilisateur (symlinks, remotes, build flow, troubleshooting).
- **`TPM-AOE-TIPS.md`** — tips pour utiliser le workflow TPM + AoE.
- **`TPM-AOE-CHEATSHEET.html`** — pense-bête visuel une-page (keybindings &
  commandes).
- **`aoe-rebuild.sh`** — le script helper de build mentionné plus haut.

Si l'utilisateur demande « où est-ce que j'ai documenté X », vérifie ces
fichiers en premier.

---

## En cas de doute

- Question sur le code → AGENTS.md.
- Question sur le workflow → ce fichier.
- Problème de build → `~/Documents/Lab/cerveau/aoe-rebuild.sh`, puis lire
  `AOE-FORK-SETUP.md` si ça échoue.
- Toute mention de Loulen, « PR upstream », « contribuer en retour » →
  **stop et relire la section "Règles strictes pour l'agent" plus haut**.
