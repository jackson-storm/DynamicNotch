# Slice 1 — Tracer : inbox → VM → page carousel (persistée)

Status: done

## Parent

`.scratch/notifications/PRD.md` — Live Activity « Notifications ».
Signatures vérifiées et fichiers de référence : `docs/notifications-feature-spec.md`.

## What to build

Le squelette end-to-end complet de la feature, câblé **actif en dur** (pas encore de toggle de
réglages). Comportement démontrable : un script dépose un fichier JSON dans le dossier `inbox`,
l'app l'ingère, le supprime, et l'affiche dans une nouvelle page « Notifications » du carousel Home ;
la liste survit au redémarrage de l'app.

Trois briques traversées de bout en bout :

1. **Monitor d'inbox** — surveille `inbox` sous Application Support (créé s'il est absent) via un
   watcher `DispatchSource` de dossier. À l'init, **drain** : consomme tous les `.json` déjà présents
   (couvre les drops arrivés app fermée). Ne traite que les `*.json` **ne commençant pas par `.`**.
   Par fichier : parse → l'app stampe `id`/`receivedAt`/`read=false` → pousse dans le VM → **supprime**
   le fichier. Parse en échec → **retry-in-place** après un délai **injectable** (défaut ~200 ms) →
   si toujours en échec, **déplace vers `inbox/rejected/`** + log, **jamais de crash**. `title` ou
   `summary` manquant → item rejeté (validation au parse). Le monitor prend son **répertoire inbox**
   et son **délai de retry** par injection.

   Contrat JSON (ce que le script écrit ; issu du design figé) :
   ```json
   {
     "title":   "Backup nightly",               // requis
     "summary": "42 fichiers, 1.2 GB\nOK",       // requis, multi-ligne
     "level":   "success",                       // opt: info|success|warning|error (défaut info)
     "source":  "backup.sh",                     // opt (coalescence — slice 4)
     "icon":    "externaldrive.badge.checkmark"  // opt (rendu — slice 3)
   }
   ```

2. **ViewModel partagé** (`NotificationCenterViewModel`) — détient la liste, ajoute chaque payload en
   **append** (pas de coalescence dans cette slice), expose `unreadCount` (tout est non-lu ici) et la
   **plus haute sévérité non-lue** (`NotificationLevel` : couleur + icône par défaut + ordre
   error>warning>success>info). Action `clearAll` (Vider). **Persistance** JSON dans un `UserDefaults`
   injecté (pattern du File Tray) ; restaurée à l'init, badge recalculé depuis `unreadCount`. Le VM
   prend le monitor par un protocole (`NotificationInboxMonitoring`, sur le modèle de
   `DownloadMonitoring`) et le `UserDefaults` par injection.

3. **Page carousel** — nouveau `case notifications` dans l'énumération des pages Home (title/subtitle/
   icon/tint) + rendu dans la fabrique de vue de page + `switch` de sizing du contenu Home. Vue liste
   **read-only** : par ligne, barre/point couleur `level` + `title` + `source` + heure + point
   « non-lu » ; en-tête = titre + bouton **« Vider »**. Contenu runtime des scripts rendu en
   **`Text(verbatim:)`** (jamais interprété comme clé de localisation).

DI dans le conteneur d'app (VM + monitor) et branchement dans le coordinateur d'événements du notch :
démarrage du monitor + drain initial au point de première-activation existant.

## Acceptance criteria

- [ ] Un `.json` valide déposé dans `inbox` apparaît dans la page « Notifications » du carousel, puis le fichier est supprimé.
- [ ] Les `.json` présents avant le lancement de l'app sont ingérés au démarrage (drain).
- [ ] Un JSON malformé est déplacé vers `inbox/rejected/` (après retry), loggué, sans crash ni item ajouté.
- [ ] Un item sans `title` ou sans `summary` est rejeté.
- [ ] Les fichiers commençant par `.` et les non-`.json` sont ignorés du scan.
- [ ] La liste et son état sont restaurés à l'identique après redémarrage de l'app.
- [ ] `title`/`summary`/`source` s'affichent en `Text(verbatim:)` (un titre « 50% done » s'affiche tel quel).
- [ ] Le bouton « Vider » du header vide la liste et remet `unreadCount` à 0.
- [ ] **Seam 1** (VM) : tests append, `unreadCount`, `highestUnreadLevel` sur liste mixte, `clearAll`, round-trip de persistance sur `UserDefaults` isolé.
- [ ] **Seam 2** (monitor) : tests sur dossier temp — ingestion+delete, malformé→`rejected/` (retry ≈0), validation `title`/`summary`, dotfiles/non-json ignorés, drain au lancement.

## Blocked by

None - can start immediately.
