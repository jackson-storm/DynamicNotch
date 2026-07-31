# L'Inbox est l'unique point d'entrée externe des Notifications

Les process externes (scripts, cron, CI, Raccourcis via action shell) créent une Notification en
déposant un Payload JSON dans un dossier surveillé — l'**Inbox**
(`~/Library/Application Support/DynamicNotch/inbox`) — via une écriture atomique (temp `.`-préfixé →
`rename` vers `<uuid>.json`). C'est le **seul** canal d'entrée : même le CLI `dynamicnotch notify` y
écrit un fichier plutôt que d'ouvrir un canal direct vers l'app.

## Pourquoi

Retenu contre deux alternatives évidentes, pour trois raisons :

- **Durabilité app-fermée.** Un Drop arrivé pendant que l'app est fermée est ingéré au lancement suivant
  (le **Drain**). Un URL scheme ou un service XPC exigent que l'app tourne (ou la lancent) — un push
  émis app fermée serait perdu.
- **Zéro vol de focus.** À l'opposé des **Native notifications** macOS (`UserNotifications`), qui volent
  le focus, disparaissent, ne s'agrègent pas par Source et ne survivent pas à la fermeture.
- **Zéro IPC.** Le file-drop ne demande aucun service à maintenir. Le CLI reste une couche d'ergonomie
  au-dessus du même contrat (il génère le Payload et le dépose), pas une seconde voie d'entrée qui
  pourrait diverger.

## Conséquences

- Contrat d'intégration **difficile à inverser** : tout appelant externe dépend de la forme du Payload
  et de l'existence de l'Inbox ; en changer casserait chaque script.
- **Frontière de confiance assumée** : n'importe quel process local peut écrire dans l'Inbox. Accepté
  pour un usage personnel ; pas d'authentification/signature des Drops.
- Pas d'**accusé de réception** possible côté script : le succès d'un Drop = « fichier déposé
  atomiquement », jamais « affiché ». Un canal synchrone a été délibérément écarté.
