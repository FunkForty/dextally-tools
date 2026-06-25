#!/system/bin/sh
# DexTally — discover Pokemod's local HTTP API (MainClient on 127.0.0.1:1333).
#   su -c 'sh probe-1333.sh' 2>&1 | tee probe-out.txt
# Read-only: queries localhost + reads the MainClient binary's strings. No Niantic contact.

PORT=1333
BASE="http://127.0.0.1:$PORT"

echo "######## A. ENDPOINT PROBE ########"
for path in / /status /health /healthz /version /info /ping /api /api/v1 /api/v1/inventory \
    /api/inventory /inventory /pokemon /pokemons /mons /storage /box /player /account /trainer \
    /data /state /game /gamestate /get_inventory /getInventory /v1/inventory /list /dump \
    /mod /config /settings /debug /metrics ; do
  CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 2 "$BASE$path" 2>/dev/null)
  BODY=$(curl -s -m 2 "$BASE$path" 2>/dev/null | head -c 200 | tr '\n' ' ')
  echo "[$CODE] $path  ->  $BODY"
done

echo
echo "######## B. MAINCLIENT BINARY — routes via strings ########"
PID=$(ps -A -o PID,NAME 2>/dev/null | grep -i 'MainClient' | awk '{print $1}' | head -1)
echo "MainClient pid: $PID"
BIN=$(readlink /proc/$PID/exe 2>/dev/null)
echo "binary path: $BIN"
echo "open files (config/sockets?):"
ls -l /proc/$PID/fd 2>/dev/null | grep -iE '\.json|\.db|\.sock|\.cfg|\.yaml' | head
echo
echo "--- path-like strings in the binary (candidate routes) ---"
if command -v strings >/dev/null 2>&1; then
  strings "$BIN" 2>/dev/null | grep -E '^/[a-zA-Z][a-zA-Z0-9_/-]+$' | sort -u | head -120
else
  # fallback if 'strings' isn't installed (pkg install binutils)
  grep -aoE '/[a-zA-Z][a-zA-Z0-9_/-]{2,40}' "$BIN" 2>/dev/null | sort -u | head -120
fi

echo
echo "######## C. APK location (pull for jadx if routes need auth) ########"
pm path com.pokemod.app.public 2>/dev/null
echo "DONE."
