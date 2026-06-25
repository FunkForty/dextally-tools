#!/system/bin/sh
# DexTally — does PoGo persist the inventory on disk (= no hook needed)?
#   su -c 'sh check-pogo-cache.sh' 2>&1 | tee pogo-out.txt   ; upload to paste.rs
# Read-only.

P=/data/data/com.nianticlabs.pokemongo

echo "######## A. PoGo data tree (dbs / files / caches by size) ########"
find $P -type f 2>/dev/null -exec ls -la {} \; | sort -k5 -n -r | head -40

echo; echo "######## B. SQLite databases + their tables ########"
for db in $(find $P -type f \( -iname '*.db' -o -iname '*.sqlite*' \) 2>/dev/null); do
  echo "== $db =="
  head -c 16 "$db" 2>/dev/null | od -c 2>/dev/null | head -1
  strings "$db" 2>/dev/null | grep -iE 'CREATE TABLE' | head -20
done

echo; echo "######## C. any file mentioning inventory/pokemon data ########"
grep -rliaE 'pokemon_id|individual_attack|inventory_item|cp_multiplier' $P 2>/dev/null | head -20

echo; echo "######## D. shared_prefs + files dir listing ########"
ls -la $P/shared_prefs/ $P/files/ $P/cache/ 2>/dev/null | head -50
echo DONE.
