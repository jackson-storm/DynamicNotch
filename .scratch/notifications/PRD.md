# PRD — Live Activity « Notifications »

Status: ready-for-agent

> Source de vérité : `docs/notifications-feature-spec.md` (design figé, issu d'une session de grilling).
> Ce PRD en est la traduction en problème/solution/stories/décisions. En cas de divergence sur un
> détail d'implémentation vérifié, le spec fait foi pour les signatures ; ce PRD fait foi pour le
> périmètre et les critères de succès.

---

## Problem Statement

En tant qu'utilisateur de DynamicNotch, mes scripts (backups, CI, tâches cron, jobs longs) terminent
sans que je le sache. Je n'ai aucun canal ambiant, discret et durable pour qu'un process local me
pousse un résumé court : les notifications système volent le focus, disparaissent, ne s'agrègent pas
par source, et ne survivent pas au fait que l'app était fermée. Je veux voir « il s'est passé quelque
chose » d'un coup d'œil sur le notch, sans être interrompu, et pouvoir consulter le détail quand je le
décide — pas quand la notification l'impose.

## Solution

Une **5e page Home « Notifications »** dans le carousel, doublée d'un **badge ambiant** (une live
activity compacte dédiée) qui s'affiche sur le notch au repos dès qu'il existe des notifications
non-lues. Des scripts externes déposent un fichier JSON dans un **dossier `inbox` surveillé** ; l'app
le lit, l'ingère, le supprime, affiche une **bannière transitoire (~3 s)** à l'arrivée, puis retombe
sur le badge ambiant. Le badge porte une **cloche + un compteur** teinté par la **plus haute sévérité
non-lue** ; un clic déplie la **liste**, chaque ligne ouvre un **détail** avec trois actions
**Read / Done / Close**. Les notifications sont **coalescées par `source`** (un nouveau drop d'une
source connue écrase et remonte l'existant), persistées entre lancements, et purgeables via un unique
bouton **« Vider »**. Un seul toggle « Notifications » active l'ensemble.

**Invariant central :** `badge = nombre de notifications non-lues encore présentes dans la liste`
(jamais de compteur fantôme, jamais > nombre d'items).

## User Stories

1. En tant qu'utilisateur, je veux qu'un script local me pousse une notification en déposant un simple
   fichier JSON, afin de notifier l'app sans dépendance ni API à intégrer.
2. En tant qu'utilisateur, je veux fournir un `title` et un `summary` multi-ligne, afin de transmettre
   un résumé lisible de ce qui s'est passé.
3. En tant qu'utilisateur, je veux qualifier une notification par un `level` (`info`/`success`/`warning`/`error`),
   afin que sa couleur et son icône reflètent sa gravité.
4. En tant qu'utilisateur, je veux attacher un `source` à ma notification, afin de la regrouper
   logiquement avec les autres notifications du même script.
5. En tant qu'utilisateur, je veux fournir une icône SF Symbol optionnelle, afin de personnaliser
   l'apparence, avec repli automatique sur l'icône du `level` si le symbole est invalide.
6. En tant qu'utilisateur, je veux qu'un `level` absent soit traité comme `info`, afin que le champ
   reste optionnel pour les scripts simples.
7. En tant qu'utilisateur, je veux voir un badge ambiant (cloche + compteur) sur le notch au repos dès
   qu'il existe au moins une non-lue, afin de savoir qu'il s'est passé quelque chose sans ouvrir le carousel.
8. En tant qu'utilisateur, je veux que la couleur du badge soit celle de la plus haute sévérité non-lue,
   afin de jauger l'urgence d'un coup d'œil.
9. En tant qu'utilisateur, je veux qu'à chaque nouvelle notification (app active) une bannière
   transitoire (~3 s) affiche title+summary teintée par le `level`, afin de ne jamais rater un push.
10. En tant qu'utilisateur, je veux qu'un clic sur le badge déplie la liste, afin d'accéder aux détails
    directement depuis le notch.
11. En tant qu'utilisateur, je veux ouvrir la liste aussi via la page carousel « Notifications », afin
    d'y accéder même quand le badge est caché.
12. En tant qu'utilisateur, je veux que le badge et la page pointent vers la même liste et le même état,
    afin d'avoir une source de vérité unique.
13. En tant qu'utilisateur, je veux voir dans la liste, par ligne, la couleur du `level`, le `title`,
    le `source`, l'heure et un indicateur « non-lu », afin de trier visuellement.
14. En tant qu'utilisateur, je veux qu'ouvrir une notification (tap) n'affecte AUCUN état (ni lu ni
    présence), afin que la consultation reste sans effet de bord.
15. En tant qu'utilisateur, je veux un bouton **Read** qui marque la notification lue tout en la
    gardant dans la liste, afin de baisser le compteur sans perdre l'historique.
16. En tant qu'utilisateur, je veux un bouton **Done** qui retire la notification de la liste, afin de
    la traiter définitivement (et de décrémenter le badge si elle était non-lue).
17. En tant qu'utilisateur, je veux un bouton **Close** qui referme le détail sans rien changer, afin
    de revenir à la liste en laissant la notification non-lue si elle l'était.
18. En tant qu'utilisateur, je veux un bouton **« Vider »** dans l'en-tête de la liste, afin de tout
    supprimer d'un coup (liste vide, badge à 0).
19. En tant qu'utilisateur, je veux qu'un nouveau drop d'une `source` déjà présente **remplace** le
    contenu de l'item existant, le repasse non-lu, mette à jour l'heure et le remonte en tête, afin
    qu'une source bavarde ne pollue pas la liste avec des doublons.
20. En tant qu'utilisateur, je veux qu'une notification lue redevienne non-lue lorsqu'un nouveau drop
    de sa `source` arrive (badge +1), afin d'être re-notifié d'une évolution.
21. En tant qu'utilisateur, je veux qu'une notification **sans `source`** soit toujours ajoutée
    (append), jamais fusionnée, afin que les notifications anonymes ne s'écrasent pas entre elles.
22. En tant qu'utilisateur, je veux que le badge disparaisse dès que `unreadCount == 0`, même si des
    notifications lues restent dans la liste, afin que le notch au repos ne montre rien quand il n'y a
    rien de nouveau (la liste reste accessible via le carousel).
23. En tant qu'utilisateur, je veux que mes notifications survivent au redémarrage de l'app, afin de ne
    rien perdre entre deux sessions.
24. En tant qu'utilisateur, je veux que les fichiers déposés pendant que l'app était fermée soient
    ingérés au lancement (drain), afin de ne rien manquer en son absence.
25. En tant qu'utilisateur, je veux qu'aucune bannière rétroactive ne s'affiche pour les drops arrivés
    app fermée, afin de ne pas être submergé au démarrage — juste le badge à jour.
26. En tant qu'utilisateur, je veux qu'une rafale de drops soit absorbée sans collision, afin que
    l'affichage reste cohérent sous charge.
27. En tant qu'utilisateur, je veux que le contenu fourni par mes scripts s'affiche verbatim (jamais
    interprété comme clé de localisation), afin qu'un titre comme « 50% done » s'affiche tel quel.
28. En tant qu'utilisateur, je veux un unique toggle « Notifications » qui active à la fois le badge
    ambiant et la page carousel, afin de tout contrôler d'un seul interrupteur.
29. En tant qu'utilisateur, je veux que la page « Notifications » participe à l'ordre et à
    l'activation/désactivation des pages Home comme les quatre autres, afin de la ranger où je veux.
30. En tant qu'utilisateur, je veux régler la priorité du badge dans Réglages > Priorités, afin
    d'arbitrer sa cohabitation avec les autres live activities.
31. En tant qu'utilisateur, je veux un bouton « Révéler l'inbox dans le Finder » dans les réglages,
    afin de retrouver facilement le dossier où déposer mes fichiers.
32. En tant qu'utilisateur, je veux un bouton « Vider » également accessible depuis les réglages, afin
    de purger sans ouvrir le notch.
33. En tant qu'auteur de script, je veux un one-liner de référence documenté qui écrit de façon
    **atomique** (temp + `mv`), afin d'éviter que le watcher lise un fichier à moitié écrit.
34. En tant qu'utilisateur, je veux qu'un JSON malformé ne fasse jamais crasher l'app mais soit isolé
    (déplacé vers `inbox/rejected/`) et loggué, afin que la robustesse prime sur la perte silencieuse.
35. En tant qu'utilisateur, je veux qu'une notification sans `title` ou sans `summary` soit rejetée,
    afin de garantir que chaque entrée de liste soit affichable.
36. En tant qu'utilisateur, je veux que les libellés statiques de l'UI (« Read », « Done », « Close »,
    « Vider », titre de la page…) soient localisés (en/es/ru/zh-Hans), afin d'utiliser l'app dans ma langue.

## Implementation Decisions

**Architecture générale.** Un **ViewModel partagé unique** (`NotificationCenterViewModel`) détient la
liste, l'état lu/non-lu par item, le compteur de non-lues, la plus haute sévérité non-lue, la décision
de visibilité du badge, et les actions de mutation (add/coalesce, markRead, markDone, clearAll). Un
**monitor** (`NotificationInboxMonitor`) surveille le dossier inbox et pousse chaque nouvelle charge
utile (payload) dans le VM. Les deux surfaces d'affichage (badge ambiant et page carousel) rendent la
même vue liste→détail alimentée par ce VM unique.

**Frontière de décision (au plus haut seam).** Toute la logique décisionnelle vit **dans le VM**, pas
dans le coordinateur d'événements :
- Le VM expose des propriétés observables : liste d'items, `unreadCount`, plus-haute-sévérité-non-lue,
  et un booléen de visibilité du badge (vrai ssi `unreadCount > 0` **et** feature activée).
- Le VM notifie ses mutations via un callback/`@Published` que le coordinateur observe.
- Le coordinateur (`NotchNotificationsEventsHandler` + câblage dans le coordinateur d'événements du
  notch) se limite à relayer : sur changement, `show`/`hide` de la live activity badge selon le booléen
  du VM ; sur **nouvel** item (app active), déclencher la bannière transitoire. C'est de la glue mince,
  assumée non testée.

**Ingestion (monitor).**
- Dossier surveillé : `inbox` sous le répertoire Application Support de l'app (créé au démarrage s'il
  est absent). App **non sandboxée** → accès fichier libre, pas d'app group.
