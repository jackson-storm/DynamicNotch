# Spec — CLI `dynamicnotch notify`

> Résultat d'une session de grilling (17 nœuds tranchés). Ajoute un **binaire en ligne de
> commande** `dynamicnotch` qui pousse une notification dans DynamicNotch depuis n'importe quel
> process externe (scripts, cron, CI, Raccourcis via action shell…), en encapsulant le boilerplate
> « construire un JSON valide + écriture atomique dans l'inbox ». Le CLI est une **couche
> d'ergonomie au-dessus du contrat file-drop existant** : il n'ouvre aucun nouveau canal IPC.
> Statut : **design figé**, prêt à implémenter.

---

## 0. Problème

Le seul point d'entrée externe actuel est le dossier `inbox` (dépôt de `<uuid>.json` atomique). Il
**fonctionne** mais impose à chaque script de : (a) connaître le chemin de l'inbox, (b) construire un
JSON valide en échappant guillemets/retours-ligne, (c) écrire de façon atomique (temp + `mv`). Ce
boilerplate est fragile (un `title` avec `"` ou `\n` casse un `printf`) et non réutilisable hors shell.
Le CLI supprime les trois frictions d'un coup.

**Non-objectif :** aucun accusé de *réception/affichage* (canal synchrone écarté). Le succès du CLI =
« fichier déposé atomiquement dans l'inbox », rien de plus. L'app draine et affiche selon sa propre
logique (déjà spécifiée dans `notifications-feature-spec.md`).

---

## 1. Décisions verrouillées (grill)

