#!/bin/sh
# Fail if Makefile has lines starting with spaces where a command should start with a tab.
# GNU Make requires tabs for rule commands.
set -e

offending=$(awk '/^ / && !/^ *#/ && !/^ *\|/ && !/\\$/ {print NR":"$0}' Makefile)
if [ -n "$offending" ]; then
    echo "Makefile lines must start with tabs, not spaces. Offending lines:" >&2
    echo "$offending" >&2
    echo "Please replace leading spaces with tabs." >&2
    exit 1
fi
