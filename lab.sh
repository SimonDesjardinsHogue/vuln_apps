#!/usr/bin/env bash
# =============================================================================
# lab.sh - Laboratoire local d'applications volontairement vulnerables
# -----------------------------------------------------------------------------
# Gere OWASP Juice Shop, DVWA et OWASP WebGoat via Docker Compose.
# Publication locale uniquement (127.0.0.1), sans demarrage automatique.
#
# Usage    : ./lab.sh <commande> [application|all]
# Commandes: doctor list pull up down status logs reset help
#
# ATTENTION: ces applications sont INTENTIONNELLEMENT vulnerables.
#            A executer uniquement sur cette machine, en cadre autorise.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
COMPOSE_FILE="${SCRIPT_DIR}/compose.yaml"
ENV_FILE="${SCRIPT_DIR}/.env"

APP_NAMES=(juice-shop dvwa webgoat)

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
else
  C_RESET=''; C_BOLD=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''
fi

info() { printf '%s[*]%s %s\n' "$C_BLUE"   "$C_RESET" "$*"; }
ok()   { printf '%s[+]%s %s\n' "$C_GREEN"  "$C_RESET" "$*"; }
warn() { printf '%s[!]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
err()  { printf '%s[x]%s %s\n' "$C_RED"    "$C_RESET" "$*" >&2; }
die()  { err "$*"; exit 1; }

load_env() {
  if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
  fi
}

port_juice_shop() { echo "${JUICE_SHOP_PORT:-3000}"; }
port_dvwa()       { echo "${DVWA_PORT:-4280}"; }
port_webgoat()    { echo "${WEBGOAT_PORT:-8080}"; }
port_webwolf()    { echo "${WEBWOLF_PORT:-9090}"; }

app_profile() {
  case "$1" in
    juice-shop) echo juice-shop ;;
    dvwa)       echo dvwa ;;
    webgoat)    echo webgoat ;;
    *) return 1 ;;
  esac
}

app_url() {
  case "$1" in
    juice-shop) echo "http://127.0.0.1:$(port_juice_shop)" ;;
    dvwa)       echo "http://127.0.0.1:$(port_dvwa)" ;;
    webgoat)    echo "http://127.0.0.1:$(port_webgoat)/WebGoat/  |  WebWolf: http://127.0.0.1:$(port_webwolf)/WebWolf/" ;;
    *) return 1 ;;
  esac
}

app_ports() {
  case "$1" in
    juice-shop) echo "$(port_juice_shop)" ;;
    dvwa)       echo "$(port_dvwa)" ;;
    webgoat)    echo "$(port_webgoat) $(port_webwolf)" ;;
    *) return 1 ;;
  esac
}

app_desc() {
  case "$1" in
    juice-shop) echo "OWASP Juice Shop - boutique en ligne vulnerable" ;;
    dvwa)       echo "DVWA - application PHP vulnerable (+ MariaDB)" ;;
    webgoat)    echo "OWASP WebGoat - lecons web vulnerables (+ WebWolf)" ;;
    *) return 1 ;;
  esac
}

is_app() {
  local a
  for a in "${APP_NAMES[@]}"; do [[ "$a" == "$1" ]] && return 0; done
  return 1
}

COMPOSE_CMD=()
detect_compose() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD=(docker compose); return 0
  fi
  if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD=(docker-compose); return 0
  fi
  return 1
}

compose() { "${COMPOSE_CMD[@]}" --file "$COMPOSE_FILE" "$@"; }

require_docker() {
  command -v docker >/dev/null 2>&1 \
    || die "Docker introuvable. Diagnostic: ./lab.sh doctor  (installation: sudo apt install docker.io docker-cli docker-compose)"
  docker info >/dev/null 2>&1 \
    || die "Demon Docker injoignable. Essayez: sudo systemctl start docker"
  detect_compose \
    || die "Docker Compose introuvable (ni 'docker compose' ni 'docker-compose')."
}

