#!/bin/bash
# Run this from the root of the boonespooner.com repo on your local machine.
# It downloads all Cargo Collective images referenced in the HTML files,
# saves them to the correct local paths, then stages and commits them.

set -e
REPO="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO"

echo "Finding image paths..."
PATHS=$(grep -roh '/images/cargo/[^"'\'' >]*' portfolio/ | sort -u | grep -v '^/images/cargo/$')

TOTAL=$(echo "$PATHS" | wc -l | tr -d ' ')
COUNT=0
FAILED=0

echo "Downloading $TOTAL images..."

while IFS= read -r localpath; do
  rel="${localpath#/images/cargo/}"
  destdir="images/cargo/${rel%/*}"
  outfile="images${localpath}"
  url="https://payload.cargocollective.com/1/8/260033/${rel}"

  mkdir -p "$destdir"
  COUNT=$((COUNT + 1))

  if [ -f "$outfile" ]; then
    echo "[$COUNT/$TOTAL] SKIP (exists): $rel"
    continue
  fi

  if curl -sL --retry 3 --fail -o "$outfile" "$url"; then
    echo "[$COUNT/$TOTAL] OK: $rel"
  else
    echo "[$COUNT/$TOTAL] FAIL: $rel"
    FAILED=$((FAILED + 1))
    rm -f "$outfile"
  fi
done <<< "$PATHS"

echo ""
echo "Done. $((COUNT - FAILED)) downloaded, $FAILED failed."

if [ "$FAILED" -eq 0 ]; then
  echo ""
  echo "Committing..."
  git add images/
  git commit -m "Add self-hosted Cargo Collective images ($(find images/cargo -type f | wc -l | tr -d ' ') files)"
  git push origin main
  echo "Pushed to main."
else
  echo "Some images failed. Fix manually then run: git add images/ && git commit -m 'Add images' && git push origin main"
fi
