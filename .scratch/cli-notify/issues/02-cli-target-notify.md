Status: done

# Slice 2 — Target CLI `dynamicnotch notify`

## What to build

Créer un **nouveau target Xcode** produisant un binaire exécutable `dynamicnotch`, dépendant du module
`NotificationContract` (slice 1) et de `swift-argument-parser`. Il expose la sous-commande `notify` qui
construit un `NotificationPayload` et le dépose atomiquement dans l'inbox. Voir
`docs/cli-notify-feature-spec.md` §3, §4, §6.

### Surface

```
dynamicnotch notify --title <t> [--summary <s>] [--level <l>] [--source <src>] [--icon <i>]
```

- `--title` : requis.
- `--summary` : requis **via ce flag OU via stdin** — si `--summary` absent, lire **tout stdin** comme
  summary. Ni flag ni stdin → erreur. `--title` ne vient jamais de stdin.
- `--level` : défaut `info` ; **strict** — mappé sur `NotificationLevel` via `ExpressibleByArgument` ;
  valeur inconnue → erreur immédiate (pas de downgrade silencieux).
- `--source`, `--icon` : optionnels.
- `--help` : fourni par argument-parser.

### Comportement

1. Parse (argument-parser) → construit `NotificationPayload` (module).
2. Résout l'inbox via `NotificationInbox.resolvedURL` (honore `$DYNAMICNOTCH_INBOX`), crée le dossier si
   absent.
3. Dépose via `AtomicInboxDrop.write(payload, to: inbox)` (temp `.`-préfixé → `rename` `<uuid>.json`).
4. Sortie `0` si déposé ; `≠ 0` si arguments invalides ou échec d'écriture.

### Testabilité

- Extraire la logique dans une **fonction/type testable** prenant l'`URL` d'inbox (et une source de
  summary) en paramètre. Le `main()` (parsing + appel) reste **glue non testée**.

## Acceptance criteria

- [ ] Target exécutable `dynamicnotch` créé (édition `.pbxproj` acceptée), dépend de
      `NotificationContract` + `swift-argument-parser`.
- [ ] `dynamicnotch notify --title … --summary …` dépose un `<uuid>.json` valide dans l'inbox résolue.
- [ ] `--summary` absent + stdin fourni ⇒ summary = stdin ; les deux absents ⇒ erreur (exit ≠ 0).
- [ ] `--level` inconnu ⇒ erreur immédiate (exit ≠ 0), **aucun** fichier déposé.
- [ ] `--title` ou `--summary` (flag+stdin) manquant ⇒ exit ≠ 0.
- [ ] `$DYNAMICNOTCH_INBOX` respecté ; inbox absente ⇒ créée puis drop réussi.
- [ ] `dynamicnotch --help` / `dynamicnotch notify --help` affichent une aide correcte.
- [ ] **Tests seam 2 (roi)** : le cœur du CLI dépose dans une inbox temp (`$DYNAMICNOTCH_INBOX`) → le
      **vrai `NotificationInboxMonitor`** l'ingère → le payload attendu ressort via `onPayload`
      (calquer `NotificationInboxMonitorIntegrationTests`). Assertions complémentaires : nom final sans
      `.` et unique ; `summary` stdin ; `--level` invalide → exit ≠ 0 + aucun fichier ; inbox créée.
- [ ] L'app et le CLI compilent ; tests verts (`CODE_SIGNING_ALLOWED=NO`).

## Blocked by

Slice 1 (module `NotificationContract`).
