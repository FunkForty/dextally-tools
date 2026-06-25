#!/system/bin/sh
# DexTally — can we read Pokemod's already-decoded mon list from its WebView?
#   su -c 'sh webview-cdp-check.sh' 2>&1 | tee wv-out.txt   ; upload to paste.rs
# Read-only. Run with Pokemod open and its Pokémon-list/IV view showing.

PM=/data/data/com.pokemod.app.public

echo "######## A. WebView DevTools sockets (is remote debugging ON?) ########"
# Chromium exposes an abstract unix socket '@webview_devtools_remote_<pid>' when debuggable.
cat /proc/net/unix 2>/dev/null | grep -aiE 'devtools|webview' || echo "(none in /proc/net/unix)"

echo; echo "######## B. WebView debuggable flag in the APK / app ########"
ps -A -o PID,UID,NAME 2>/dev/null | grep -i pokemod

echo; echo "######## C. WebView on-disk storage — does it cache the mon list? ########"
echo "-- IndexedDB --"; find $PM/app_webview -type d -iname 'IndexedDB' 2>/dev/null
ls -laR $PM/app_webview/Default/IndexedDB 2>/dev/null | head -25
echo "-- Local Storage + IndexedDB leveldb: mon-ish strings --"
find $PM/app_webview \( -name '*.log' -o -name '*.ldb' \) 2>/dev/null | while read f; do
  HIT=$(strings "$f" 2>/dev/null | grep -aiE 'individual_attack|cp_multiplier|"pokemon|pokemonId|isShiny|costume|inventory' | head -3)
  [ -n "$HIT" ] && { echo "== $f =="; echo "$HIT"; }
done | head -30
echo "-- Web Data / leveldb file list --"
ls -la $PM/app_webview/Default/'Local Storage'/leveldb/ 2>/dev/null

echo DONE.