- Watcher basé sur `DispatchSource` (même famille que le watcher de dossier existant du feature Timer),
  déclenché sur écriture du répertoire ; le handler ré-énumère le dossier et traite les `*.json` **ne
  commençant pas par `.`** (les fichiers temporaires en cours d'écriture, préfixés `.`, sont ignorés).
- **Drain au lancement** : à l'init, énumérer et consommer tous les `.json` déjà présents (couvre les
  drops arrivés app fermée), avant/après `resume` du watcher.
- Cycle par fichier : parse → succès → l'app stampe les champs internes (`id`, `receivedAt`, `read=false`)
  puis pousse le payload dans le VM → **supprime** le fichier.
- Échec de parse → **retry-in-place** après un court délai (défaut ~200 ms) — filet contre les écritures
  non atomiques ; si l'échec persiste → **déplacer vers `inbox/rejected/`** + log, **jamais crasher**.
  Le délai de retry est **injectable** (paramètre du monitor) pour la testabilité.
- **Frontière de confiance** : n'importe quel process local peut écrire dans l'inbox. Accepté pour un
  usage personnel (scripts de l'utilisateur).

**Schéma JSON (contrat scripts → app).** Ce que le script écrit :

```json
{
  "title":   "Backup nightly",               // requis, court
  "summary": "42 fichiers, 1.2 GB\nOK",       // requis, multi-ligne
  "level":   "success",                       // opt: info|success|warning|error (défaut info)
  "source":  "backup.sh",                     // opt: clé de coalescence + sous-titre
  "icon":    "externaldrive.badge.checkmark"  // opt: nom SF Symbol (fallback si invalide)
}
```

Ajoutés par l'app à la réception : `id` (UUID), `receivedAt` (timestamp), `read` (bool, défaut `false`).
`title`/`summary` **requis** → l'absence de l'un rejette l'item ; ce rejet tombe **au parse** (côté
monitor), pas dans le VM. Mapping `level` → couleur/icône par défaut : `info`→neutre/`bell.fill`,
`success`→vert/`checkmark.circle.fill`, `warning`→orange/`exclamationmark.triangle.fill`,
`error`→rouge/`xmark.octagon.fill`. Une `icon` custom est validée via l'API SF Symbol ; invalide →
fallback sur l'icône du `level`.

