# Slice 6 — Réglages (toggle unique) + localisation

Status: ready-for-agent

## Parent

`.scratch/notifications/PRD.md` — Live Activity « Notifications ».
Signatures vérifiées : `docs/notifications-feature-spec.md` (§10, §15.7, §15.10).

## What to build

Transforme le câblé-actif-en-dur de la slice 1 en une vraie option, et localise les libellés statiques.

- **Un seul toggle « Notifications »** qui active/désactive **ensemble** le badge ambiant et la page
  carousel. Nouveau store de réglages (sur le modèle `SettingsStoreBase`) avec `isEnabled` persisté.
- Gating : badge caché et page absente/masquée quand le toggle est off ; le monitor peut continuer à
  drainer (à trancher côté implémentation, mais l'affichage est gaté sur le toggle).
- Écran de réglages dédié : le toggle + **« Révéler l'inbox dans le Finder »** + **« Vider »**,
  enregistré dans les sections de réglages.
- La page participe à l'ordre des pages Home comme les 4 autres : ajouter `"notifications"` aux valeurs
  par défaut de l'ordre des pages et à la persistance des pages activées.
- La ligne de priorité « Notifications » (posée en slice 2) reste auto-affichée via les clés
  configurables.
- **Localisation** : nouvelles chaînes statiques (« Notifications » + sous-titre de page, « Read » /
  « Done » / « Close » / « Vider », libellés de l'écran de réglages) dans le catalogue de localisation
  (en / es / ru / zh-Hans). Le contenu runtime des scripts n'y va **pas** (rendu en `Text(verbatim:)`).

## Acceptance criteria

- [ ] Le toggle « Notifications » off masque à la fois le badge ambiant et la page carousel ; on le rallume et les deux reviennent.
- [ ] « Révéler l'inbox dans le Finder » ouvre le dossier `inbox`.
- [ ] « Vider » (réglages) vide la liste et remet `unreadCount` à 0 (réutilise l'action du VM).
- [ ] La page « Notifications » apparaît dans l'ordre des pages Home par défaut et respecte activation/désactivation comme les autres.
- [ ] Les libellés statiques sont traduits en en / es / ru / zh-Hans ; le contenu runtime reste en `Text(verbatim:)`.

## Blocked by

- Slice 1 (`01-tracer-inbox-vm-carousel-page`)
- Slice 2 (`02-ambient-badge`)
