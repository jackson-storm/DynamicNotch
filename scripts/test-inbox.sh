#!/usr/bin/env bash
#
# test-inbox.sh — manual verification helper for the Notifications feature (Slice 1).
#
# Drops JSON files into the app's watched inbox to exercise each acceptance criterion.
# Build & run the app first, then open the Home carousel's "Notifications" page and watch
# it react. There is NO ambient badge / banner / detail view yet (deferred slices), so the
# carousel page is the only place the notifications appear.
#
# Usage:  scripts/test-inbox.sh <command>
#
#   valid       ① a valid drop  -> appears in the list, file is deleted           (AC#1)
#   drain N     ② drop N valid files with the app CLOSED, then relaunch to drain   (AC#2)
#   malformed   ③ broken JSON    -> moved to inbox/rejected/, no crash, no row      (AC#3)
#   missing     ④ no `summary`   -> rejected at parse                              (AC#4)
#   ignored     ⑤ dotfile + .txt -> ignored (not consumed, not rejected)          (AC#5)
#   verbatim    ⑦ title "50% done" -> shown literally, not as a localization key   (AC#7)
#   burst N     drop N valid files back-to-back (rafale)                           (AC bonus)
#   status      list what's in the inbox and inbox/rejected/
#   logs        stream the monitor's os.log (quarantine messages)
#   clean       remove everything under the inbox (reset)
#   help        show this message
#
# Atomic drops (valid/verbatim/burst/drain) mirror the reference script: write to a
# dotfile temp, then `mv` onto the final `.json` name — so the watcher never reads a
# half-written file. The `malformed`/`ignored` commands write directly ON PURPOSE, to
# exercise the rejection / filtering paths.

set -euo pipefail

INBOX="${HOME}/Library/Application Support/DynamicNotch/inbox"
REJECTED="${INBOX}/rejected"

mkdir -p "${INBOX}"

# --- helpers ---------------------------------------------------------------

# atomic_drop <json-string>  — temp dotfile + rename, safe against the watcher.
atomic_drop() {
    local json="$1"
    local tmp="${INBOX}/.$(uuidgen).tmp"
    printf '%s' "${json}" > "${tmp}"
    mv "${tmp}" "${INBOX}/$(uuidgen).json"
}

# direct_write <name> <content>  — NON-atomic, used to test rejection/filtering.
direct_write() {
    printf '%s' "$2" > "${INBOX}/$1"
}

green() { printf '\033[32m%s\033[0m\n' "$1"; }
dim()   { printf '\033[2m%s\033[0m\n' "$1"; }

# --- commands --------------------------------------------------------------

cmd_valid() {
    atomic_drop '{"title":"Backup nightly","summary":"42 fichiers\nOK","level":"success","source":"backup.sh"}'
    green "① Dropped a valid success notification."
    dim   "   Expect: a green row 'Backup nightly · backup.sh · <time>' with an unread dot,"
    dim   "   and the .json removed from the inbox (run: $0 status)."
}

cmd_drain() {
    local n="${1:-3}"
    for i in $(seq 1 "${n}"); do
        atomic_drop "{\"title\":\"Drain #${i}\",\"summary\":\"landed while the app was closed\",\"level\":\"info\",\"source\":\"drain-${i}\"}"
    done
    green "② Dropped ${n} files."
    dim   "   Do this with the app QUIT (⌘Q). Then relaunch: all ${n} should appear at launch."
}

cmd_malformed() {
    direct_write "$(uuidgen).json" '{ ceci n_est pas du json '
    green "③ Dropped a malformed .json (direct write)."
    dim   "   Expect: no row added, no crash, file moved to inbox/rejected/ (after ~retry)."
    dim   "   Check:  $0 status   and   $0 logs"
}

cmd_missing() {
    # Valid JSON, but no `summary` — must be rejected at parse, not shown as a blank row.
    atomic_drop '{"title":"Sans summary"}'
    green "④ Dropped a JSON missing the required 'summary'."
    dim   "   Expect: no row added, file ends up in inbox/rejected/."
}

cmd_ignored() {
    direct_write ".inflight.json" '{"title":"Hidden","summary":"in-flight temp"}'
    direct_write "note.txt"       'not json at all'
    green "⑤ Dropped a dotfile (.inflight.json) and a non-JSON (note.txt)."
    dim   "   Expect: BOTH remain in the inbox (not consumed, not rejected), no row added."
    dim   "   Check:  $0 status"
}

cmd_verbatim() {
    atomic_drop '{"title":"50% done","summary":"progress report","level":"warning","source":"ci"}'
    green "⑦ Dropped a notification titled '50% done'."
    dim   "   Expect: the row shows literally '50% done' (Text(verbatim:)), never mangled"
    dim   "   into a localization lookup."
}

cmd_burst() {
    local n="${1:-5}"
    for i in $(seq 1 "${n}"); do
        atomic_drop "{\"title\":\"Burst ${i}/${n}\",\"summary\":\"rapid drop\",\"level\":\"info\",\"source\":\"burst-${i}\"}"
    done
    green "Dropped a burst of ${n} files."
    dim   "   Expect: all ${n} appear (no source coalescence in this slice — each is its own row)."
}

cmd_status() {
    green "Inbox: ${INBOX}"
    dim "  eligible .json awaiting ingestion:"
    ls -1 "${INBOX}"/*.json 2>/dev/null | grep -v '/\.' || dim "    (none)"
    dim "  all entries:"
    ls -la "${INBOX}" 2>/dev/null || true
    echo
    green "Rejected: ${REJECTED}"
    ls -la "${REJECTED}" 2>/dev/null || dim "    (no rejected/ dir yet)"
}

cmd_logs() {
    green "Streaming monitor logs (⌃C to stop)…"
    log stream --predicate 'subsystem == "com.dynamicnotch" AND category == "NotificationInbox"'
}

cmd_clean() {
    rm -rf "${INBOX:?}/"* "${INBOX:?}/".* 2>/dev/null || true
    mkdir -p "${INBOX}"
    green "Inbox emptied (files + rejected/). The persisted in-app list is NOT touched"
    dim   "   (use the 'Clear' button in the app to empty that)."
}

# --- dispatch --------------------------------------------------------------

cmd="${1:-help}"
shift || true

case "${cmd}" in
    valid)     cmd_valid ;;
    drain)     cmd_drain "$@" ;;
    malformed) cmd_malformed ;;
    missing)   cmd_missing ;;
    ignored)   cmd_ignored ;;
    verbatim)  cmd_verbatim ;;
    burst)     cmd_burst "$@" ;;
    status)    cmd_status ;;
    logs)      cmd_logs ;;
    clean)     cmd_clean ;;
    help|-h|--help)
        sed -n '2,44p' "$0" | sed 's/^# \{0,1\}//'
        ;;
    *)
        printf 'Unknown command: %s\n\n' "${cmd}" >&2
        sed -n '2,44p' "$0" | sed 's/^# \{0,1\}//' >&2
        exit 1
        ;;
esac
