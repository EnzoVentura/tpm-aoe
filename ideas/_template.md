---
id: NNNN
title: Titre court de l'idée (6 à 10 mots)
status: idée            # idée | accepté | en-cours | terminé | abandonné
priority: medium        # low | medium | high
created: YYYY-MM-DD
tags: []                # ex. [tui, performance, dx]
# branch:               # à remplir quand status: en-cours
# closed:               # date de clôture (terminé / abandonné)
---

# NNNN — Titre court de l'idée

## Idée

*1 à 2 phrases.* Décris ce que l'idée propose, sans rentrer dans le
comment. Quelqu'un qui lit cette section doit comprendre **quoi** en
30 secondes.

## But

*1 paragraphe.* Pourquoi on le fait. Quel problème ça résout, quelle
valeur ça apporte, ou quel inconfort ça fait disparaître. Si tu ne
trouves pas de but clair, ce n'est probablement pas une idée à garder.

## Fonctionnement technique

*1 à 3 paragraphes ou une liste.* À haut niveau : les modules touchés,
l'approche envisagée, les patterns à utiliser. Pas de pseudo-code détaillé,
pas de signatures de fonctions. Quelqu'un qui code doit voir où aller
et quoi modifier sans se perdre dans les détails.

Exemple de découpage :
- Module / fichier principal modifié : `src/...`
- Mécanique : *décris le flow*.
- Points de friction prévisibles : *liste*.

## Besoin

*Liste à puces.* Ce qu'il faut pour réaliser l'idée :
- Prérequis techniques (ex. dépendance crate, refacto préalable)
- Dépendances sur d'autres idées (ex. `0003` doit être terminée avant)
- Décisions à trancher avant d'implémenter
- Estimation de complexité (S / M / L) — optionnelle

---

<!--
Sections optionnelles à ajouter selon le besoin :

## Alternatives considérées
Pour les idées qui ont plusieurs implémentations possibles. Liste-les
brièvement, dis pourquoi tu as choisi celle de la section "Fonctionnement
technique".

## Notes
Pour les liens, screenshots, références à des issues upstream, ou tout
contexte additionnel.

## Pourquoi abandonné
À remplir si status: abandonné. Une raison claire, pour ne pas y revenir
inutilement plus tard.
-->
