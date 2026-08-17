#!/bin/bash

path=$1
selection_file=$2
done_file=$3

[[ -n "$selection_file" ]] && printf '%s\n' "$path" > "$selection_file"
[[ -n "$done_file" ]] && : > "$done_file"
