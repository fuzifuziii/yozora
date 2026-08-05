#!/bin/bash

directory=${1:-$HOME}
[[ -d "$directory" ]] || directory="$HOME"

printf 'D\t..\t%s\n' "$(dirname "$directory")"
find -L "$directory" -mindepth 1 -maxdepth 1 -printf '%y\t%f\t%p\n' 2>/dev/null | sort -f -k2,2
