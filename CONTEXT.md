# DynamicNotch

Une app macOS qui s'intègre au notch physique du MacBook. Ce glossaire fixe le vocabulaire
du domaine « notifications » : le canal par lequel des process externes poussent des résumés
ambiants et durables sur le notch, sans voler le focus.

## Language

### Notifications

**Notification**:
Une notification **de DynamicNotch** : l'entité que l'app ingère, garde en liste et affiche
sur le notch. C'est le système de notification de l'application elle-même.
_Avoid_: « alert », « item » seul, et surtout « notification » employé pour la notif système.

**Native notification**:
La notification **système macOS** (Centre de notifications), qu'on **oppose** délibérément :
elle vole le focus, disparaît, ne s'agrège pas par source, ne survit pas à la fermeture de l'app.
_Avoid_: « system notification », « notification » sans qualificatif.

**Payload**:
Le JSON qu'un script externe pousse pour créer une Notification : `title`, `summary`, `level`,
`source`, `icon`. La forme « sur le fil » d'une Notification à naître.
_Avoid_: appeler ça une « notification », « message », « event ».

**Source**:
Le canal de coalescence d'une Notification. Ce n'est pas une simple étiquette d'origine :
deux Payloads de la même `source` ne coexistent pas — le nouveau remplace l'existant. Une
Notification sans source n'est jamais fusionnée.
_Avoid_: « sender », « origin », « channel » (en surface), « author ».

**Level**:
La sévérité d'une Notification : `info` < `success` < `warning` < `error`. Pilote la teinte et
l'icône par défaut.
_Avoid_: « severity » (dans le code/UI), « priority » (réservé à la cohabitation des live activities).

**Coalescence**:
La règle par laquelle un nouveau Drop d'une Source déjà présente **remplace** la Notification
existante (repasse non-lue, remonte en tête) au lieu d'en créer une seconde.
_Avoid_: « merge », « dedup », « grouping ».

### Ingestion

**Inbox**:
Le dossier surveillé où les Drops atterrissent. Unique point d'entrée externe : même le CLI y
écrit plutôt que d'ouvrir un canal direct.
_Avoid_: « queue », « spool », « mailbox ».

**Drop**:
Une unité déposée dans l'Inbox — un fichier portant un Payload. « Déposer » (to drop) est le
geste d'un script qui notifie.
_Avoid_: « file », « message », « entry ».

**Drain**:
L'ingestion, au lancement de l'app, des Drops arrivés pendant qu'elle était fermée. Le Drain
ne déclenche **pas** de bannière (juste la mise à jour du badge).
_Avoid_: « flush », « replay », « catch-up ».

### Surfaces sur le notch

**Badge**:
La surface ambiante au repos : cloche + compteur de non-lues, teinté par la plus haute sévérité
non-lue. Visible ssi il existe au moins une Notification non-lue (et la feature est activée).
_Avoid_: « indicator », « counter » seul, « pill ».

**Arrival banner**:
La bannière transitoire (~3 s) affichée à l'arrivée d'une nouvelle Notification (app active),
avant de retomber sur le Badge. Le garant qu'on ne rate jamais un push.
_Avoid_: « toast », « popup », « alert ».
