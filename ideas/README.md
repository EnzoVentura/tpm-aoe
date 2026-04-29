# Ideas — espace d'idées de fonctionnalités

Ce dossier liste les idées d'évolution du fork. Chaque idée vit dans un
fichier `.md` numéroté, avec un format unique imposé par le template.
Le but : pouvoir parcourir les idées en un coup d'œil, en piocher une
quand on veut bosser dessus, et garder une trace de ce qui est fait.

---

## Comment ajouter une idée

1. **Copier le template** :
   ```bash
   cd ~/Documents/Lab/tpm-aoe/ideas
   cp _template.md NNNN-slug-court.md
   ```
   Où `NNNN` est le prochain numéro libre (4 chiffres, padding par zéros)
   et `slug-court` est un identifiant en kebab-case de 2-4 mots.

2. **Trouver le prochain numéro** :
   ```bash
   ls ideas/[0-9]*.md 2>/dev/null | sort | tail -1
   ```

3. **Remplir les 4 sections** du fichier (Idée / But / Fonctionnement
   technique / Besoin) en respectant les limites suggérées dans le
   template — l'objectif est qu'une idée tienne sur **un écran**.

4. **Mettre à jour le frontmatter** : `status: idée`, `priority`, `tags`.

5. **Commit** :
   ```bash
   git add ideas/NNNN-slug-court.md
   git commit -m "docs(ideas): NNNN — titre court"
   git push origin main
   ```

---

## Cycle de vie d'une idée

Le statut vit dans le frontmatter du fichier (champ `status`). Pas besoin
de renommer le fichier quand le statut change.

```
idée  →  accepté  →  en-cours  →  terminé
   ╲          │
    ╲         ▼
     →   abandonné
```

| Statut | Sens |
|---|---|
| `idée` | Brouillon, pas encore tranché. La majorité des fichiers vivent ici. |
| `accepté` | On a décidé de le faire, mais pas encore commencé. |
| `en-cours` | Implémentation en cours (référencer la branche dans le frontmatter). |
| `terminé` | Mergé sur `main`. Garde le fichier comme archive (pratique pour `grep`). |
| `abandonné` | On ne le fait pas. Note la raison dans une section `## Pourquoi abandonné`. |

---

## Trouver des idées par critère

```bash
# Toutes les idées au statut "idée"
grep -l "^status: idée" ideas/*.md

# Toutes les idées prioritaires
grep -l "^priority: high" ideas/*.md

# Idées avec un tag particulier
grep -l "tui" ideas/*.md | xargs grep -l "^tags:.*tui"

# Liste rapide titre + statut
for f in ideas/[0-9]*.md; do
  printf "%s  [%s]  %s\n" \
    "$(basename "$f" .md)" \
    "$(awk -F: '/^status:/{print $2}' "$f" | xargs)" \
    "$(awk -F: '/^title:/{print $2}' "$f" | xargs)"
done
```

---

## Champs du frontmatter

| Champ | Valeurs | Obligatoire |
|---|---|---|
| `id` | numéro à 4 chiffres, identique au préfixe du nom de fichier | oui |
| `title` | titre court (~6-10 mots) | oui |
| `status` | `idée` / `accepté` / `en-cours` / `terminé` / `abandonné` | oui |
| `priority` | `low` / `medium` / `high` | oui |
| `created` | date de création `YYYY-MM-DD` | oui |
| `tags` | liste YAML (ex. `[tui, performance]`) | optionnel |
| `branch` | nom de la branche git en cours, si `status: en-cours` | optionnel |
| `closed` | date de clôture `YYYY-MM-DD`, si `terminé` ou `abandonné` | optionnel |

---

## Bonnes pratiques

- **Une idée = un fichier.** Pas de regroupement.
- **Reste court.** Si une section dépasse un paragraphe dense, c'est qu'elle
  contient déjà l'amorce d'une autre idée — sépare.
- **Réécris au fil du temps.** Quand tu mûris une idée, modifie-la. Le but
  n'est pas l'historique du fichier (git le fait), c'est qu'à un moment
  donné, l'idée soit lisible en 30 secondes.
- **Commit chaque idée séparément.** Plus simple à reviewer dans le futur.
- **Le numéro est immuable** une fois assigné, même si l'idée est abandonnée.
  Ne pas réutiliser un numéro libéré.
- **Tags suggérés** : `tui`, `cli`, `web`, `tpm`, `serve`, `sandbox`,
  `worktree`, `tmux`, `events`, `performance`, `refactor`, `dx`, `ux`,
  `serveur`, `mobile`. Liste libre, pas exhaustive.

---

## Quand ne pas créer une idée

- **Bug fix simple** → branche `fix/...` direct, pas la peine de passer par ici.
- **Refactor cosmétique** → idem.
- **Question / interrogation** → discute-la avec l'agent en session, ne
  l'enferme pas dans un fichier tant qu'elle n'a pas la forme d'une idée
  actionnable.

Les idées d'ici sont des **propositions concrètes**, pas un journal de
réflexion. Pour ce dernier, garde un fichier ailleurs (ex. dans
`~/Documents/Lab/cerveau/`).

---

## Index (manuel)

Met à jour cette liste quand tu ajoutes/clôtures une idée. Garde-la triée
par numéro.

| ID | Titre | Statut | Priorité |
|---|---|---|---|
| [0001](./0001-multi-modeles-non-tpm.md) | Sessions multi-modèles avec contexte projet, sans TPM | idée | medium |

---

## Voir aussi

- `_template.md` dans ce dossier — le squelette à copier pour chaque nouvelle idée.
- `../CLAUDE.md` — règles globales du fork.
- `../CONTRIBUTING.md` — workflow git détaillé.
