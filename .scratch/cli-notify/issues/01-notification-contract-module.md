Status: ready-for-agent

# Slice 1 — Module partagé `NotificationContract`

## What to build

Créer un **Swift Package local** `NotificationContract` (Foundation pur, zéro dépendance) et y déplacer
le contrat de fil aujourd'hui dispersé dans l'app, puis recâbler l'app pour le consommer. C'est la
fondation des slices suivantes (le CLI en dépendra). Voir `docs/cli-notify-feature-spec.md` §2, §4, §6.

### Contenu du module (`public`)

1. `NotificationPayload` — déplacé depuis
   `DynamicNotch/Features/Notifications/Models/NotificationPayload.swift`, **rendu `Codable`** (il est
   aujourd'hui `Decodable` seul). Conserver la validation custom au decode (`title`/`summary` non-blancs,
   `level` inconnu toléré → `.info`). ⚠️ Garder l'`enum CodingKeys` **accessible** à l'`Encodable`
   synthétisé (ne pas le laisser `private` dans une extension isolée) — sinon erreur de compil.
2. `NotificationLevel` — **cœur uniquement** : `enum` rawValue, `Codable` dérivé, `Comparable` + ordre de
   sévérité (`info < success < warning < error`). Déplacé depuis
   `DynamicNotch/Features/Notifications/Models/NotificationItem.swift`.
3. `NotificationInbox` — dérivation du chemin d'inbox : `defaultURL`
   (`~/Library/Application Support/DynamicNotch/inbox`) + `resolvedURL` qui honore la variable d'env
   `DYNAMICNOTCH_INBOX` si présente, sinon `defaultURL`.
4. `AtomicInboxDrop` — mécanisme de drop atomique : écrit un temp **`.`-préfixé dans le dossier inbox**,
   puis `rename` vers `<uuid>.json` **dans le même dossier** (nom final unique, jamais de collision ;
   temp intra-dossier = atomicité même sans hypothèse de volume). Crée le dossier s'il est absent.

### Recâblage app (reste app-side)

- `NotificationLevel.color` / `.defaultIconName` (SwiftUI/AppKit) → `extension` sur l'enum **importé**,
  dans le target app.
- `NotificationItem` → reste app-internal, `import NotificationContract` pour réutiliser
  `NotificationLevel` et `NotificationPayload`.
- `AppContainer.notificationsInboxDirectory` → délègue à `NotificationInbox` (une seule dérivation).
- `DynamicNotchTests/TestSupport/InboxDropTestHelpers.swift` → délègue à `AtomicInboxDrop` (une seule
  implémentation d'écriture atomique partagée par le CLI et les tests).
- Ajouter la dépendance de package au projet Xcode (édition ponctuelle du `.pbxproj` **acceptée**).

## Acceptance criteria

- [ ] Package local `NotificationContract` créé, lié par le target app, Foundation pur (aucune dépendance,
      aucun `import SwiftUI`/`AppKit`).
- [ ] `NotificationPayload` est `Codable` ; encode produit les clés `title/summary/level/source/icon` ;
      la validation au decode est préservée à l'identique.
- [ ] `NotificationLevel` (cœur) vit dans le module ; `color`/`defaultIconName` restent dans l'app via
      extension sur l'enum importé.
- [ ] `NotificationInbox.resolvedURL` honore `$DYNAMICNOTCH_INBOX` ; `defaultURL` reproduit le chemin
      actuel d'`AppContainer`.
- [ ] `AtomicInboxDrop` écrit temp `.`-préfixé dans l'inbox → `rename` en `<uuid>.json` ; crée l'inbox si
      absente ; nom final unique par appel.
- [ ] `AppContainer` et `InboxDropTestHelpers` consomment le module (aucune dérivation/écriture dupliquée).
- [ ] **Tests seam 1** (dans le package) : round-trip encode→decode égal ; `level` inconnu → `.info` ;
      `title`/`summary` blanc → throw ; `resolvedURL` honore l'env.
- [ ] L'app compile et **tous les tests existants restent verts**
      (`xcodebuild test … CODE_SIGNING_ALLOWED=NO`).

## Blocked by

None — fondation.
