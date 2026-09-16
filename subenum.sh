#!/usr/bin/env bash
#
# subenum.sh
#
# Production-oriented passive subdomain enumeration wrapper.
#
# Usage:
#   ./subenum.sh doxbin.com
#   ./subenum.sh example.com example.org
#   ./subenum.sh -f targets.txt
#   ./subenum.sh -f targets.txt -r
#   ./subenum.sh -f targets.txt -r -o /opt/recon
#
# Passive enumeration:
#   ProjectDiscovery Subfinder
#
# Optional:
#   DNS A/AAAA resolution of discovered hosts
#
# No port scanning, exploitation, brute forcing, or service interaction.
#

set -Eeuo pipefail
IFS=$'\n\t'

VERSION="1.0.0"

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

OUT="${HOME}/subenum-results"
TARGET_FILE=""
RESOLVE=0
QUIET=0
INSTALL_MISSING=0
TARGETS=()

TMP=""

cleanup() {
    [[ -n "${TMP:-}" && -d "$TMP" ]] && rm -rf -- "$TMP"
}

trap cleanup EXIT
trap 'printf "\n[!] Interrupted\n" >&2; exit 130' INT TERM

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION

Passive subdomain enumeration using ProjectDiscovery Subfinder.

Usage:
  $SCRIPT_NAME [options] domain [domain ...]

Options:
  -f FILE       Read domains from FILE
  -o DIR        Output directory
  -r            Resolve discovered hosts with DNS
  -i            Automatically install Subfinder if missing
  -q            Quiet operational output
  -h            Show help
  -v            Show version

Examples:
  $SCRIPT_NAME example.com
  $SCRIPT_NAME example.com example.org
  $SCRIPT_NAME -f targets.txt
  $SCRIPT_NAME -f targets.txt -r
  $SCRIPT_NAME -f targets.txt -r -o /opt/recon
  $SCRIPT_NAME -i doxbin.com

Output:
  DIR/
    all-subdomains.txt
    DOMAIN/
      subfinder.raw.txt
      subdomains.txt
      dns.txt
EOF
}

log() {
    (( QUIET )) && return 0
    printf '[+] %s\n' "$*"
}

warn() {
    printf '[!] %s\n' "$*" >&2
}

die() {
    printf '[!] %s\n' "$*" >&2
    exit 1
}

need_command() {
    command -v "$1" >/dev/null 2>&1 ||
        die "Required command not found: $1"
}

is_root() {
    [[ "${EUID:-$(id -u)}" -eq 0 ]]
}

real_home() {
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        getent passwd "$SUDO_USER" 2>/dev/null |
            awk -F: '{print $6}' ||
            printf '%s\n' "$HOME"
    else
        printf '%s\n' "$HOME"
    fi
}

normalize_domain() {
    local value="$1"

    value="${value//$'\r'/}"
    value="$(printf '%s' "$value" | sed -E \
        's/^[[:space:]]+//; s/[[:space:]]+$//')"

    value="$(printf '%s' "$value" |
        sed -E 's#^[[:alpha:]][[:alnum:]+.-]*://##')"

    value="${value%%/*}"
    value="${value%%\?*}"
    value="${value%%#*}"
    value="${value%%:*}"
    value="${value%.}"

    printf '%s' "$value" |
        tr '[:upper:]' '[:lower:]'
}

