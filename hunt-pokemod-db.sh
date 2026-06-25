#!/system/bin/sh
# DexTally — Pokemod ships its own sqlite3, so it writes a DB somewhere. Find it.
# The decode agents run INSIDE PoGo, so a DB they open shows in PoGo's fds, not the injector's.
#   su -c 'sh hunt-pokemod-db.sh' 2>&1 | tee hunt-out.txt   ; upload to paste.rs
# Read-only.

PM=com.pokemod.app.public
FILES=/data/data/$PM/files

echo "######## A. PoGo process — open regular files (injected agent's DB/working files) ########"
POGO=$(ps -A -o PID,NAME 2>/dev/null | grep -iE 'nianticlabs.pokemongo' | awk '{print $1}' | head -1)
echo "pogo pid: $POGO  cwd=$(readlink /proc/$POGO/cwd 2>/dev/null)"
ls -l /proc/$POGO/fd 2>/dev/null | sed 's/.*-> //' | grep -E '^/' \
  | grep -ivE '^/system|^/apex|^/vendor|^/dev|^/data/app|^/data/dalvik|\.so$|\.apk$|\.odex$|\.vdex$|\.art$|\.oat$|\.jar$|font|icu' \
  | sort -u | head -60

echo; echo "######## B. all pokemod procs — open regular files + cwd ########"
for p in $(ps -A -o PID,NAME 2>/dev/null | grep -iE 'pokemod' | awk '{print $1}'); do
  echo "-- pid $p ($(cat /proc/$p/comm 2>/dev/null)) cwd=$(readlink /proc/$p/cwd 2>/dev/null) --"
  ls -l /proc/$p/fd 2>/dev/null | sed 's/.*-> //' | grep -E '^/' \
    | grep -ivE '^/system|^/apex|^/dev|\.so$|\.apk$|\.jar$' | sort -u | head -25
done

echo; echo "######## C. agent strings — persistence hints (SQL / .db paths / scratch dirs) ########"
for b in $FILES/agents/main_agent $FILES/agents/vpgp_agent $FILES/injector/pokemod-injector; do
  echo "== $b =="
  strings "$b" 2>/dev/null \
    | grep -aoiE 'INSERT INTO [a-z_]+|CREATE TABLE [a-z_]+|REPLACE INTO [a-z_]+|[a-z0-9_./-]+\.db\b|[a-z0-9_./-]+\.sqlite[a-z0-9]*|/data/local/tmp/[a-z0-9_./-]+|/sdcard/[a-z0-9_./-]+|/data/data/[a-z0-9_./-]+\.(db|sqlite)' \
    | sort -u | head -40
done

echo; echo "######## D. SQLite files in scratch/likely dirs ########"
for d in /data/local/tmp /data/data/$PM /data/local/tmp/OGMC; do
  find $d -type f -size -25M 2>/dev/null | while read f; do
    [ "$(head -c 15 "$f" 2>/dev/null)" = "SQLite format 3" ] && echo "SQLITE: $f  ($(ls -la "$f" 2>/dev/null | awk '{print $5}') bytes, mtime $(ls -la "$f" 2>/dev/null | awk '{print $6, $7, $8}'))"
  done
done | head -30
echo "-- name-based on sdcard --"
find /sdcard /data/media/0 2>/dev/null \( -iname '*.db' -o -iname '*.sqlite*' -o -iname '*pokemod*' -o -iname '*vpgp*' -o -iname '*mon*' \) | head -20
echo DONE.
