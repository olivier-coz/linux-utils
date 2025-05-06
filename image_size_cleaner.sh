#!/usr/bin/env bash
# image_size_cleaner.sh
# Deletes (or previews) images smaller than a user‑defined width/height.

set -euo pipefail
IFS=$'\n\t'

########################################
# 0) dependency
########################################
command -v identify >/dev/null 2>&1 || {
  echo "Error: ImageMagick’s ‘identify’ is required." >&2; exit 1; }

########################################
# 1) target folder
########################################
read -r -p "Folder to scan: " TARGET
TARGET="${TARGET%/}"
[[ -d "$TARGET" ]] || { echo "Not a directory."; exit 1; }

########################################
# 2) recurse?
########################################
read -r -p "Include subdirectories? [N/y]: " ans
RECURSE=false; [[ ${ans,,} == y* ]] && RECURSE=true

########################################
# 3) dry‑run?
########################################
read -r -p "Dry‑run (preview only)? [N/y]: " ans
DRY_RUN=false; [[ ${ans,,} == y* ]] && DRY_RUN=true

########################################
# 4) formats
########################################
read -r -p "Image formats (comma separated, e.g. png,jpg,gif): " line
line=${line,,}
IFS=',' read -ra fmt_raw <<< "$line"

fmts=()
for f in "${fmt_raw[@]}"; do
  [[ -z $f ]] && continue
  if [[ $f == jpg || $f == jpeg ]]; then
    fmts+=(jpg jpeg)
  else
    fmts+=("$f")
  fi
done
fmts=($(printf '%s\n' "${fmts[@]}" | sort -u))
[[ ${#fmts[@]} -eq 0 ]] && { echo "No valid formats."; exit 1; }

########################################
# 5) collect files by extension (fast)
########################################
candidates=()

if $RECURSE; then
  for ext in "${fmts[@]}"; do
    while IFS= read -r -d '' f; do candidates+=("$f"); done \
      < <(find "$TARGET" -type f -iname "*.$ext" -print0)
  done
else
  shopt -s nullglob nocaseglob
  for ext in "${fmts[@]}"; do
    for f in "$TARGET"/*."$ext"; do candidates+=("$f"); done
  done
  shopt -u nullglob nocaseglob
fi

echo
echo "📁 Folder selected: $TARGET"
echo "🔍 ${#candidates[@]} file(s) with extension(s): ${fmts[*]}"
(( ${#candidates[@]} == 0 )) && { echo "No files found. Exiting."; exit 0; }
echo "First 5 files:"
for f in "${candidates[@]:0:5}"; do echo "  - $f"; done

########################################
# 6) size thresholds
########################################
read -r -p "Minimum width : " MIN_W
read -r -p "Minimum height: " MIN_H
[[ $MIN_W =~ ^[0-9]+$ && $MIN_H =~ ^[0-9]+$ ]] \
  || { echo "Width/height must be numbers."; exit 1; }

echo "Delete an image if:"
select opt in "1) EITHER width OR height is smaller" "2) BOTH width AND height are smaller"; do
  case $REPLY in
    1) MODE=either; break ;;
    2) MODE=both  ; break ;;
    *) echo "Choose 1 or 2." ;;
  esac
done

echo
$DRY_RUN && echo "🚀 Dry‑run: files will only be listed." \
          || echo "🚀 Deletion will start immediately."
read -r -p "Proceed? [N/y]: " ok
[[ ${ok,,} != y* ]] && { echo "Aborted."; exit 0; }
echo

########################################
# 7) single‑pass analyse + delete/echo
########################################
deleted=0 skipped=0
for f in "${candidates[@]}"; do
  dim=$(identify -format "%w %h" "$f" 2>/dev/null) || { (( skipped++ )); continue; }
  w=${dim%% *}; h=${dim##* }

  small=false
  if [[ $MODE == either && ( $w -lt $MIN_W || $h -lt $MIN_H ) ]]; then
    small=true
  elif [[ $MODE == both  &&   $w -lt $MIN_W &&  $h -lt $MIN_H ]]; then
    small=true
  fi

  if $small; then
    if $DRY_RUN; then
      echo "Would delete: $f (${w}×${h})"
    else
      echo "Deleting    : $f (${w}×${h})"
      rm -f -- "$f"
      (( deleted++ ))
    fi
  fi
done

echo
if $DRY_RUN; then
  echo "Dry‑run complete."
else
  echo "Finished. $deleted file(s) deleted."
fi
