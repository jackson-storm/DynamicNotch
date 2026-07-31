# Spec — Live Activity « Notifications »

> Résultat d'une session de grilling. Ajoute une 5e page Home (`Notifications`) qui affiche
> des résumés poussés par des scripts externes, avec un badge ambiant `(1)` sur le notch.
> Statut : **design figé**, prêt à implémenter. Les points marqués 🟡 sont des défauts
> résolus par recommandation — faciles à inverser.

---

## 1. Décisions verrouillées (grill)

| # | Sujet | Décision |
|---|-------|----------|
| 1 | Visibilité du badge | **Ambiant** : visible sur le notch au repos (nouvelle live activity compacte dédiée), PAS seulement dans le carousel. |
| 2 | Transport (ingestion) | **Dossier `inbox` surveillé** : chaque script écrit un `<uuid>.json`, l'app watch + lit + supprime. Durable (draine au lancement), zéro vol de focus. |
| 3 | Sémantique Read/Done/Close | **Badge = nb de non-lues encore dans la liste** (jamais de fantôme). Voir §4. |
| 4 | À l'arrivée | **Bannière transitoire ~3s** (title+summary via `showTemporaryNotification`), puis badge ambiant. |
| 5 | Payload | **Riche** : `title` + `summary` + `level` + `source` + `icon`. Voir §3. |
| 6 | Coalescence | **Par `source`** : 1 notif max par source (le nouveau drop écrase). Sans source → append. Voir §5. |
| 7 | Apparence badge | **Icône cloche + compteur**, couleur = **plus haute sévérité non-lue**. Clic → ouvre la liste. |
| 8 | UX page | **Liste → détail (2 niveaux)**. Ouvrir NE marque PAS lu. |
| 9 | Rétention | **Pas de plafond**, juste un bouton **« Vider »**. On s'appuie sur la coalescence-par-source ; les notifs sans `source` peuvent s'accumuler (tradeoff assumé). |
| 10 | Cohabitation | **Ambiant best-effort** : live activity au tier repos (priorité configurable), couverte par les activités plus prioritaires, mais la bannière garantit qu'on ne rate jamais un push. Réutilise l'écran Réglages > Priorités. |

---

## 2. Vue d'ensemble

Deux points d'entrée vers **la même liste** :
- **Badge ambiant** (nouvelle live activity compacte `notifications.badge`) → clic → liste dépliée.
- **Page carousel** `Notifications` (5e `case` de `HomePages`) → même vue liste.

Un seul **ViewModel partagé** (`NotificationCenterViewModel`) détient la liste, l'état lu/non-lu,
le compteur, la plus haute sévérité, et les actions. Un **monitor** (`NotificationInboxMonitor`)
surveille le dossier inbox et pousse les nouveaux items dans le VM.

```
scripts ──> ~/Library/Application Support/DynamicNotch/inbox/*.json
                     │  (DispatchSource file watcher)
                     ▼
        NotificationInboxMonitor  ──parse+coalesce+delete──►  NotificationCenterViewModel
                                                                     │  @Published items / unreadCount / highestUnreadLevel
                        ┌────────────────────────────────────────────┼───────────────────────────────┐
                        ▼                                            ▼                                 ▼
       NotchNotificationsEventsHandler                    NotificationsBadgeNotchContent      HomePages.notifications
       - show/hide badge si unread>0 & enabled            (compact = badge, expanded = liste)  (page carousel = liste)
       - bannière ~3s à chaque nouvel item
```

---

## 3. Schéma JSON (ce que les scripts écrivent)

```json
{
  "title":   "Backup nightly",              // requis, court
  "summary": "42 fichiers, 1.2 GB\nOK",     // requis, multi-ligne
  "level":   "success",                      // opt: info | success | warning | error  (défaut: info)
  "source":  "backup.sh",                    // opt: clé de coalescence + sous-titre
  "icon":    "externaldrive.badge.checkmark" // opt: nom SF Symbol libre (fallback si invalide)
}
```

