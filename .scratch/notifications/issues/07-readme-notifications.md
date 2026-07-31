Status: ready-for-agent

## What to build

Update `README.md` to document the Notifications inbox feature end-to-end, in two places:

1. **Highlights section** — add a bullet for the new feature alongside the existing live-activity entries. It should convey: ambient badge (bell + unread counter on the notch), transient arrival banner, inbox folder watched for JSON drops, and per-notification level (`info`/`success`/`warning`/`error`).

2. **New "🔔 Script Notifications" section** — placed before the Gallery, explaining:
   - What the feature does (scripts push a short JSON into a watched folder; DynamicNotch shows an ambient badge and a banner, coalesces by source, persists across restarts).
   - The JSON contract:
     ```json
     {
       "title":   "Backup nightly",
       "summary": "42 files, 1.2 GB\nOK",
       "level":   "success",
       "source":  "backup.sh",
       "icon":    "externaldrive.badge.checkmark"
     }
     ```
     Fields: `title` and `summary` are required; `level` defaults to `info`; `source` enables coalescence (new drop from the same source replaces the existing entry); `icon` is an optional SF Symbol name.
   - The atomic one-liner for scripts (temp file + `mv` to avoid partial reads):
     ```bash
     tmp=$(mktemp "${INBOX}/.XXXXXX.json") \
       && printf '{"title":"…","summary":"…","level":"success","source":"my-script"}' > "$tmp" \
       && mv "$tmp" "${INBOX}/drop.json"
     ```
     Where `INBOX` is the path revealed by **Settings → Notifications → Reveal inbox in Finder**.
   - How to enable: single **Notifications** toggle in Settings activates both the ambient badge and the carousel page.

## Acceptance criteria

- [ ] The Highlights bullet mentions: ambient badge, arrival banner, JSON inbox drops, and severity levels.
- [ ] A new section "🔔 Script Notifications" (or equivalent heading) appears before the Gallery section.
- [ ] The section includes the JSON schema with field descriptions (required vs optional).
- [ ] The section includes the atomic `tmp` + `mv` one-liner with the `INBOX` variable clearly explained.
- [ ] The section mentions the Settings toggle and the "Reveal inbox in Finder" button.
- [ ] All prose uses `Text(verbatim:)` semantics in spirit — no localisation keys, no interpolation artefacts; the README itself is English-only.
- [ ] No existing README content is removed or reordered unintentionally.

## Blocked by

None — can start immediately.
