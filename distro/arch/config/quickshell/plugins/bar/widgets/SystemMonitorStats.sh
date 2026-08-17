#!/usr/bin/env bash

awk '
  BEGIN { mt = 0; ma = 0 }
  /^cpu / {
    printf "%s %s %s %s %s %s %s %s %s ", $1, $2, $3, $4, $5, $6, $7, $8, $9
  }
  /^MemTotal:/ { mt = $2 }
  /^MemAvailable:/ { ma = $2 }
  END {
    getline load < "/proc/loadavg"
    split(load, l)
    printf "%d %d %s %s %s\n", mt, ma, l[1], l[2], l[3]
  }
' /proc/stat /proc/meminfo

LC_ALL=C top -b -n 2 -d 0.15 -w 512 | awk '
  /^top -/ { batch++ }
  batch == 2 && $1 ~ /^[0-9]+$/ && $9 ~ /^[0-9]+([.][0-9]+)?$/ {
    printf "proc %s %.1f %.1f\n", $12, $9, $10
    count++
    if (count >= 5) exit
  }
'