Ajoutés par l'app à la réception (le script ne les fournit pas) :
- `id` (UUID interne), `receivedAt` (timestamp stampé app), `read` (bool, défaut `false`).

**One-liner script de référence — écriture ATOMIQUE (temp + `mv`) :**
```bash
dir=~/"Library/Application Support/DynamicNotch/inbox"
mkdir -p "$dir"
tmp="$dir/.$(uuidgen).tmp"
cat > "$tmp" <<'EOF'
{"title":"Backup nightly","summary":"42 fichiers, 1.2 GB\nOK","level":"success","source":"backup.sh"}
EOF
mv "$tmp" "$dir/$(uuidgen).json"   # rename atomique sur le même volume
```
> ⚠️ **Ne PAS écrire directement dans le `.json` final** (`cat > .../x.json`) : le watcher peut lire
> le fichier pendant que `cat` écrit encore → parse partiel → notif perdue (race classique du drop-folder,
> cf. Maildir tmp→rename). Le `.tmp` commence par `.` pour être ignoré du scan.

**Mapping `level` → couleur / icône par défaut :**

| level | couleur | icône (si `icon` absent) |
|-------|---------|--------------------------|
| info (défaut) | neutre/blanc | `bell.fill` |
| success | vert | `checkmark.circle.fill` |
| warning | orange | `exclamationmark.triangle.fill` |
| error | rouge | `xmark.octagon.fill` |

🟡 `icon` custom validé via `NSImage(systemSymbolName:accessibilityDescription:)` ; si le symbole
n'existe pas → fallback sur l'icône du `level`.

---

## 4. Sémantique Read / Done / Close (le cœur)

**Invariant : `badge = nombre de notifs non-lues encore présentes dans la liste`.** Jamais > nb d'items.

| Action | Présence liste | Flag read | Effet badge |
|--------|----------------|-----------|-------------|
| **Read** | reste | → lu | −1 (si était non-lu) |
| **Done** | retirée | (n/a) | −1 (si était non-lu) |
| **Close** | reste (ferme juste le détail) | inchangé (reste non-lu) | inchangé |

- **Ouvrir** une notif (tap dans la liste) ≠ Read : ne change aucun état. Seul le bouton **Read** marque lu.
- **Close** ≈ « retour à la liste sans rien faire » (le bouton retour du détail).
- **« Vider »** (header liste) : supprime toutes les notifs → liste vide, badge 0.

Scénario de contrôle (2 non-lues A, B) :
```
Read A  -> liste=[A(lu), B]   badge 2->1
Done A  -> liste=[B]          badge 2->1
Close A -> liste=[A, B]       badge 2->2   (A toujours non-lu)
```

---

## 5. Coalescence

- Clé = **`source`**. Nouveau drop dont le `source` existe déjà → **remplace** le contenu de
  l'item existant, **le repasse non-lu** (`read=false`, badge +1 si il était lu), met à jour
  `receivedAt`, **remonte en tête** de liste.
- Drop **sans `source`** → traité comme **unique** (append), jamais fusionné (sinon tous les
  sans-source s'écraseraient entre eux). Recommandation d'usage : toujours mettre un `source`.
- **Pas de plafond** (choix Q9). Les notifs sans `source` peuvent donc s'accumuler indéfiniment —
  tradeoff assumé ; le « Vider » manuel est le seul reset. (Note : UserDefaults n'est pas idéal pour de
  gros blobs ; si l'accumulation devient réelle en pratique, rouvrir la question d'un plafond.)

---

## 6. Ingestion — détails du monitor

- Dossier : `~/Library/Application Support/DynamicNotch/inbox/` (créé au démarrage si absent).
  App **non sandboxée** (entitlements = camera + calendars uniquement, et elle shelle déjà
  `/usr/bin/log`, `scutil`… → sandbox définitivement exclu) : accès fichier libre, **pas d'app group**.
- Watcher : `DispatchSource.makeFileSystemObjectSource` (même pattern que `ClockTimerMonitor`).
- **Drain au lancement** : à l'init, énumérer + consommer tous les `.json` présents (couvre les
  drops arrivés app fermée).
