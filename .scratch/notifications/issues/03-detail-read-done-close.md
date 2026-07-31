# Slice 3 — Détail + Read / Done / Close

Status: done

## Parent

`.scratch/notifications/PRD.md` — Live Activity « Notifications ».
Signatures vérifiées : `docs/notifications-feature-spec.md` (§4, §9).

## What to build

Le second niveau de l'UX : un tap sur une ligne de la liste ouvre une **vue détail** (summary complet
multi-ligne, `title`, `source`, heure, icône) avec trois boutons **Read / Done / Close** qui appliquent
la sémantique verrouillée du design.

Table de vérité (issue du design figé — encode la décision) :

| Action | Présence liste | Flag read | Effet badge |
|--------|----------------|-----------|-------------|
| **Read** | reste | → lu | −1 (si était non-lu) |
| **Done** | retirée | (n/a) | −1 (si était non-lu) |
| **Close** | reste (ferme le détail) | inchangé | inchangé |
| Ouvrir (tap) | reste | inchangé | inchangé |

Scénario de contrôle (2 non-lues A, B) : `Read A → [A(lu), B]` badge 2→1 ; `Done A → [B]` badge 2→1 ;
`Close A → [A, B]` badge 2→2 (A toujours non-lu).

- Vue détail (niveau 2) rendue en `Text(verbatim:)` pour le contenu runtime ; boutons au style de
  bouton primaire du repo ; libellés statiques localisés (posés en slice 6).
- Actions `markRead` / `markDone` / fermeture (retour liste) dans le VM. **Ouvrir n'affecte aucun état.**
- **Validation + fallback de l'`icon` custom** SF Symbol : valider via l'API SF Symbol ; symbole
  invalide → repli sur l'icône par défaut du `level`.

## Acceptance criteria

- [ ] Un tap sur une ligne ouvre le détail sans changer aucun état (ni `read`, ni présence, ni badge).
- [ ] **Read** marque l'item lu, le garde dans la liste, décrémente le badge s'il était non-lu.
- [ ] **Done** retire l'item de la liste, décrémente le badge s'il était non-lu.
- [ ] **Close** referme le détail sans rien changer (l'item reste non-lu s'il l'était).
- [ ] Une `icon` SF Symbol invalide retombe sur l'icône par défaut du `level`.
- [ ] Le summary multi-ligne s'affiche entièrement dans le détail, en `Text(verbatim:)`.
- [ ] **Seam 1** : tests couvrant toute la table Read/Done/Close + le scénario de contrôle A/B.

## Blocked by

- Slice 1 (`01-tracer-inbox-vm-carousel-page`)

> Synergie avec Slice 2 (`02-ambient-badge`) pour observer visuellement la décrémentation du badge,
> mais non bloquant : la logique est vérifiable au Seam 1.
