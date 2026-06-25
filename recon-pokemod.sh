#!/system/bin/sh
# DexTally capture recon — run on the rooted Ugphone via Termux:
#   su -c 'sh <(curl -fsSL https://YOURHOST/recon-pokemod.sh)'
# Read-only. Finds where Pokemod/PoGo might expose inventory we could read.
# Best run with PoGo OPEN and your storage box scrolled at least once.

echo "######## 1. PACKAGES (separate Pokemod app, or patched PoGo?) ########"
pm list packages -f 2>/dev/null | grep -iE 'pokemon|pokemod|niantic|umbrella|inject|mod'

echo; echo "######## 2. RUNNING PROCESSES + PIDs ########"
ps -A -o PID,USER,NAME 2>/dev/null | grep -iE 'pokemon|pokemod' || ps 2>/dev/null | grep -iE 'pokemon|pokemod'
GAME_PIDS=$(ps -A -o PID,NAME 2>/dev/null | grep -iE 'pokemon|pokemod' | awk '{print $1}')
echo "game/pokemod PIDs: $GAME_PIDS"

echo; echo "######## 3. LOCAL LISTENING SOCKETS + live probe (a local server is the jackpot) ########"
( ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null ) | grep -iE 'LISTEN|127.0.0.1|::1'
PORTS=$( ( ss -tln 2>/dev/null || netstat -tln 2>/dev/null ) | grep -oE '127.0.0.1:[0-9]+|\[::1\]:[0-9]+|0.0.0.0:[0-9]+' | grep -oE '[0-9]+$' | sort -u )
for PORT in $PORTS; do
  case "$PORT" in 5037|3000) continue;; esac
  echo "--- GET http://127.0.0.1:$PORT/ ---"
  curl -s -m 2 "http://127.0.0.1:$PORT/" 2>/dev/null | head -c 500
  echo
done
echo "--- unix domain sockets ---"
( ss -lxp 2>/dev/null || netstat -lxp 2>/dev/null ) | grep -iE 'pokemod|pogo|niantic'

echo; echo "######## 4. INJECTED LIBRARIES in the game process (non-system .so = a hook) ########"
for PID in $GAME_PIDS; do
  echo "--- /proc/$PID/maps (non-standard files) ---"
  cat /proc/$PID/maps 2>/dev/null | awk '{print $6}' \
    | grep -E '\.so$|\.dex$|\.apk$' | grep -vE '^/system|^/apex|^/vendor|^/data/app|^/data/dalvik' | sort -u | head -30
done

echo; echo "######## 5. INSTRUMENTATION SIGNS (frida etc.) ########"
ps -A 2>/dev/null | grep -iE 'frida|gum|gadget' | grep -v grep
( ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null ) | grep -E ':2704[0-9]'

echo; echo "######## 6. DATA AT REST (dbs / json / protobuf / caches) ########"
for P in $(pm list packages 2>/dev/null | grep -iE 'pokemod|pokemongo|niantic' | sed 's/package://'); do
  echo "--- /data/data/$P ---"
  find /data/data/$P -type f \( -iname '*.db' -o -iname '*.json' -o -iname '*.pb' \
      -o -iname '*.proto' -o -iname '*.sqlite' -o -iname '*cache*' -o -iname '*inventory*' \) 2>/dev/null | head -40
done
echo "--- shared storage ---"
find /sdcard 2>/dev/null -iname '*pokemod*' -o -iname '*inventory*' | head -20

echo; echo "######## 7. EXPORTED IPC (providers/services/receivers we could query) ########"
for P in $(pm list packages 2>/dev/null | grep -iE 'pokemod|pokemongo|niantic' | sed 's/package://'); do
  echo "--- $P exported=true ---"
  dumpsys package "$P" 2>/dev/null | grep -iB1 'exported=true' | grep -iE 'Provider|Service|Receiver|Activity' | head -20
done

echo; echo "######## 8. APK paths (pull for jadx static analysis) ########"
for P in $(pm list packages 2>/dev/null | grep -iE 'pokemod|pokemongo|niantic' | sed 's/package://'); do
  echo "$P:"; pm path "$P" 2>/dev/null
done
echo; echo "DONE."