valid_domain() {
    local d="$1"

    [[ -n "$d" ]] || return 1
    [[ ${#d} -le 253 ]] || return 1

    [[ "$d" =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$ ]] ||
        return 1

    [[ "$d" == *.* ]] ||
        return 1

    return 0
}

load_targets() {
    local line normalized

    if [[ -n "$TARGET_FILE" ]]; then
        [[ -f "$TARGET_FILE" ]] ||
            die "Target file not found: $TARGET_FILE"

        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%%#*}"
            normalized="$(normalize_domain "$line")"

            [[ -z "$normalized" ]] && continue

            if valid_domain "$normalized"; then
                TARGETS+=("$normalized")
            else
                warn "Skipping invalid target: $line"
            fi
        done < "$TARGET_FILE"
    fi

    local arg
    for arg in "$@"; do
        normalized="$(normalize_domain "$arg")"

        if valid_domain "$normalized"; then
            TARGETS+=("$normalized")
        else
            warn "Skipping invalid target: $arg"
        fi
    done

    [[ "${#TARGETS[@]}" -gt 0 ]] ||
        die "No valid targets supplied"

    mapfile -t TARGETS < <(
        printf '%s\n' "${TARGETS[@]}" |
            sort -fu
    )
}

find_subfinder() {
    local candidate

    if command -v subfinder >/dev/null 2>&1; then
        command -v subfinder
        return 0
    fi

    local go_bin
    go_bin="$(go env GOPATH 2>/dev/null || true)"

    if [[ -n "$go_bin" ]]; then
        candidate="${go_bin}/bin/subfinder"

        if [[ -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    fi

    for candidate in \
        "$HOME/go/bin/subfinder" \
        "/root/go/bin/subfinder" \
        "/usr/local/bin/subfinder" \
        "/usr/bin/subfinder" \
        "/opt/subfinder/subfinder"
    do
        if [[ -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

install_subfinder() {
    local go_cmd=""

    if command -v go >/dev/null 2>&1; then
        go_cmd="$(command -v go)"
    elif [[ -x /usr/local/go/bin/go ]]; then
        go_cmd="/usr/local/go/bin/go"
        export PATH="/usr/local/go/bin:${PATH}"
    else
        return 1
    fi

    log "Go found at $go_cmd"
    log "Installing Subfinder..."

    "$go_cmd" install -v \
        github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

    local gobin
    gobin="$("$go_cmd" env GOPATH)/bin"

    export PATH="${gobin}:${PATH}"

    [[ -x "${gobin}/subfinder" ]] ||
        return 1

    return 0
}

setup_subfinder() {
    local sf

    sf="$(find_subfinder 2>/dev/null || true)"

    if [[ -n "$sf" ]]; then
        printf '%s\n' "$sf"
        return 0
    fi

    if (( INSTALL_MISSING )); then
        install_subfinder ||
            die "Unable to install Subfinder. Install Go and rerun with -i."

        sf="$(find_subfinder 2>/dev/null || true)"

        [[ -n "$sf" ]] ||
            die "Subfinder installation completed but binary was not found."

        printf '%s\n' "$sf"
        return 0
    fi

    cat >&2 <<EOF

[!] Subfinder is not installed or is not in PATH.

Install it with:

    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

Or let this script install it:

    $SCRIPT_NAME -i example.com

EOF

    exit 1
}

validate_subfinder() {
    local sf="$1"

    "$sf" -version >/dev/null 2>&1 ||
        die "Subfinder executable is not working: $sf"
}

prepare_output() {
    mkdir -p -- "$OUT" ||
        die "Unable to create output directory: $OUT"

    [[ -w "$OUT" ]] ||
        die "Output directory is not writable: $OUT"
}

enumerate_target() {
    local domain="$1"
    local target_dir="$OUT/$domain"

    local raw="$target_dir/subfinder.raw.txt"
    local hosts="$target_dir/subdomains.txt"
    local dns="$target_dir/dns.txt"

    mkdir -p -- "$target_dir"

    : > "$raw"
    : > "$hosts"

    log "Enumerating $domain"

    if ! "$SUBFINDER_BIN" \
        -d "$domain" \
        -all \
        -recursive \
        -silent \
        -o "$raw"
    then
        warn "Subfinder failed for $domain"
        return 1
    fi

    if [[ ! -s "$raw" ]]; then
        log "$domain: no results returned"
        return 0
    fi

    awk -v domain="$domain" '
        BEGIN {
            IGNORECASE=1
            suffix="." domain
        }

        {
            gsub(/\r/, "")
            gsub(/^[[:space:]]+|[[:space:]]+$/, "")

            host=tolower($0)

            if (host == domain ||
                (length(host) > length(suffix) &&
                 substr(host, length(host)-length(suffix)+1) == suffix)) {
                print host
            }
        }
    ' "$raw" |
        sed 's/\.$//' |
        sort -fu > "$hosts"

    log "$domain: $(wc -l < "$hosts") unique hosts"

    if (( RESOLVE )); then
        resolve_hosts "$hosts" "$dns"
    fi

    return 0
}

resolve_hosts() {
    local hosts="$1"
    local output="$2"
    local host ip

    : > "$output"

    while IFS= read -r host; do
        [[ -z "$host" ]] && continue

        while IFS= read -r ip; do
            [[ -z "$ip" ]] && continue
            printf '%s\tA\t%s\n' "$host" "$ip" >> "$output"
        done < <(
            dig +short A "$host" 2>/dev/null |
                grep -E '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' |
                sort -u
        )

        while IFS= read -r ip; do
            [[ -z "$ip" ]] && continue
            printf '%s\tAAAA\t%s\n' "$host" "$ip" >> "$output"
        done < <(
            dig +short AAAA "$host" 2>/dev/null |
                grep -E ':' |
                sort -u
        )

    done < "$hosts"

    sort -u "$output" -o "$output"

    log "DNS: $(wc -l < "$output") records"
}

build_master() {
    local master="$OUT/all-subdomains.txt"

    : > "$master"

    local domain file

    for domain in "${TARGETS[@]}"; do
        file="$OUT/$domain/subdomains.txt"

        [[ -f "$file" ]] || continue

        cat "$file" >> "$master"
    done

    sort -fu "$master" -o "$master"
}

build_summary() {
    local summary="$OUT/summary.txt"

    {
        echo "SUBDOMAIN ENUMERATION REPORT"
        echo "============================"
        echo
        echo "Version : $VERSION"
        echo "UTC     : $(date -u '+%Y-%m-%d %H:%M:%S')"
        echo "Tool    : Subfinder"
        echo
        echo "Targets : ${#TARGETS[@]}"
        echo

        for domain in "${TARGETS[@]}"; do
            local hosts="$OUT/$domain/subdomains.txt"
            local dns="$OUT/$domain/dns.txt"

            echo "TARGET: $domain"
            echo "  Hosts: $( [[ -f "$hosts" ]] && wc -l < "$hosts" || echo 0 )"

            if (( RESOLVE )); then
                echo "  DNS:   $( [[ -f "$dns" ]] && wc -l < "$dns" || echo 0 )"
            fi

            echo
        done

        echo "TOTAL UNIQUE HOSTS"
        echo "------------------"
        echo "$(wc -l < "$OUT/all-subdomains.txt")"
    } > "$summary"
}

main() {
    local OPTIND=1 opt

    while getopts ":f:o:riqhv" opt; do
        case "$opt" in
            f)
                TARGET_FILE="$OPTARG"
                ;;
            o)
                OUT="$OPTARG"
                ;;
            r)
                RESOLVE=1
                ;;
            i)
                INSTALL_MISSING=1
                ;;
            q)
                QUIET=1
                ;;
            h)
                usage
                exit 0
                ;;
            v)
                printf '%s v%s\n' "$SCRIPT_NAME" "$VERSION"
                exit 0
                ;;
            :)
                die "Option -$OPTARG requires an argument"
                ;;
            \?)
                die "Unknown option: -$OPTARG"
                ;;
        esac
    done

    shift $((OPTIND - 1))

    need_command awk
    need_command sed
    need_command grep
    need_command sort
    need_command mktemp

    if (( RESOLVE )); then
        need_command dig
    fi

    load_targets "$@"

    prepare_output

    TMP="$(mktemp -d)"

    SUBFINDER_BIN="$(setup_subfinder)"
    validate_subfinder "$SUBFINDER_BIN"

    log "Subfinder: $SUBFINDER_BIN"
    log "Targets: ${#TARGETS[@]}"
    log "Output: $OUT"

    local failed=0
    local target

    for target in "${TARGETS[@]}"; do
        if ! enumerate_target "$target"; then
            failed=$((failed + 1))
        fi
    done

    build_master
    build_summary

    echo
    echo "============================================"
    echo " Enumeration complete"
    echo "============================================"
    echo
    echo "Targets        : ${#TARGETS[@]}"
    echo "Unique hosts   : $(wc -l < "$OUT/all-subdomains.txt")"
    echo "Failed targets : $failed"
    echo
    echo "Combined hosts : $OUT/all-subdomains.txt"
    echo "Summary        : $OUT/summary.txt"
    echo

    if (( failed > 0 )); then
        exit 2
    fi
}

main "$@"