**Sémantique Read / Done / Close.** Table de vérité (issue du grilling, encode la décision) :

| Action | Présence liste | Flag read | Effet badge |
|--------|----------------|-----------|-------------|
| **Read** | reste | → lu | −1 (si était non-lu) |
| **Done** | retirée | (n/a) | −1 (si était non-lu) |
| **Close** | reste (ferme le détail) | inchangé | inchangé |
| Ouvrir (tap) | reste | inchangé | inchangé |
| Vider | tout supprimé | (n/a) | → 0 |

Scénario de contrôle (2 non-lues A, B) : `Read A → [A(lu), B]` badge 2→1 ; `Done A → [B]` badge 2→1 ;
`Close A → [A, B]` badge 2→2 (A toujours non-lu).

**Coalescence.** Clé = `source`. Drop d'une `source` existante → **remplace** le contenu, **repasse
non-lu** (`read=false`, badge +1 s'il était lu), met à jour `receivedAt`, **remonte en tête**. Drop
sans `source` → **append** (unique, jamais fusionné). **Pas de plafond** de rétention ; seul le
« Vider » manuel réinitialise.

**Badge ambiant (live activity compacte).** Nouveau descripteur de contenu enregistré dans le registre
des live activities (id `notifications.badge`, clé de priorité `.notifications`). Vue **compacte** =
cloche + compteur numérique animé (réutilise le composant de compteur animé du File Tray), teinte =
plus haute sévérité non-lue. Vue **dépliée** = la vue liste→détail. Nouveau `case notifications` dans
l'énumération de priorité, `defaultValue` au **tier repos** (≈ 0, pair de VPN, au-dessus de la page
Home), ajouté aux clés configurables (titre/icône `bell.fill`/couleur à fournir).

