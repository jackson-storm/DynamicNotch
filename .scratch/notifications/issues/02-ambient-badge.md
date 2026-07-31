# Slice 2 — Badge ambiant (live activity compacte)

Status: done

## Parent

`.scratch/notifications/PRD.md` — Live Activity « Notifications ».
Signatures vérifiées : `docs/notifications-feature-spec.md` (§7, §15.1–15.3, §15.8).

## What to build

Un **badge ambiant** sur le notch au repos : dès qu'il existe au moins une notification non-lue, une
**cloche + un compteur** apparaît, teinté par la **plus haute sévérité non-lue**
(error > warning > success > info). Un clic déplie la **liste** (la vue de la slice 1). Le badge
**disparaît dès `unreadCount == 0`**, même si des notifications lues restent dans la liste (elle reste
accessible via le carousel).

- Nouvelle **live activity compacte** enregistrée dans le registre de contenu (id `notifications.badge`).
  Vue compacte = cloche + compteur numérique animé (réutiliser le composant de compteur animé du File
  Tray), teinte = plus haute sévérité non-lue. Vue dépliée (`makeExpandedView`) = la vue liste de la
  slice 1. `isExpandable = true`.
- Nouveau `case notifications` dans l'énumération de priorité : `defaultValue` au **tier repos** (≈ 0,
  pair de VPN, au-dessus de la page Home), + titleKey / image (`bell.fill`) / color, et ajout aux clés
  configurables (une ligne apparaît alors automatiquement dans Réglages > Priorités).
- **Câblage réactif** dans le coordinateur d'événements : sur mutation du VM, `show`/`hide` de la live
  activity badge selon `unreadCount > 0` (pattern show/hide du File Tray). La décision de visibilité est
  une propriété du VM ; le coordinateur ne fait que la relayer.

## Acceptance criteria

- [ ] Au repos, quand `unreadCount > 0`, la cloche + compteur s'affiche sur le notch.
- [ ] La teinte du badge suit la plus haute sévérité non-lue (error > warning > success > info).
- [ ] Le compteur reflète exactement `unreadCount` et s'anime à chaque changement.
- [ ] Un clic sur le badge déplie la vue liste (slice 1).
- [ ] Le badge disparaît dès `unreadCount == 0`, même si la liste n'est pas vide.
- [ ] Une ligne de priorité « Notifications » est éditable dans Réglages > Priorités.
- [ ] **Seam 1** : tests de la visibilité du badge (vrai ssi `unreadCount > 0`) et de `highestUnreadLevel` sur listes mixtes (déjà posés en slice 1, étendus si besoin).

## Blocked by

- Slice 1 (`01-tracer-inbox-vm-carousel-page`)
