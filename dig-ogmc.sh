#!/system/bin/sh
# DexTally — does Pokemod PERSIST decrypted game data anywhere we can read?
#   su -c 'sh dig-ogmc.sh' 2>&1 | tee dig-out.txt   ; then upload to paste.rs
# Read-only, local only.

D=/data/local/tmp/OGMC

echo "######## A. log/ — what does MainClient write? ########"
ls -la $D/log/ 2>/dev/null
echo "--- size + first/last bytes of each log ---"
for f in $D/log/*; do
  [ -f "$f" ] || continue
  echo "== $f ($(wc -c < "$f" 2>/dev/null) bytes) =="
  head -c 600 "$f" 2>/dev/null; echo " […] "; tail -c 600 "$f" 2>/dev/null; echo
done
echo "--- grep ALL of OGMC for game data ---"
grep -riaoE 'individual_(attack|defense|stamina)|pokemon_id|GetInventory|inventory_item|cp_multiplier|pokedex' $D 2>/dev/null | head -20

echo; echo "######## B. conf/ + app/ (config may reveal the API / a data path) ########"
ls -la $D/conf/ $D/app/ 2>/dev/null
for f in $D/conf/*; do [ -f "$f" ] && { echo "== $f =="; head -c 1200 "$f" 2>/dev/null; echo; }; done

echo; echo "######## C. Pokemod APK — how does it call 127.0.0.1:1333? ########"
APK=$(pm path com.pokemod.app.public 2>/dev/null | sed 's/package://' | head -1)
echo "apk: $APK"
WORK=/data/local/tmp/_pmdex; rm -rf $WORK; mkdir -p $WORK
( unzip -o "$APK" 'classes*.dex' -d $WORK >/dev/null 2>&1 ) || echo "(unzip missing? pkg install unzip)"
( strings $WORK/*.dex 2>/dev/null || cat $WORK/*.dex 2>/dev/null ) \
  | grep -aoiE '127\.0\.0\.1[:0-9]*|localhost[:0-9]*|:1333|/client/[A-Za-z0-9_/]*|/ogMain[A-Za-z0-9_/]*|http://[A-Za-z0-9_./:-]+|getInventory|inventory' \
  | sort -u | head -60
rm -rf $WORK
echo DONE.
