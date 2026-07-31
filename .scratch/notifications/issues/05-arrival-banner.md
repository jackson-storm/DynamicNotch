# Slice 5 — Bannière à l'arrivée (~3 s)

Status: done

## Parent

`.scratch/notifications/PRD.md` — Live Activity « Notifications ».
Signatures vérifiées : `docs/notifications-feature-spec.md` (§8, §15.2, §15.5).

## What to build

Une **bannière transitoire** (~3 s) à chaque nouvel item quand l'app est active, pour garantir qu'on ne
rate jamais un push même si le badge ambiant est couvert par une live activity plus prioritaire.

- Sur **nouvel** item (app active) : le VM émet un signal « nouvel item » que le coordinateur relaie en
  `send(.showTemporaryNotification(content, duration: 3.0))`, avec une petite vue title+summary teintée
  par `level` (même mécanisme que le toast « langue changée »).
- App **fermée** à l'arrivée → **pas de bannière rétroactive** ; seulement le badge au prochain drain.
- Les rafales sont sérialisées par la file d'événements existante du moteur du notch (pas de collision).
- Distinguer « nouvel item » (déclenche bannière) d'une simple mutation d'état (Read/Done/coalescence ne
  redéclenchent pas de bannière hormis l'arrivée d'un nouveau drop).

## Acceptance criteria

- [ ] Un nouveau drop reçu app active affiche une bannière title+summary ~3 s teintée par `level`.
- [ ] Les items ingérés au drain (app fermée à l'arrivée) n'affichent **aucune** bannière rétroactive.
- [ ] Une rafale de drops n'entraîne pas de collision d'affichage (file d'événements).
- [ ] Une action Read/Done/Close ne déclenche pas de bannière.

## Blocked by

- Slice 1 (`01-tracer-inbox-vm-carousel-page`)

> Recommandé après Slice 2 (`02-ambient-badge`) : réutilise le handler/câblage du coordinateur
> introduit pour le badge.
