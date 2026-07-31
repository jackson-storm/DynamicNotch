Status: done

# Slice 4 — Docs README : CLI en voie principale

## What to build

Mettre à jour la section « 🔔 Script Notifications » du `README.md` pour présenter le CLI `dynamicnotch`
comme la **voie principale/recommandée**, tout en conservant le file-drop JSON brut comme couche
bas-niveau documentée. Voir `docs/cli-notify-feature-spec.md` §5, §7.

### Contenu

1. **Installation** : mentionner le bouton **Réglages → « Installer l'outil CLI »** qui pose
   `dynamicnotch` sur le `PATH` (`/usr/local/bin`).
2. **Usage CLI** (recommandé) :
   ```bash
   dynamicnotch notify --title "Backup nightly" \
     --summary $'42 files, 1.2 GB\nOK' --level success \
     --source backup.sh --icon externaldrive.badge.checkmark

   # summary depuis stdin (pipe de la sortie d'un job)
   backup.sh 2>&1 | dynamicnotch notify --title "Backup nightly" --level success --source backup.sh
   ```
   Décrire les flags : `--title`/`--summary` requis (summary via flag **ou** stdin), `--level`
   (`info|success|warning|error`, défaut `info`, strict), `--source` (coalescence), `--icon` (SF Symbol).
3. **Voie bas-niveau (file-drop)** : conserver le contrat JSON et le one-liner atomique existants, mais
   les présenter comme **alternative bas-niveau** pour les environnements sans le CLI. Signaler que le
   CLI génère un **nom de fichier unique** (le one-liner à nom fixe `drop.json` peut perdre une notif
   sous rafale).
4. **Anglais-only** : le CLI et sa doc restent en anglais ; pas de clés de localisation dans le README.

## Acceptance criteria

- [ ] La section documente `dynamicnotch notify` comme voie principale, avec exemples flag et stdin.
- [ ] Les flags sont décrits (requis vs optionnels ; `--level` strict ; stdin pour `summary`).
- [ ] L'installation via le bouton Réglages est mentionnée.
- [ ] Le file-drop JSON brut est conservé comme couche bas-niveau, avec la nuance « nom unique côté CLI ».
- [ ] Aucune régression/réordonnancement involontaire du reste du README ; prose anglaise.

## Blocked by

Slices 2 et 3 (le CLI et son installation doivent exister pour être documentés fidèlement).