expand_targets() {
  local -n _out="$1"; shift
  local t
  for t in "$@"; do
    if [[ "$t" == all ]]; then _out=("${APP_NAMES[@]}"); return 0; fi
    is_app "$t" || die "Application inconnue: '$t' (voir ./lab.sh list)"
    _out+=("$t")
  done
  [[ ${#_out[@]} -gt 0 ]] || die "Aucune application indiquee (voir ./lab.sh list)."
}

port_in_use() {
  local p="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn 2>/dev/null | awk 'NR>1 {print $4}' | grep -Eq "[:.]${p}\$"
  elif command -v netstat >/dev/null 2>&1; then
    netstat -ltn 2>/dev/null | awk 'NR>2 {print $4}' | grep -Eq "[:.]${p}\$"
  else
    return 1
  fi
}

cmd_list() {
  printf '%sApplications disponibles%s\n\n' "$C_BOLD" "$C_RESET"
  local a
  for a in "${APP_NAMES[@]}"; do
    printf '  %s%s%s\n' "$C_BOLD" "$a" "$C_RESET"
    printf '      %s\n' "$(app_desc "$a")"
    printf '      URL : %s\n\n' "$(app_url "$a")"
  done
  printf 'Demarrer : ./lab.sh up <application>   (ou "all")\n'
}

cmd_doctor() {
  printf '%sDiagnostic du laboratoire%s\n\n' "$C_BOLD" "$C_RESET"
  local fail=0 free_kb mem_mb a p

  if command -v docker >/dev/null 2>&1; then
    ok "Docker present : $(docker --version 2>/dev/null | head -1)"
  else
    err "Docker absent  -> sudo apt install docker.io docker-cli docker-compose"; fail=1
  fi

  if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
      ok "Demon Docker joignable"
    else
      err "Demon Docker injoignable -> sudo systemctl start docker"; fail=1
    fi
    if id -nG 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
      ok "Utilisateur membre du groupe docker"
    else
      warn "Utilisateur hors du groupe docker -> sudo usermod -aG docker \$USER (puis reconnexion)"
    fi
  fi

  if detect_compose; then
    ok "Docker Compose present : $("${COMPOSE_CMD[@]}" version 2>/dev/null | head -1) [${COMPOSE_CMD[*]}]"
  else
    err "Docker Compose absent -> sudo apt install docker-compose"; fail=1
  fi

  free_kb=$(df -Pk "$SCRIPT_DIR" | awk 'NR==2 {print $4}')
  if [[ -n "$free_kb" && "$free_kb" -gt 5242880 ]]; then
    ok "Espace disque suffisant ($(( free_kb / 1048576 )) GiB libres)"
  elif [[ -n "$free_kb" ]]; then
    warn "Espace disque faible ($(( free_kb / 1048576 )) GiB libres, >= 5 GiB conseilles)"
  fi

  mem_mb=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 0)
  if [[ "$mem_mb" -ge 2048 ]]; then
    ok "Memoire suffisante (${mem_mb} MiB)"
  else
    warn "Memoire faible (${mem_mb} MiB, >= 2048 MiB conseilles)"
  fi

  for a in "${APP_NAMES[@]}"; do
    for p in $(app_ports "$a"); do
      if port_in_use "$p"; then
        warn "Port $p deja utilise ($a) -> changez le port dans .env"
      else
        ok "Port $p libre ($a)"
      fi
    done
  done

  printf '\n'
  if [[ "$fail" -eq 0 ]]; then
    ok "Diagnostic termine : environnement pret."
  else
    err "Diagnostic termine : des prerequis manquent (voir ci-dessus)."
  fi
  return "$fail"
}

cmd_pull() {
  local targets=(); expand_targets targets "$@"
  require_docker
  local t
  for t in "${targets[@]}"; do
    info "Telechargement des images pour '$t'..."
    compose --profile "$(app_profile "$t")" pull
    ok "Images de '$t' telechargees."
  done
}

cmd_up() {
  local targets=(); expand_targets targets "$@"
  require_docker
  local t
  for t in "${targets[@]}"; do
    info "Demarrage de '$t'..."
    compose --profile "$(app_profile "$t")" up --detach
    ok "'$t' demarre : $(app_url "$t")"
  done
}

cmd_down() {
  local targets=(); expand_targets targets "$@"
  require_docker
  local t
  for t in "${targets[@]}"; do
    info "Arret de '$t' (donnees conservees)..."
    compose --profile "$(app_profile "$t")" down
    ok "'$t' arrete."
  done
}

cmd_status() {
  require_docker
  printf '%sEtat du laboratoire%s\n\n' "$C_BOLD" "$C_RESET"
  compose ps --all
}

cmd_logs() {
  local targets=(); expand_targets targets "$@"
  require_docker
  local t="${targets[0]}"
  compose --profile "$(app_profile "$t")" logs --follow --tail 100
}

cmd_reset() {
  local targets=(); expand_targets targets "$@"
  require_docker
  local t ans
  for t in "${targets[@]}"; do
    printf 'Reinitialiser %s%s%s ? Toutes ses donnees seront supprimees. [y/N] ' "$C_BOLD" "$t" "$C_RESET"
    read -r ans
    if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
      info "Reinitialisation de '$t'..."
      compose --profile "$(app_profile "$t")" down --volumes
      ok "'$t' reinitialise."
    else
      info "Reinitialisation de '$t' annulee."
    fi
  done
}

cmd_help() {
  cat <<'EOF'
lab.sh - laboratoire local d'applications volontairement vulnerables

Usage:
  ./lab.sh <commande> [application|all]

Applications: juice-shop, dvwa, webgoat

Commandes:
  doctor            Verifie Docker, Compose, ressources et ports libres
  list              Liste les applications et leurs URL locales
  pull [app|all]    Telecharge les images (sans demarrer)
  up <app|all>      Demarre une application (127.0.0.1 uniquement)
  down <app|all>    Arrete et supprime les conteneurs (donnees conservees)
  status            Affiche l'etat des conteneurs du laboratoire
  logs <app>        Suit les journaux d'une application
  reset <app|all>   Arrete et supprime conteneurs ET donnees (confirmation)
  help              Affiche cette aide

Securite:
  Ports publies sur 127.0.0.1 uniquement. Aucun demarrage automatique.
  Ces applications sont INTENTIONNELLEMENT vulnerables : usage local seul.
EOF
}

main() {
  load_env
  local cmd="${1:-help}"; shift || true
  case "$cmd" in
    doctor) cmd_doctor ;;
    list)   cmd_list ;;
    pull)   cmd_pull "$@" ;;
    up)     cmd_up "$@" ;;
    down)   cmd_down "$@" ;;
    status) cmd_status ;;
    logs)   cmd_logs "$@" ;;
    reset)  cmd_reset "$@" ;;
    help|-h|--help) cmd_help ;;
    *) err "Commande inconnue: '$cmd'"; printf '\n'; cmd_help; exit 2 ;;
  esac
}

main "$@"
