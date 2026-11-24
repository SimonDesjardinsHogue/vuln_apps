#!/usr/bin/env bash
# Tests de fumee pour lab.sh (aucune exploitation, aucun scan).
# Verifie la syntaxe, l'aide, la liste, les erreurs d'usage et la config Compose.
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
LAB="${ROOT}/lab.sh"

pass=0
fail=0
ok()  { printf '  \033[32mok\033[0m   %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=$((fail + 1)); }
skip(){ printf '  \033[33mskip\033[0m %s\n' "$1"; }

expect_ok() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else bad "$desc"; fi
}

expect_fail() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then bad "$desc"; else ok "$desc"; fi
}

expect_contains() {
  local desc="$1" needle="$2"; shift 2
  local out
  out="$("$@" 2>&1)" || true
  if printf '%s' "$out" | grep -qF -- "$needle"; then ok "$desc"; else bad "$desc"; fi
}

printf 'Tests de fumee - vuln_apps\n\n'

expect_ok  "lab.sh : syntaxe bash valide"          bash -n "$LAB"
expect_ok  "smoke.sh : syntaxe bash valide"        bash -n "${BASH_SOURCE[0]}"
expect_ok  "lab.sh help : code de sortie 0"        "$LAB" help
expect_ok  "lab.sh list : code de sortie 0"        "$LAB" list
expect_contains "lab.sh list : contient juice-shop" "juice-shop" "$LAB" list
expect_contains "lab.sh list : contient dvwa"       "dvwa"       "$LAB" list
expect_contains "lab.sh list : contient webgoat"    "webgoat"    "$LAB" list
expect_contains "lab.sh list : URL locale 127.0.0.1" "127.0.0.1" "$LAB" list
expect_contains "lab.sh help : contient reset"      "reset"      "$LAB" help

expect_fail "lab.sh up sans app : doit echouer"        "$LAB" up
expect_fail "lab.sh up app inconnue : doit echouer"    "$LAB" up application-inexistante
expect_fail "lab.sh logs sans app : doit echouer"      "$LAB" logs
expect_fail "lab.sh commande inconnue : doit echouer"  "$LAB" commande-inexistante

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  expect_ok "compose.yaml : configuration valide" docker compose -f "${ROOT}/compose.yaml" config
  if docker compose -f "${ROOT}/compose.yaml" config 2>/dev/null | grep -qE '0\.0\.0\.0:'; then
    bad "compose.yaml : aucune publication sur 0.0.0.0"
  else
    ok  "compose.yaml : aucune publication sur 0.0.0.0"
  fi
else
  skip "Docker Compose absent : verification de compose.yaml ignoree"
fi

if command -v shellcheck >/dev/null 2>&1; then
  expect_ok "shellcheck lab.sh" shellcheck -S warning "$LAB"
else
  skip "shellcheck absent"
fi

printf '\nResultat : %d reussis, %d echoues\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