| # | Sujet | Décision |
|---|-------|----------|
| 1 | Friction ciblée | **B** (boilerplate JSON + atomicité) + **C** (appel hors-shell). |
| 2 | Interface | **CLI seul** — tous les appelants réels sont lançables en process (shell, Python, Node, cron, CI, Raccourcis via action shell). Pas d'URL scheme. |
| 3 | Transport | Le CLI **écrit dans l'inbox** (temp `.`-préfixé → `rename`). Couche fine au-dessus du file-drop ; marche **app fermée** (drain au prochain lancement) ; zéro nouvel IPC. |
| 4 | Langage | **Binaire Swift**, nouveau target Xcode. |
| 5 | Partage | **Swift Package local `NotificationContract`** lié par l'app **et** le CLI. Édition ponctuelle du `.pbxproj` acceptée. |
| 6 | Portée du module | Contrat de **données** (`NotificationPayload` `Codable` + cœur `NotificationLevel`) **+ helper de chemin d'inbox + mécanisme de drop atomique**. La présentation (`color`/`defaultIconName`) et `NotificationItem` **restent app-side**. |
| 7 | Distribution | Binaire **embarqué dans le `.app`** + bouton Réglages **« Installer l'outil CLI »** → symlink `/usr/local/bin`, escalade admin si non-writable, **idempotent**. |
| 8 | Surface | Sous-commande **`notify`** + flags `--title`/`--summary` (requis), `--level` (défaut `info`, **strict**), `--source`/`--icon` (opt). `summary` **via flag ou stdin**. |
| 9 | Parsing | **`swift-argument-parser`** (dépendance du target CLI, PAS du module). |
| 10 | Nom binaire | **`dynamicnotch`** (pas d'alias court imposé). |
| 11 | Chemin inbox | Dérivation **partagée dans le module** ; le CLI **crée l'inbox si absente** ; override via env **`DYNAMICNOTCH_INBOX`**. |
| 12 | Nom de fichier | **Unique par invocation (UUID)** — corrige le bug de collision du one-liner à nom fixe (rafale). |
| 13 | Tests | Seam 1 : round-trip Codable dans le module. Seam 2 **roi** : CLI → **vrai `NotificationInboxMonitor`** sur temp dir → payload via callback. |
| 14 | Docs | README : CLI en voie **principale**, file-drop conservé comme couche bas-niveau. CLI **anglais-only** ; libellés du bouton Réglages **localisés** (en/es/ru/zh-Hans). |

---

## 2. Architecture

```
Script externe
  └─ dynamicnotch notify --title … --summary … [--level …] [--source …] [--icon …]
       │  (ou:  job | dynamicnotch notify --title …   ← summary depuis stdin)
       ▼
  [target CLI]  parse (swift-argument-parser) → NotificationPayload (module)
       │  résout inbox (module: NotificationInbox.resolvedURL, honore $DYNAMICNOTCH_INBOX)
       │  mkdir -p inbox si absente
       │  drop atomique (module: AtomicInboxDrop) → écrit  .<uuid>.tmp  dans l'inbox
       │                                            → rename en  <uuid>.json  (même dossier)
       ▼
  ~/Library/Application Support/DynamicNotch/inbox/<uuid>.json
       ▼
  [app]  NotificationInboxMonitor (watch + drain)  ──►  NotificationCenterViewModel  ──►  badge / bannière / page
```

**Frontière du module partagé** (`NotificationContract`, pur Foundation, zéro dépendance) :

| Élément | Emplacement | Visibilité |
|---------|-------------|-----------|
| `NotificationPayload` (rendu **`Codable`**) | module | `public` |
| `NotificationLevel` — cœur (rawValue, `Codable` dérivé, `Comparable`, ordre de sévérité) | module | `public` |
| Helper chemin inbox (`NotificationInbox.defaultURL` + `.resolvedURL` honorant `$DYNAMICNOTCH_INBOX`) | module | `public` |
| Mécanisme de drop atomique (`AtomicInboxDrop.write(_:to:)` → temp `.`-préfixé + `rename`, nom `<uuid>.json`) | module | `public` |
| `NotificationLevel.color` / `.defaultIconName` (SwiftUI/AppKit) | **app**, `extension` sur l'enum importé | app-only |
| `NotificationItem` (`id`/`receivedAt`/`read`) | **app**, importe le module | app-internal |

`AppContainer.notificationsInboxDirectory` et `InboxDropTestHelpers` sont recâblés pour **consommer** le
helper de chemin et le mécanisme de drop du module (une seule implémentation, zéro dérive).

---

## 3. Contrat CLI (surface publique)

```
USAGE: dynamicnotch notify --title <title> [--summary <summary>] [--level <level>]
                           [--source <source>] [--icon <icon>]

OPTIONS:
  --title    <title>    (requis)   Titre court.
  --summary  <summary>  (requis*)  Corps multi-ligne. *Requis via ce flag OU via stdin :
                                   si --summary est absent, le CLI lit tout stdin comme summary.
                                   Ni flag ni stdin → erreur (exit ≠ 0).
  --level    <level>    (défaut info)  Un de: info | success | warning | error.
                                   Valeur inconnue → erreur immédiate (PAS de downgrade silencieux).
  --source   <source>              Clé de coalescence + sous-titre.
  --icon     <icon>                Nom SF Symbol (fallback app-side si invalide).
  -h, --help                       Aide auto (argument-parser).
```

Exemples :

```bash
dynamicnotch notify --title "Backup nightly" \
  --summary $'42 fichiers, 1.2 GB\nOK' --level success \
  --source backup.sh --icon externaldrive.badge.checkmark

backup.sh 2>&1 | dynamicnotch notify --title "Backup nightly" --level success --source backup.sh
```

**Codes de sortie :** `0` = fichier déposé atomiquement dans l'inbox. `≠ 0` = arguments invalides
(`--title`/`--summary` manquant, `--level` inconnu) **ou** échec d'écriture. Aucun accusé de réception.

**Env :** `DYNAMICNOTCH_INBOX` surcharge le dossier d'inbox (tests + power-users). Non documenté dans
le README « grand public » ; détail avancé.

---

## 4. Correction du dépôt atomique (issue du grilling)

Le one-liner historique (`mv "$tmp" "${INBOX}/drop.json"`) a **deux défauts** que le CLI corrige et que
`AtomicInboxDrop` encode :

1. **Nom final fixe → collision sous rafale.** Deux drops avant ingestion du premier ⇒ le 2e `mv` écrase
   le 1er ⇒ notif perdue (viole la story « rafale sans collision »). ⟶ **nom final unique `<uuid>.json`
   par invocation.**
2. **`mv` cross-volume non atomique.** Le temp doit être **dans le dossier inbox** (préfixé `.`, donc
   ignoré par le monitor), suivi d'un `rename` **dans le même dossier**. Jamais `NSTemporaryDirectory()`.

Détail Swift : en passant `NotificationPayload` de `Decodable` à `Codable`, garder l'`enum CodingKeys`
**accessible** à l'`Encodable` synthétisé (ne pas le laisser `private` dans une extension `Decodable`
isolée) — sinon erreur de compilation.