- Ne scanner que les fichiers `*.json` **ne commençant pas par `.`** (ignore les `.tmp` en cours d'écriture).
- Cycle par fichier : parse → succès : append/coalesce dans le VM **puis `delete`** le fichier.
- Échec de parse : **retry-in-place** après un court délai (~200 ms) avant de rejeter — filet de sécurité
  si un script n'a pas fait d'écriture atomique (le fichier peut être en cours d'écriture). Après le retry :
  🟡 déplacer vers `inbox/rejected/` (debug) + log, **ne jamais crasher**.
- Trust boundary : n'importe quel process local peut écrire dans l'inbox. **Accepté** pour un usage
  perso (scripts de l'utilisateur).

---

## 7. Badge ambiant (live activity compacte)

- `NotchContentRegistry.Notifications.badge` (id `notifications.badge`, `priorityKey: .notifications`).
- Compact (`makeView`) = **cloche + `AnimatedLevelText(count)`**, teinte = plus haute sévérité non-lue
  (error > warning > success > info). Réutilise `AnimatedLevelText` (déjà utilisé par le File Tray).
- Déplié (`makeExpandedView`) = la vue **liste → détail**.
- Show/hide piloté comme le File Tray (`onItemsChange` → `send(.showLiveActivity/.hideLiveActivity)`)
  selon `unreadCount > 0` **ou** `items non vide` (à trancher : le badge disparaît-il quand tout est
  lu mais la liste non vide ? → **le badge disparaît dès `unreadCount == 0`** ; la liste reste
  accessible via le carousel).
- Priorité : nouveau `case .notifications` dans `NotchContentPriority.Key`, ajouté à `configurableKeys`,
  `defaultValue` au tier repos (≈ 0, peer de VPN, au-dessus de `homePage=-10000`). Configurable dans
  Réglages > Priorités (titre/icône/couleur à fournir).

---

## 8. Bannière à l'arrivée

- À chaque nouvel item (app active) : `notchViewModel.send(.showTemporaryNotification(content, duration: 3.0))`
  avec une petite vue title+summary teintée par `level` (même mécanisme que le toast « langue changée »).
- App fermée à l'arrivée → pas de bannière, juste le badge au prochain lancement (drain).
- Rafales : le `NotchEngine` met déjà les events en file (pas de collision).

---

## 9. UX page dépliée (liste → détail)

**Niveau 1 — Liste** (`NotificationsListNotchView`, réutilisée par badge-déplié ET page carousel) :
- `ScrollView` + `ForEach` (pattern `TrayExpandedActiveNotchView`), `maxHeight` ~120 + fade mask.
- Ligne : barre/point couleur = `level`, `title`, `source` + heure, point « non-lu ».
- Header : titre + bouton **« Vider »**. 🟡 (« Tout marquer lu » non retenu — Vider suffit.)
- Tap ligne → Niveau 2.

**Niveau 2 — Détail** (`NotificationDetailNotchView`) :
- `summary` complet multi-ligne, `title`, `source`, heure, icône.
- 3 boutons : **Read** / **Done** / **Close** (style `PrimaryButtonStyle`, cf. `VpnPageNotchView`).

> ⚠️ Le contenu fourni par script (`title`, `summary`, `source`) est du texte utilisateur runtime :
> le rendre avec **`Text(verbatim:)`** (idiome du repo, cf. `Text(verbatim: vpn.name)` dans `VpnPageNotchView`),
> **jamais** `Text(item.title)` — SwiftUI l'interpréterait comme `LocalizedStringKey` (un titre `"50% done"`
> ou qui collisionne avec une clé de traduction s'afficherait mal). Seuls les libellés statiques
> (« Read », « Done », « Vider »…) passent par la localisation.

---

## 10. Réglages

- 🟡 **Un seul toggle** « Notifications » (active badge ambiant + page carousel ensemble).
- La page participe à `homePageOrder` / `homePageDisabled` comme les 4 autres (add `"notifications"`
  aux `defaultValues`).
- Ligne de priorité auto-affichée via `configurableKeys`.
- Écran dédié `NotificationsSettingsView` : toggle + « Révéler l'inbox dans le Finder » + « Vider ».

---

## 11. Persistance

- Liste persistée en **JSON dans UserDefaults** (pattern `FileTrayViewModel.persistItems/restore`).
- Restaurée à l'init du VM ; badge recalculé depuis `unreadCount`.
- `receivedAt`, `read`, `level`, `source`, `icon` tous persistés.

---

## 12. Fichiers à créer / modifier

**Créer** (`Features/Notifications/`) :
- `Models/NotificationItem.swift` (+ `NotificationLevel` enum)
- `Models/NotificationPayload.swift` (DTO Decodable de l'inbox)
- `Core/Services/Notifications/NotificationInboxMonitor.swift`
- `ViewModels/NotificationCenterViewModel.swift`
- `Content/NotificationsBadgeNotchContent.swift`
- `Views/NotificationsBadgeNotchView.swift`
- `Views/NotificationsListNotchView.swift`
- `Views/NotificationDetailNotchView.swift`
- `Views/NotificationsPageNotchView.swift` (wrapper page carousel)
- `Features/Notch/EventHandlers/NotchNotificationsEventsHandler.swift`
- `Features/Settings/.../NotificationsSettingsView.swift`

**Modifier** :
- `HomePageNotchView.swift` — `case notifications` dans l'enum `HomePages` (title/subtitle/icon/tint)
  + `case .notifications:` dans `pageView(for:)`.
- `HomePageNotchContent.swift` — `.notifications` dans les `switch` de sizing.
- `NotchContentRegistry.swift` — `enum Notifications { static let badge = … }`.
- `NotchContentPriority.swift` — `case notifications` (+ defaultValue/titleKey/image/color/configurableKeys).
- `GeneralSettingsStorage.swift` — `"notifications"` dans `homePageOrder` défaut + clés (toggle, liste persistée).
- `NotchEventCoordinator.swift` — instancier VM+monitor+handler, observer publishers (show/hide badge,
  bannière), drainer l'inbox au lancement.
- `AppContainer.swift` — DI du VM/monitor.
- `SettingsRootSections.swift` — enregistrer `NotificationsSettingsView`.
- `Localizable.xcstrings` — nouvelles chaînes (en/es/ru/zh-Hans).

---

## 13. Edge cases & failure modes

- JSON malformé → `inbox/rejected/` + log, pas de crash.
- `title`/`summary` manquants → item rejeté (requis).
- `icon` SF Symbol invalide → fallback level.
- Coalescence d'une notif lue → repasse non-lue (badge +1).
- App fermée à l'arrivée → drain au lancement, pas de bannière rétroactive.
- Rafales de drops → file du `NotchEngine`.
- Badge disparaît dès `unreadCount == 0` (liste peut rester non vide, accessible via carousel).
- `inbox/` sur volume réseau / permissions : hors scope (usage local).

---

## 14. Points mineurs — TRANCHÉS

1. **JSON rejeté → déplacé vers `inbox/rejected/`** (garder pour debug), *à condition que ça ne complexifie
   pas* — c'est un simple `FileManager.moveItem` après échec du retry, donc OK. Sinon suppression + log.
2. **Un seul toggle « Notifications »** (active badge ambiant + page carousel ensemble).
3. **Badge caché dès `unreadCount == 0`**, même si des notifs lues restent dans la liste (accessible via carousel).

---

## 15. Référence d'implémentation (interfaces VÉRIFIÉES dans le code)

> Tout ce qui suit a été lu directement dans le repo au moment de la rédaction — **ne pas ré-inventer
> les signatures**. Chemins relatifs à la racine du repo.

### 15.1 — Interface d'une live activity : `NotchContentProtocol`
`DynamicNotch/Core/Protocols/NotchContentProtocol.swift` + `.../DynamicIslandCustomizable.swift`

```swift
protocol NotchContentProtocol {
    var id: String { get }
    var stackID: String { get }              // défaut = id
    var priority: Int { get }                // défaut = NotchContentPriority.default (0)
    var strokeColor: Color { get }           // défaut = .white.opacity(0.2)
    var isExpandable: Bool { get }           // défaut = false  -> mettre true pour le badge
    var expandsOnTap: Bool { get }           // défaut = isExpandable
    var windowLink: (@MainActor () -> Void)? { get } // défaut nil
    func size(baseWidth:baseHeight:) -> CGSize
    func expandedSize(baseWidth:baseHeight:) -> CGSize          // défaut = size(...)
    func cornerRadius(baseRadius:) -> (top:CGFloat, bottom:CGFloat)          // a un défaut
    func expandedCornerRadius(baseRadius:) -> (top:CGFloat, bottom:CGFloat)  // défaut = cornerRadius
    @MainActor func makeView() -> AnyView            // vue COMPACTE
    @MainActor func makeExpandedView() -> AnyView    // vue DÉPLIÉE (défaut = makeView)
}
```
Les extensions fournissent des défauts pour presque tout. **Une live activity minimale** (cf. template
`DynamicNotch/Features/Settings/Content/LanguageChangedNotchContent.swift`) n'implémente en pratique que :
`id`, `priority`, `size(...)`, `dynamicIslandSize(...)`, `makeView()`.

Pour le **badge** : conformer à `NotchContentProtocol, DynamicIslandCustomizable`, avec
`isExpandable = true`, `id = NotchContentRegistry.Notifications.badge.id`,
`priority = NotchContentRegistry.Notifications.badge.priority`, `makeView()` = badge compact,
`makeExpandedView()` = `NotificationsListNotchView`. (Voir `HomePageNotchContent.swift` pour un exemple
complet avec tailles dépliées et coins.)

### 15.2 — Commandes du notch : `NotchState`
`DynamicNotch/Core/Models/NotchState.swift`. Envoyées via `notchViewModel.send(_:)`.
```swift
enum NotchState {
    case showLiveActivity(NotchContentProtocol)
    case hideLiveActivity(id: String)
    case dismissLiveActivity(id: String)
    case showTemporaryNotification(NotchContentProtocol, duration: TimeInterval)
    case hide
}
```
- Afficher/rafraîchir le badge : `send(.showLiveActivity(NotificationsBadgeNotchContent(...)))`
- Cacher le badge (unread==0) : `send(.hideLiveActivity(id: NotchContentRegistry.Notifications.badge.id))`
- Bannière d'arrivée : `send(.showTemporaryNotification(NotificationBannerContent(item), duration: 3.0))`

### 15.3 — Badge numérique animé : `AnimatedLevelText`
`DynamicNotch/Shared/UI/Components/AnimateLevelText.swift`
```swift
AnimatedLevelText(level: viewModel.unreadCount, fontSize: 14, color: highestUnreadLevel.color)
// contentTransition(.numericText()) + snappy animation intégrés
```

### 15.4 — Watcher de dossier : `DispatchSource`
Pattern copié de `DynamicNotch/Core/Services/Timer/ClockTimerMonitor.swift` (startPreferencesMonitor, ~l.175).
Pour surveiller un **dossier** : `open(inboxPath, O_EVTONLY)` sur le dossier, puis
`DispatchSource.makeFileSystemObjectSource(fileDescriptor:eventMask:[.write], queue:)`. L'event `.write`
se déclenche à chaque ajout/suppression d'entrée. Dans le handler : ré-énumérer le dossier
(`FileManager.contentsOfDirectory`), traiter les `*.json` ne commençant pas par `.`. Toujours drainer une
fois à l'init (avant/après resume) pour les fichiers déjà présents. `source.resume()` obligatoire.

### 15.5 — Event handler + câblage dans `NotchEventCoordinator`
Modèle du handler : `DynamicNotch/Features/Notch/EventHandlers/NotchHomePageEventsHandler.swift` (petit,
`@MainActor final class`, une méthode `handle(_:)` qui appelle `notchViewModel.send(...)`).

Câblage réactif show/hide — **copier le pattern File Tray** dans `NotchEventCoordinator.swift` (~l.150) :
```swift
// fileTrayViewModel.onItemsChange = { items in ... send(.showLiveActivity/.hideLiveActivity) }
```
→ Donner au `NotificationCenterViewModel` un callback `onChange` (ou observer un `@Published`) qui, à
chaque mutation : si `unreadCount > 0` && feature activée → `send(.showLiveActivity(badge))`, sinon
`send(.hideLiveActivity(id: badge.id))`. Et sur **nouvel** item → `send(.showTemporaryNotification(...))`.

Bannière : voir `showLanguageChangedNotification` dans `NotchEventCoordinator.swift` (~l.787) :
`notchViewModel.send(.showTemporaryNotification(content, duration: 3.0))`.

Drain au lancement : `checkFirstLaunch()` (~l.195) est l'endroit où `homePageHandler.handleHomePage(.homePageOn)`
est appelé si activé — y ajouter le démarrage du monitor + drain initial de l'inbox.

### 15.6 — Persistance de la liste (JSON dans UserDefaults)
Pattern exact : `DynamicNotch/Features/DragAndDrop/Tray/FileTrayViewModel.swift`
(`persistItems()` / `restorePersistedItems()`, ~l.273) :
```swift
let data = try JSONEncoder().encode(storedItems)      // [NotificationItem] Codable
defaults.set(data, forKey: Self.persistedItemsKey)
// restore: defaults.data(forKey:) -> JSONDecoder().decode([NotificationItem].self, from: data)
```

### 15.7 — Réglages
- `SettingsStoreBase` (`.../Stores/SettingsStoreBase.swift`) fournit `persist(_:for:)` surchargé pour
  `Bool/Int/Double/String/[String:Int]/[String]`. Nouveau store `NotificationsSettingsStore: SettingsStoreBase`
  avec `@Published var isEnabled { didSet { persist(...) } }` (cf. `HomePageSettingsStore.swift`).
- `GeneralSettingsStorage.swift` : `enum Keys` (l.~125) — ajouter `notificationsEnabled`, `notificationsList`.
  `defaultValues` (l.137) — l.274 : ajouter `"notifications"` à
  `Keys.homePageOrder: ["camera","localTimer","vpn","systemStats"]` → `[..., "notifications"]`.
- Enum des pages : `HomePages` dans `DynamicNotch/Features/HomePage/Views/HomePageNotchView.swift` —
  ajouter `case notifications` + `title`/`subtitle`/`icon`/`tint`, et `case .notifications:` dans
  `pageView(for:)`. Ajouter aussi `.notifications` aux `switch` de sizing de
  `HomePage/Content/HomePageNotchContent.swift`.
- `HomePageSettingsStore.swift` gère automatiquement le nouveau case (tableau `[HomePages]`).

### 15.8 — Priorité : `NotchContentPriority.swift`
Rappel : **nombre haut = priorité haute**. `homePage = -10000` (le plus bas), défauts réels 0–9,
`configurableKeys` = liste éditable dans Réglages > Priorités. À ajouter :
```swift
// dans enum Key: case notifications
// var defaultValue: case .notifications: NotchContentPriority.notifications
// static let notifications = 0   // tier repos, peer de VPN, > homePage
// + titleKey / image ("bell.fill") / color, et l'ajouter à configurableKeys
```
Et dans `NotchContentRegistry.swift` :
```swift
enum Notifications {
    static let badge = NotchContentDescriptor(id: "notifications.badge", priorityKey: .notifications)
}
```

### 15.9 — Injection de dépendances : `AppContainer.swift`
Les VMs sont créés là (`homePageViewModel = HomePageViewModel()` l.14) puis passés à
`NotchEventCoordinator(...)` (l.45). Ajouter `let notificationCenterViewModel = NotificationCenterViewModel()`
(+ le monitor) et le passer au coordinator (dont il faudra étendre l'init + stocker le handler, comme les autres).

### 15.10 — Localisation
`DynamicNotch/Resources/Localization/Localizable.xcstrings` (JSON, langues en/es/ru/zh-Hans).
Ajouter les libellés statiques (« Notifications », sous-titre, « Read »/« Done »/« Close »/« Vider »…).
**⚠️ Le contenu runtime des scripts n'y va PAS** — rendu en `Text(verbatim:)` (voir §9).

---

## 16. Ordre d'implémentation suggéré (TDD)

1. **Modèle + coalescence (testable pur, sans UI)** : `NotificationItem` (Codable), `NotificationLevel`
   (couleur/icône), `NotificationPayload` (Decodable). `NotificationCenterViewModel` : `add(payload:)`
   (coalescence par `source`, sans-source=append, replace→unread), `markRead/done/clearAll`, `unreadCount`,
   `highestUnreadLevel`, persistance. → **tests unitaires** sur toute la table §4 + coalescence §5.
2. **Monitor inbox** : `NotificationInboxMonitor` (DispatchSource + drain + parse atomique + delete +
   rejected/). Test : déposer des fichiers, vérifier ingestion + suppression + rejet du malformé.
3. **Badge (live activity compacte)** : `NotchContentRegistry.Notifications` + `NotchContentPriority.notifications`
   + `NotificationsBadgeNotchContent` + `NotificationsBadgeNotchView` (cloche + `AnimatedLevelText`, couleur sévérité).
4. **Vue liste → détail** : `NotificationsListNotchView` (pattern `TrayExpandedActiveNotchView`) +
   `NotificationDetailNotchView` (3 boutons). `Text(verbatim:)` pour title/summary/source.
5. **Page carousel** : `case notifications` dans `HomePages` + `NotificationsPageNotchView` (wrap la liste)
   + sizing dans `HomePageNotchContent` + `"notifications"` dans `homePageOrder` défaut.
6. **Câblage** : `NotchNotificationsEventsHandler` + observations dans `NotchEventCoordinator`
   (show/hide badge, bannière à l'arrivée) + drain au lancement dans `checkFirstLaunch` + DI dans `AppContainer`.
7. **Réglages** : `NotificationsSettingsStore` (toggle) + `NotificationsSettingsView` (toggle, « Révéler
   l'inbox », « Vider ») + enregistrement dans `SettingsRootSections`.
8. **Localisation** : chaînes statiques dans `Localizable.xcstrings`.

## 17. Fichiers de référence à lire avant de coder (patterns à copier)

| Besoin | Fichier de référence |
|--------|----------------------|
| Live activity compacte minimale | `Features/Settings/Content/LanguageChangedNotchContent.swift` |
| Live activity Home + sizing/coins | `Features/HomePage/Content/HomePageNotchContent.swift` |
| Page carousel + boutons | `Features/VPN/Views/VpnPageNotchView.swift` |
| Liste scrollable + actions par ligne | `Features/DragAndDrop/Tray/Views/TrayExpandedActiveNotchView.swift` |
| Persistance liste JSON/UserDefaults | `Features/DragAndDrop/Tray/FileTrayViewModel.swift` |
| Watcher de fichier `DispatchSource` | `Core/Services/Timer/ClockTimerMonitor.swift` (l.175) |
| Câblage show/hide réactif | `Features/Notch/NotchEventCoordinator.swift` (l.150, l.787) |
| Event handler | `Features/Notch/EventHandlers/NotchHomePageEventsHandler.swift` |
| Store de réglages | `Features/Settings/Shared/Stores/HomePageSettingsStore.swift` |
| Badge numérique animé | `Shared/UI/Components/AnimateLevelText.swift` |
