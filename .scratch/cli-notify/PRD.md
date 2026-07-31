# PRD — CLI `dynamicnotch notify`

Status: ready-for-agent

> Source de vérité : `docs/cli-notify-feature-spec.md` (design figé, issu d'une session de grilling).
> Ce PRD en est la traduction problème/solution/stories/décisions. En cas de divergence sur une
> signature vérifiée, le spec fait foi ; ce PRD fait foi pour le périmètre et les critères de succès.

---

## Problem Statement

Le seul canal externe pour pousser une notification dans DynamicNotch est le dépôt d'un fichier JSON
dans le dossier `inbox`. Il fonctionne mais impose à chaque appelant le même boilerplate fragile :
connaître le chemin de l'inbox, construire un JSON valide (échapper guillemets, retours-ligne, unicode),
et écrire de façon atomique (temp + `mv`). Un `title` contenant `"` ou `\n` casse un `printf` naïf ; le
one-liner documenté à nom de fichier fixe (`drop.json`) perd des notifications sous rafale ; et rien de
tout cela n'est réutilisable hors d'un shell. Je veux un moyen **fiable et trivial** de notifier depuis
n'importe quel process (script, cron, CI, Raccourcis via action shell), sans réécrire ce boilerplate.

## Solution

Un **binaire en ligne de commande `dynamicnotch`** livré avec l'app, exposant une sous-commande
`notify`. Il prend des flags (`--title`, `--summary`, `--level`, `--source`, `--icon`), construit un
`NotificationPayload` valide via `JSONEncoder`, et le **dépose atomiquement dans l'inbox** (temp
`.`-préfixé + `rename`, nom final `<uuid>.json` unique). Le `summary` peut venir du flag **ou de stdin**
(pipe de la sortie d'un job). Le CLI n'ouvre **aucun nouveau canal** : il écrit dans l'inbox existante,
donc il marche même **app fermée** (drain au prochain lancement).

Le contrat de fil (`NotificationPayload`, cœur `NotificationLevel`), la dérivation du chemin d'inbox et
le mécanisme de drop atomique sont extraits dans un **Swift Package local `NotificationContract`**
partagé par l'app et le CLI — **une seule définition**, zéro dérive. La présentation (couleur, icône) et
`NotificationItem` restent dans l'app.

Le binaire est **embarqué dans le `.app`** ; un bouton **« Installer l'outil CLI »** dans Réglages crée
un symlink `/usr/local/bin/dynamicnotch` (escalade admin si besoin, idempotent) pointant dans le bundle.

**Invariant central :** le succès du CLI = « fichier valide déposé atomiquement dans l'inbox ». Pas
d'accusé de réception/affichage — l'app reste seule maître de l'ingestion et du rendu.

## User Stories

1. En tant qu'auteur de script, je veux notifier avec `dynamicnotch notify --title … --summary …`, afin
   de ne plus écrire à la main le chemin d'inbox, le JSON, ni l'écriture atomique.
2. En tant qu'auteur de script, je veux passer un `summary` multi-ligne sans casser le JSON, afin
   qu'un titre/corps avec guillemets, `\n` ou « 50% done » s'encode correctement.
3. En tant qu'auteur de script, je veux pouvoir **piper** la sortie d'un job (`job | dynamicnotch notify
   --title …`), afin d'attacher son output comme `summary` sans passer par `$(…)`.
4. En tant qu'auteur de script, je veux qualifier `--level` (`info`/`success`/`warning`/`error`), et
   qu'une valeur inconnue **échoue immédiatement**, afin d'éviter un downgrade silencieux en `info`.
5. En tant qu'auteur de script, je veux `--source` et `--icon` optionnels, afin de coalescer par source
   et personnaliser l'icône, exactement comme le contrat file-drop.
6. En tant qu'auteur de script, je veux que `--title` et `--summary` (ou stdin) soient **requis**, afin
   qu'un appel incomplet échoue au lieu de produire une notif inaffichable.
7. En tant qu'auteur de script, je veux un code de sortie fiable (`0` = déposé, `≠ 0` = erreur d'arguments
   ou d'écriture), afin de chaîner le CLI dans mes scripts.
8. En tant qu'auteur de script, je veux que deux notifications rapprochées ne se **collisionnent** jamais
   (nom de fichier unique), afin qu'une rafale n'en perde aucune.
9. En tant qu'auteur de script, je veux pouvoir notifier même si l'app **n'a jamais été lancée** (le CLI
   crée l'inbox), afin que le tout premier drop soit drainé au lancement suivant.
10. En tant qu'utilisateur, je veux un bouton **« Installer l'outil CLI »** dans Réglages, afin d'avoir
    `dynamicnotch` sur mon `PATH` sans éditer mon `.zshrc` ni chercher le binaire dans le bundle.
11. En tant qu'utilisateur, je veux que ré-appuyer sur ce bouton soit **sans danger** (idempotent) et
    répare un symlink périmé, afin de réinstaller après une mise à jour ou un déplacement de l'app.
12. En tant que testeur/power-user, je veux surcharger le dossier d'inbox via `DYNAMICNOTCH_INBOX`, afin
    de tester le CLI de bout en bout ou de viser un emplacement custom.
13. En tant que développeur du repo, je veux **une seule** définition du contrat de fil et du mécanisme
    de drop (module partagé), afin que CLI et app ne puissent pas diverger.
14. En tant qu'utilisateur international, je veux les libellés du bouton d'installation **localisés**
    (en/es/ru/zh-Hans), afin d'utiliser Réglages dans ma langue. (Le CLI, lui, reste anglais-only.)

## Implementation Decisions

Voir `docs/cli-notify-feature-spec.md` §1–§5 pour la table complète. Points structurants :

- **Transport = inbox** (couche fine, app-fermée OK, zéro IPC). Pas d'URL scheme, pas de XPC.
- **Module SPM local `NotificationContract`** (Foundation pur, zéro dépendance) : possède
  `NotificationPayload` (`Codable`), cœur `NotificationLevel`, helper chemin (`NotificationInbox`,
  honore `$DYNAMICNOTCH_INBOX`), mécanisme de drop atomique (`AtomicInboxDrop`, temp `.`-préfixé +
  `rename`, nom `<uuid>.json`). Présentation + `NotificationItem` restent app-side.
- **CLI target** : `swift-argument-parser`, sous-commande `notify`, `--level` strict, `summary` via flag
  ou stdin, logique testable extraite (URL d'inbox injectée), `main()` = glue non testée.
- **Distribution** : binaire embarqué (build phase) + bouton Réglages « Installer l'outil CLI » →
  symlink `/usr/local/bin` + escalade admin `osascript` + idempotence.
- **Correction atomicité** : nom final UUID (anti-collision) ; temp dans l'inbox (atomicité cross-volume).
  `CodingKeys` accessible à l'`Encodable` synthétisé.

## Testing Decisions

- **Seam 1 (module)** : round-trip `NotificationPayload` encode→decode ; `level` inconnu → `info` ;
  `title`/`summary` blanc → throw ; `NotificationInbox.resolvedURL` honore l'env.
- **Seam 2 (CLI → pipeline réel, roi)** : cœur du CLI dépose dans une inbox temp (`$DYNAMICNOTCH_INBOX`)
  → le **vrai `NotificationInboxMonitor`** l'ingère → payload via `onPayload`. Vérifie aussi : nom final
  sans `.` et unique ; `summary` stdin ; `--level` invalide → exit ≠ 0 + aucun fichier ; inbox créée si
  absente. Prior art : `NotificationInboxMonitorIntegrationTests`.
- **Hors test** : `main()` du CLI et code UI du bouton (symlink/osascript), glue assumée.

## Out of Scope

- **Accusé de réception/affichage** (canal synchrone) : écarté ; succès = fichier déposé.
- **URL scheme / XPC / socket** : écartés (tous les appelants sont lançables en process).
- **Alias court `dn`** : non imposé (risque de collision ; l'utilisateur peut aliaser côté `.zshrc`).
- **Plafond de taille du stdin** : pas de plafond (cohérent avec le PRD Notifications).
- **Formule Homebrew / tap** : sur-dimensionné pour un usage perso ; bouton Réglages suffit.
- **Localisation du CLI** : dev-facing, anglais-only. Seuls les libellés du bouton Réglages sont localisés.

## Further Notes

- **Une seule voie d'entrée** : le CLI n'est qu'un générateur de drop atomique au-dessus de l'inbox ;
  toute logique d'ingestion/rendu reste dans l'app (déjà spécifiée et testée).
- **Le CLI corrige le one-liner** : le README documente aujourd'hui un `mv drop.json` à nom fixe,
  vulnérable aux collisions de rafale — le CLI (nom UUID) devient la voie recommandée, le file-drop brut
  reste documenté comme couche bas-niveau.
- **Zéro dérive, étendue au mécanisme d'écriture** : on partage le contrat de données ET le drop
  atomique, pour la même raison — deux implémentations divergeraient.
- **Ordre suggéré** : (1) module + tests seam 1 ; (2) CLI + tests seam 2 ; (3) bouton install ; (4) docs.