**Bannière à l'arrivée.** À chaque nouvel item (app active), afficher une notification transitoire
(~3 s) via le mécanisme de toast existant (même que le toast « langue changée »), petite vue
title+summary teintée par `level`. App fermée à l'arrivée → pas de bannière, juste le badge au
prochain lancement. Les rafales sont sérialisées par la file d'événements existante du moteur du notch.

**UX liste → détail (2 niveaux).** **Niveau 1 (liste)** : `ScrollView` + `ForEach` (pattern de la liste
scrollable du File Tray), hauteur max ~120 + masque de fondu ; ligne = barre/point couleur `level`,
`title`, `source` + heure, point « non-lu » ; en-tête = titre + bouton « Vider ». Réutilisée par le
badge-déplié ET la page carousel. **Niveau 2 (détail)** : `summary` complet multi-ligne, `title`,
`source`, heure, icône ; trois boutons Read / Done / Close (style de bouton primaire du repo).
**Contenu runtime des scripts rendu en `Text(verbatim:)`** (idiome du repo) — jamais interprété comme
clé de localisation ; seuls les libellés statiques passent par la localisation.

**Page carousel.** Nouveau `case notifications` dans l'énumération des pages Home (title/subtitle/icon/
tint), branché dans la fabrique de vue de page et dans les `switch` de sizing du contenu Home. Ajout de
`"notifications"` à l'ordre des pages par défaut et à la persistance des pages activées.

