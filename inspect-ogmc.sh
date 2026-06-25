#!/system/bin/sh
# DexTally — inspect Pokemod's OGMC core: the mark.db store + MainClient's real routes.
#   su -c 'sh inspect-ogmc.sh' 2>&1 | tee ogmc-out.txt
# Output is short — paste it straight into the chat. Read-only, localhost only.

D=/data/local/tmp/OGMC

echo "######## A. OGMC directory ########"
ls -la $D 2>/dev/null

echo; echo "######## B. mark.db — format + schema + data hints ########"
echo "--- header bytes ---"
head -c 16 $D/mark.db 2>/dev/null | od -c 2>/dev/null | head -1
echo "--- size ---"; ls -l $D/mark.db 2>/dev/null | awk '{print $5" bytes"}'
echo "--- CREATE TABLE / table names ---"
strings $D/mark.db 2>/dev/null | grep -iE 'CREATE TABLE|CREATE INDEX' | head -30
echo "--- inventory/pokemon-ish strings inside it ---"
strings $D/mark.db 2>/dev/null | grep -iE 'pokemon|inventory|individual_|captured|owner' | head -15

echo; echo "######## C. MainClient routes (broad strings) ########"
PID=$(ps -A -o PID,NAME 2>/dev/null | grep -i MainClient | awk '{print $1}' | head -1)
BIN=$(readlink /proc/$PID/exe 2>/dev/null); echo "binary: $BIN"
( strings "$BIN" 2>/dev/null || grep -aoE '/[A-Za-z][A-Za-z0-9_/-]{2,60}' "$BIN" 2>/dev/null ) \
  | grep -aoE '/(ogMain|client|api|inventory|pokemon|player|get|asset|proto)[A-Za-z0-9_/-]*' \
  | sort -u | head -80

echo; echo "######## D. probe under /ogMain ########"
for p in /ogMain /ogMain/ /ogMain/client /ogMain/client/inventory /ogMain/client/internal \
         /ogMain/client/internal/inventory /ogMain/inventory ; do
  CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 2 "http://127.0.0.1:1333$p" 2>/dev/null)
  BODY=$(curl -s -m 2 "http://127.0.0.1:1333$p" 2>/dev/null | head -c 120 | tr '\n' ' ')
  echo "[$CODE] $p -> $BODY"
done
echo DONE.
