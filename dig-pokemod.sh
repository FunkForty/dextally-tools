#!/system/bin/sh
# DexTally — examine POKEMOD itself (we skipped it for the OGMC/Ugphone red herring).
# Pokemod already decodes your full inventory for its IV overlay/list — does it PERSIST
# or EXPOSE that anywhere we can read?
#   su -c 'sh dig-pokemod.sh' 2>&1 | tee pm-out.txt   ; upload to paste.rs
# Read-only. (For section G: pkg install unzip binutils)

PM=com.pokemod.app.public

echo "######## A. Pokemod data tree (biggest files first — a mon DB?) ########"
find /data/data/$PM -type f 2>/dev/null -exec ls -la {} \; | sort -k5 -n -r | head -50

echo; echo "######## B. databases (SQLite / Realm) + tables ########"
for db in $(find /data/data/$PM -type f \( -iname '*.db' -o -iname '*.sqlite*' -o -iname '*.realm' -o -iname '*.store' \) 2>/dev/null); do
  echo "== $db =="
  head -c 16 "$db" 2>/dev/null | od -c 2>/dev/null | head -1
  strings "$db" 2>/dev/null | grep -iE 'CREATE TABLE|pokemon|inventory|individual|costume|shiny' | head -25
done

echo; echo "######## C. files mentioning mon data ########"
grep -rliaE 'pokemon_id|individual_attack|inventory|cp_multiplier|encounter' /data/data/$PM 2>/dev/null | head -20

echo; echo "######## D. Pokemod processes + their IPC sockets (injector<->UI channel) ########"
ps -A -o PID,USER,NAME 2>/dev/null | grep -i pokemod
PIDS=$(ps -A -o PID,NAME 2>/dev/null | grep -i pokemod | awk '{print $1}')
echo "pids: $PIDS"
echo "-- unix domain sockets (abstract + filesystem) --"
( ss -xlp 2>/dev/null || netstat -xlp 2>/dev/null ) | grep -iE 'pokemod' | head
echo "-- TCP listeners owned by pokemod --"
( ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null ) | grep -iE 'pokemod' | head
for p in $PIDS; do
  echo "-- pid $p fds (sockets/dbs/pipes) --"
  ls -l /proc/$p/fd 2>/dev/null | grep -iE 'socket:|\.db|\.sock|pipe:|\.realm' | head -15
  echo "   exe: $(readlink /proc/$p/exe 2>/dev/null)"
done

echo; echo "######## E. exported components (content providers we could query) ########"
dumpsys package $PM 2>/dev/null | grep -iB1 'exported=true' | grep -iE 'Provider|Service|Receiver|Authority' | head -20

echo; echo "######## F. APK dex strings — IPC / provider / data hints ########"
APK=$(pm path $PM 2>/dev/null | sed 's/package://' | head -1); echo "apk: $APK"
W=/data/local/tmp/_pm; rm -rf $W; mkdir -p $W
unzip -o "$APK" 'classes*.dex' -d $W >/dev/null 2>&1 || echo "(unzip missing -> pkg install unzip)"
strings $W/*.dex 2>/dev/null \
  | grep -aoiE 'content://[A-Za-z0-9._/-]+|[A-Za-z_]+\.sock|LocalSocket[A-Za-z]*|127\.0\.0\.1:[0-9]+|getInventory|inventoryItem|pokemonData|individualAttack' \
  | sort -u | head -60
rm -rf $W
echo DONE.