**Persistance.** Liste sérialisée en **JSON dans UserDefaults** (pattern `persistItems`/`restore` du
File Tray). Restaurée à l'init du VM ; badge recalculé depuis `unreadCount`. Tous les champs persistés
(`receivedAt`, `read`, `level`, `source`, `icon`).

**Réglages.** Nouveau store de réglages (`SettingsStoreBase`) avec un `isEnabled` (unique toggle
« Notifications » pilotant badge + page ensemble). Nouvel écran dédié : toggle + « Révéler l'inbox dans
le Finder » + « Vider », enregistré dans les sections de réglages. Nouvelles clés de stockage
(`notificationsEnabled`, liste persistée). Ligne de priorité auto-affichée via les clés configurables.

**Injection de dépendances.** Le VM et le monitor sont créés dans le conteneur d'app et passés au
coordinateur d'événements du notch (init étendu, handler stocké comme les autres). Le drain initial de
l'inbox et le démarrage du monitor sont branchés au point de première-activation existant.

**Localisation.** Nouvelles chaînes statiques (« Notifications » + sous-titre, « Read »/« Done »/
« Close »/« Vider », libellés réglages) dans le catalogue de localisation (en/es/ru/zh-Hans). Le
contenu runtime des scripts n'y va **pas**.

## Testing Decisions

**Ce qui fait un bon test ici.** On teste le **comportement externe** observable aux frontières
(API publique du VM ; effets de fichiers du monitor), jamais les détails d'implémentation privés. Les
tests calquent le pattern d'intégration éprouvé de la feature **Download** (déjà dans le repo).

