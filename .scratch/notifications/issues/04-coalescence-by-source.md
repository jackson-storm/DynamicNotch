# Slice 4 — Coalescence par `source`

Status: ready-for-agent

## Parent

`.scratch/notifications/PRD.md` — Live Activity « Notifications ».
Signatures vérifiées : `docs/notifications-feature-spec.md` (§5).

## What to build

Le regroupement des notifications par `source`, pour qu'un script bavard ne remplisse pas la liste de
doublons.

- Drop dont le `source` **existe déjà** dans la liste → **remplace** le contenu de l'item existant,
  le **repasse non-lu** (`read=false`, badge +1 s'il était lu), met à jour `receivedAt`, et le
  **remonte en tête** de liste.
- Drop **sans `source`** → toujours traité comme **unique** (append), jamais fusionné (sinon tous les
  sans-source s'écraseraient entre eux).
- Remplace la logique d'append pur de la slice 1 par cette règle add/coalesce dans le VM.

## Acceptance criteria

- [ ] Un second drop d'une `source` connue met à jour l'item existant (contenu + `receivedAt`) au lieu d'en créer un nouveau.
- [ ] L'item coalescé remonte en tête de liste.
- [ ] Coalescer un item **lu** le repasse non-lu et incrémente le badge (+1).
- [ ] Deux drops **sans `source`** produisent **deux** items distincts (jamais fusionnés).
- [ ] **Seam 1** : tests coalescence (replace/reorder/re-unread), re-unread d'un item lu → badge +1, sans-source = append jamais fusionné, `receivedAt` mis à jour.

## Blocked by

- Slice 1 (`01-tracer-inbox-vm-carousel-page`)
