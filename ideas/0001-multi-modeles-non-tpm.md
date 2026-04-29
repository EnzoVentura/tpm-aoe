---
id: 0001
title: Sessions multi-modèles avec contexte projet, sans TPM
status: implémenté
priority: medium
created: 2026-04-29
tags: [agents, cli, tui, dx, multi-model]
---

# 0001 — Sessions multi-modèles avec contexte projet, sans TPM

## Idée

Permettre de lancer des sessions AoE avec d'autres modèles que Claude
(Codex, Ollama, Gemini, etc.) **sans le toggle TPM**, tout en garantissant
que ces sessions héritent du contexte du projet (CLAUDE.md, AGENTS.md,
conventions, structure).

## But

Le toggle TPM ajouté par le fork est claude-only par construction
(orchestrator + sub-agents reposent sur les Claude Code skills). Conséquence
actuelle : on ne peut pas exploiter facilement un autre modèle pour les
tâches où il serait pertinent — un Ollama local pour brainstormer hors
budget API, Codex pour des refactos lourds, Gemini pour des tâches longues
au coût lissé. Pouvoir choisir le modèle par tâche, sans perdre le bénéfice
du setup AoE (worktrees, sandbox, sessions persistantes), élargit
significativement l'usage du fork pour un coût d'implémentation modeste.

## Fonctionnement technique

L'idée se découpe en deux briques relativement indépendantes :

**1. Couverture multi-agents.** AoE supporte déjà nativement Claude Code,
OpenCode, Mistral Vibe, Codex CLI, Gemini CLI, Cursor CLI, Copilot CLI,
Pi.dev et Factory Droid (auto-détection dans `src/agents/`). À vérifier
sur la version actuelle de notre fork (v1.5.0) et ajouter ce qui manque,
notamment **Ollama** qui n'est probablement pas dans la liste — soit comme
agent natif (wrapper autour de `ollama run <model>`), soit via une
intégration générique « commande arbitraire ». Le bon endroit :
`src/agents/`, suivre le pattern d'un agent existant comme Codex ou
OpenCode.

**2. Contexte projet partagé entre agents.** Chaque agent a sa propre
convention de fichier d'instructions auto-chargé : `CLAUDE.md` pour Claude,
`AGENTS.md` pour Codex/OpenCode (convention agent-md), pas de standard pour
Ollama. Trois pistes pour propager le contexte :

- **Convergence vers `AGENTS.md`** : conserver `AGENTS.md` (déjà en place)
  comme source de vérité multi-agents et faire en sorte que `CLAUDE.md`
  l'inclue explicitement (déjà partiellement le cas) → bénéfice immédiat
  pour Codex/OpenCode sans rien coder.
- **Hooks `on_create`** dans `.agent-of-empires/config.toml` qui copient
  ou symlinkent les fichiers de contexte vers le format attendu par
  l'agent (ex. `cp CLAUDE.md .gemini/instructions.md` au démarrage d'une
  session Gemini).
- **Injection via `--system-prompt`** au moment du `aoe add`, similaire à
  ce que fait le toggle TPM mais avec le contenu de `CLAUDE.md` plutôt
  que celui de l'orchestrator. À gater par un nouveau toggle/flag :
  `--inject-context` ou `☐ Project context` dans la dialog new-session.

L'option **(c)** est la plus ambitieuse mais aussi la plus uniforme : peu
importe l'agent choisi, on lui colle systématiquement le contexte projet
en system-prompt. Les options **(a)** et **(b)** sont des alternatives
plus légères, à privilégier si on veut un effet rapide.

## Besoin

- **Audit préalable** :
  - Vérifier la liste exacte des agents supportés dans la branche `main`
    actuelle (lire `src/agents/`).
  - Vérifier si Ollama y est. Si non, c'est un point d'entrée pour
    l'intégration.
  - Vérifier le comportement actuel du toggle TPM quand l'agent
    sélectionné n'est pas Claude (devrait être désactivé / griser, mais à
    confirmer).
- **Décisions à trancher** :
  - Quelle(s) approche(s) pour le contexte projet ? Option (a), (b), (c)
    ou un mix ? Mon préfèré pragmatique : (a) en premier (zéro code, on
    peaufine `AGENTS.md`), (c) si on veut un toggle dédié dans la dialog.
  - Faut-il une intégration Ollama « première classe » (entrée dans
    `src/agents/`, auto-détection) ou suffit-il d'utiliser le mécanisme
    de commande arbitraire (`aoe add --cmd "ollama run llama3"`) ?
- **Dépendances** : aucune. Cette idée est indépendante des autres.
- **Complexité estimée** :
  - Approche (a) seule : **S** — quelques tweaks dans `AGENTS.md`.
  - Ajout intégration Ollama : **M** — copier le pattern d'un agent
    existant, +1 entrée dans la liste détectée, tests e2e.
  - Approche (c) avec toggle dédié : **L** — touche `src/cli/add.rs`,
    `src/tui/dialogs/new_session/`, et probablement
    `src/agents/system_prompt.rs` (ou équivalent).

## Alternatives considérées

- **Ne rien faire et rester claude-only sur le fork** : bonne option si on
  réalise que l'ajout d'autres modèles dilue l'expérience TPM. À garder en
  tête si le coût d'implémentation s'envole.
- **Forker AoE encore plus, en virant le toggle TPM** : trop radical,
  perd l'intérêt du fork.
- **Utiliser un wrapper externe** (ex. un script qui lance `aoe add` puis
  injecte le contexte via `aoe send`) : marche aujourd'hui, mais pas
  intégré dans la TUI, donc friction.