**Deux seams, au plus haut possible (confirmé avec l'utilisateur).**

**Seam 1 — `NotificationCenterViewModel` (logique métier pure, sans filesystem ni UI).**
Le VM prend ses dépendances par injection : un `UserDefaults` isolé (suite dédiée par test) pour la
persistance, et le monitor via un protocole (`NotificationInboxMonitoring`, sur le modèle de
`DownloadMonitoring`) doublé par un `FakeNotificationInboxMonitor` à ajouter aux test doubles partagés
(méthode `publish(_ payload:)` invoquant le callback). Couverture :
- **Toute la table Read/Done/Close** (§ ci-dessus) : Read garde+marque lu+décrémente ; Done retire+
  décrémente si non-lu ; Close ne touche rien ; tap ne touche rien ; Vider → liste vide + badge 0.
- **Coalescence** : source existante remplace+remonte+repasse non-lu (badge +1 si l'item était lu) ;
  sans-source = append jamais fusionné ; `receivedAt` mis à jour.
- `unreadCount` et **plus-haute-sévérité-non-lue** (error>warning>success>info) sur listes mixtes.
- **Visibilité du badge** : vrai ssi `unreadCount > 0` **et** feature activée ; badge caché dès
  `unreadCount == 0` même liste non vide.
- **Persistance round-trip** : muter le VM → instancier un nouveau VM sur le même `UserDefaults` isolé
  → la liste et le badge sont restaurés à l'identique.

**Seam 2 — `NotificationInboxMonitor` (intégration filesystem réelle).**
Le monitor prend son **répertoire inbox par injection** (sur le modèle de
`FolderFileDownloadMonitor(monitoredDirectories:)`) et son **délai de retry par injection** (≈0 en
test pour rester rapide/déterministe). Test dans un dossier temporaire jetable, assertions via le
callback d'items :
- Dépôt d'un `.json` valide → payload ingéré **et fichier supprimé**.
- JSON malformé → après retry, fichier **déplacé vers `inbox/rejected/`**, pas de crash, aucun item émis.
- `title`/`summary` manquant → item rejeté (validation au parse).
- Fichiers `.` (temp) et non-`.json` → ignorés du scan.
- **Drain au lancement** : fichiers déjà présents à l'init → consommés.

**Ce qui reste hors test (assumé).** Le câblage du coordinateur d'événements (relais show/hide badge +
bannière) est de la glue mince : sa logique décisionnelle a été **poussée dans le VM** (Seam 1)
précisément pour ne pas laisser de logique non testée dans le coordinateur. Le rendu SwiftUI (vues
badge/liste/détail) n'est pas testé unitairement (pas de prior-art de snapshot testing dans le repo).

**Prior art dans le repo.**
- Monitor sur dossier temp : les tests d'intégration du monitor de téléchargements (dépose des
  fichiers dans un temp dir, asserte l'ingestion via callback) — modèle direct du Seam 2.
- VM avec monitor injecté + fake publiant des snapshots : les tests du view model de téléchargements —
  modèle direct du Seam 1 (injection + fake dans les test doubles partagés).
- Persistance UserDefaults injectée : le view model du File Tray injecte `UserDefaults`. **Nuance
  honnête** : il n'existe pas de test unitaire du File Tray dans le repo — on s'appuie sur le *pattern
  d'injection* qu'il fournit, pas sur un test existant à copier. Le round-trip de persistance est donc
  du test neuf, bâti sur ce pattern.

## Out of Scope

- **Plafond de rétention / éviction automatique.** Choix assumé : pas de plafond. Les notifications
  **sans `source`** peuvent s'accumuler indéfiniment ; le « Vider » manuel est le seul reset. (À
  rouvrir si l'accumulation devient réelle en pratique — voir Further Notes.)
- **« Tout marquer lu ».** Non retenu ; « Vider » suffit.
- **Ouvrir = marquer lu.** Explicitement écarté : ouvrir ne change aucun état ; seul Read marque lu.
- **Bannière rétroactive** pour les drops arrivés app fermée : pas de bannière, seulement le badge au
  drain.
- **Durcissement de la frontière de confiance** de l'inbox (auth/signature des drops) : usage personnel,
  tout process local peut écrire — accepté.
- **Inbox sur volume réseau / permissions particulières** : hors scope (usage local).
- **Snapshot/UI testing** des vues badge/liste/détail : pas de prior-art, non couvert.
- **Test d'intégration du coordinateur d'événements** (3e seam) : écarté avec l'utilisateur au profit
  de la logique poussée dans le VM.

## Further Notes

- **Deux points d'entrée, une seule liste/état** : badge ambiant et page carousel partagent le même
  `NotificationCenterViewModel`. C'est la décision structurante — toute divergence d'état est un bug.
- **Ambiant best-effort** : le badge vit au tier repos et peut être couvert par des live activities plus
  prioritaires ; la **bannière** est le garant qu'on ne rate jamais un push. La priorité est
  configurable (Réglages > Priorités).
- **Écriture atomique obligatoire côté script** : documenter le one-liner de référence (temp + `mv`).
  Écrire directement dans le `.json` final expose à un parse partiel (race classique du drop-folder,
  type Maildir tmp→rename) → notif perdue. Le filet retry-in-place limite la casse mais ne remplace pas
  l'atomicité.
- **UserDefaults ≠ store idéal pour gros blobs** : combiné à l'absence de plafond, si l'accumulation des
  sans-source devient réelle, rouvrir la question (plafond, ou store fichier dédié).
- **`Text(verbatim:)` non négociable** pour le contenu runtime : un `title` comme « 50% done » ou qui
  collisionne avec une clé de traduction s'afficherait mal en `Text(_:)`.
- **Ordre d'implémentation suggéré (TDD, cf. spec §16)** : (1) modèles + VM (coalescence, read/done/close,
  persistance) **avec tests Seam 1** ; (2) monitor **avec tests Seam 2** ; (3) badge live activity ;
  (4) vues liste→détail ; (5) page carousel ; (6) câblage coordinateur + drain + DI ; (7) réglages ;
  (8) localisation.
- Le spec `docs/notifications-feature-spec.md` contient les **signatures vérifiées** (protocoles,
  `NotchState`, composants réutilisés) et les **fichiers de référence à copier** — s'y reporter avant
  de coder plutôt que de réinventer les interfaces.