---

## 5. Distribution & installation

- **Build phase** : le binaire `dynamicnotch` est copié dans le bundle (`DynamicNotch.app/Contents/…`).
- **Bouton Réglages « Installer l'outil CLI »** : crée un symlink `/usr/local/bin/dynamicnotch` →
  binaire embarqué. Le symlink pointe **dans le bundle** ⇒ chaque update de l'app met à jour le CLI.
  - Si `/usr/local/bin` non-writable (fréquent Apple Silicon) : escalade admin via
    `osascript … with administrator privileges` (app **non-sandboxée** ⇒ autorisé), **un seul prompt**.
  - **Idempotent** : ré-appui = recrée/écrase un symlink périmé. Message clair en cas d'échec.
- **Risque à vérifier (slice 3)** : un binaire signé dans le bundle, lancé depuis `/usr/local/bin` via
  symlink, doit s'exécuter sans friction Gatekeeper/quarantine. En pratique OK pour une app déjà
  installée lancée en Terminal, mais **budgéter la vérif** — casse silencieuse possible à la 1re install.
- Libellés du bouton et messages : **localisés** en/es/ru/zh-Hans.

---

## 6. Tests

**Seam 1 — module `NotificationContract`** (logique pure, sans FS) :
- **Round-trip Codable** : encoder un `NotificationPayload` → re-decoder → égalité. Attrape l'asymétrie
  entre le `Decodable` custom (validation) et l'`Encodable` synthétisé.
- `level` inconnu au decode → `.info` (comportement toléré existant, préservé).
- `title`/`summary` blanc au decode → throw.
- `NotificationInbox.resolvedURL` honore `$DYNAMICNOTCH_INBOX` quand présent, sinon `defaultURL`.

**Seam 2 — CLI → pipeline réel** (intégration FS, dossier injecté via `$DYNAMICNOTCH_INBOX`) :
- **Test roi** : le cœur du CLI dépose dans une inbox temp → le **vrai `NotificationInboxMonitor`**
  l'ingère → le payload attendu ressort via `onPayload`. Prior art : `NotificationInboxMonitorIntegrationTests`.
- Fichier final **ne commence pas par `.`** et est unique (preuve atomicité + anti-collision).
- `summary` depuis stdin ⇒ payload correct.
- `--level` invalide ⇒ sortie ≠ 0, **aucun** fichier déposé.
- Inbox absente ⇒ créée puis drop réussi.

**Hors test (glue assumée)** : le `main()` du CLI (parsing argument-parser + appel du cœur) et le code
UI du bouton d'installation (symlink/osascript). La logique testable du CLI est **extraite** dans une
fonction/type prenant l'`URL` d'inbox en paramètre.

---

## 7. Ordre d'implémentation (slices)

1. **Module `NotificationContract`** — extraction payload+level (→ `Codable`), helper chemin, drop
   atomique ; recâblage `AppContainer`/`NotificationItem`/extensions présentation/`InboxDropTestHelpers`.
   Tests seam 1. *App verte, tests existants verts.*
2. **Target CLI `dynamicnotch`** — `notify` + argument-parser + cœur de drop + stdin + override env.
   Tests seam 2 (CLI → vrai monitor).
3. **Bouton « Installer l'outil CLI »** — build phase d'embarquement + symlink `/usr/local/bin` +
   escalade admin + idempotence + libellés localisés + vérif Gatekeeper.
4. **Docs README** — CLI en voie principale, file-drop en couche bas-niveau, CLI anglais-only.
