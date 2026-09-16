#!/usr/bin/env bash
#
# Subenum
# Production-ready passive subdomain enumeration
#
# Made By Taylor Christian Newsome
#
# Repository
# https://github.com/SleepTheGod/Subenum
#

set -Eeuo pipefail
IFS=$'\n\t'

VERSION="2.0.1"
PROGRAM="Subenum"
AUTHOR="Taylor Christian Newsome"

OUT="${HOME}/subenum-results"
TARGET_FILE=""
RESOLVE=0
QUIET=0
INSTALL_MISSING=0

declare -a TARGETS=()

TMP_DIR=""

cleanup() {
    [[ -n "${TMP_DIR:-}" && -d "$TMP_DIR" ]] && rm -rf -- "$TMP_DIR"
}

trap cleanup EXIT
trap 'printf "\n[!] Interrupted\n" >&2; exit 130' INT TERM

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------

if [[ -t 1 ]]; then
    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    RED=$'\033[31m'
    GREEN=$'\033[32m'
    YELLOW=$'\033[33m'
    CYAN=$'\033[36m'
    RESET=$'\033[0m'
else
    BOLD=""
    DIM=""
    RED=""
    GREEN=""
    YELLOW=""
    CYAN=""
    RESET=""
fi

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------

log() {
    (( QUIET )) && return 0
    printf '%s[+]%s %s\n' "$GREEN" "$RESET" "$*"
}

info() {
    (( QUIET )) && return 0
    printf '%s[*]%s %s\n' "$CYAN" "$RESET" "$*"
}

warn() {
    printf '%s[!]%s %s\n' "$YELLOW" "$RESET" "$*" >&2
}

die() {
    printf '%s[!]%s %s\n' "$RED" "$RESET" "$*" >&2
    exit 1
}

# ------------------------------------------------------------
# Help
# ------------------------------------------------------------

show_help() {
    cat <<EOF

${BOLD}Subenum${RESET} ${VERSION}

Production-ready passive subdomain enumeration

${DIM}Made By Taylor Christian Newsome${RESET}

Usage

  $0 [options] domain [domain ...]
  $0 [options] -f target-file

Options

  -f FILE       Read targets from a file
  -o DIR        Set the output directory
  -r            Resolve discovered hosts to IP addresses
  -i            Install Subfinder automatically if missing
  -q            Quiet mode
  -h            Show this help
  --help        Show this help
  -v            Show version
  --version     Show version

Examples

  $0 example.com
  $0 -r example.com
  $0 example.com example.org example.net
  $0 -f targets.txt
  $0 -f targets.txt -r
  $0 -o /opt/recon example.com
  $0 -i example.com

Output

  subenum-results/
  ├── all-subdomains.txt
  ├── all-subdomains-ip.txt
  ├── summary.txt
  └── example.com/
      ├── raw/
      │   └── subfinder.raw.txt
      ├── hosts/
      │   └── subdomains.txt
      ├── dns/
      │   ├── subdomains-ip.txt
      │   ├── resolved-hosts.txt
      │   └── unresolved-hosts.txt
      └── summary.txt

IP mapping with -r

  api.example.com        192.0.2.10
  mail.example.com       192.0.2.20
  www.example.com        192.0.2.30

Requirements

  Bash
  ProjectDiscovery Subfinder

DNS resolution with -r additionally requires

  dig
  cut
  comm

Repository

  https://github.com/SleepTheGod/Subenum

Authorization

  Use this tool only against domains you own or are authorized
  to assess.

EOF
}

show_version() {
    printf '%s %s\n' "$PROGRAM" "$VERSION"
    printf 'Made By %s\n' "$AUTHOR"
}

# ------------------------------------------------------------
# Dependencies
# ------------------------------------------------------------

need_command() {
    command -v "$1" >/dev/null 2>&1 ||
        die "Required command not found $1"
}

# ------------------------------------------------------------
# Domain normalization
# ------------------------------------------------------------

normalize_domain() {
    local value="$1"

    value="${value//$'\r'/}"

    value="$(printf '%s' "$value" |
        sed -E \
            's/^[[:space:]]+//;
             s/[[:space:]]+$//;
             s#^[[:alpha:]][[:alnum:]+.-]*://##;
             s#/.*$##;
             s/\?.*$//;
             s/#.*$//;
             s/\.$//')"

    value="${value%%:*}"

    printf '%s' "$value" |
        tr '[:upper:]' '[:lower:]'
}

# ------------------------------------------------------------
# Domain validation
# ------------------------------------------------------------

valid_domain() {
    local domain="$1"

    [[ -n "$domain" ]] || return 1
    [[ ${#domain} -le 253 ]] || return 1
    [[ "$domain" == *.* ]] || return 1
    [[ "$domain" != *..* ]] || return 1

    [[ "$domain" =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$ ]] ||
        return 1

    return 0
}

# ------------------------------------------------------------
# Targets
# ------------------------------------------------------------

load_targets() {
    local line
    local domain
    local arg

    if [[ -n "$TARGET_FILE" ]]; then

        [[ -f "$TARGET_FILE" ]] ||
            die "Target file not found $TARGET_FILE"

        while IFS= read -r line || [[ -n "$line" ]]; do

            line="${line%%#*}"
            domain="$(normalize_domain "$line")"

            [[ -z "$domain" ]] && continue

            if valid_domain "$domain"; then
                TARGETS+=("$domain")
            else
                warn "Skipping invalid target $line"
            fi

        done < "$TARGET_FILE"
    fi

    for arg in "$@"; do

        domain="$(normalize_domain "$arg")"

        if valid_domain "$domain"; then
            TARGETS+=("$domain")
        else
            warn "Skipping invalid target $arg"
        fi

    done

    [[ ${#TARGETS[@]} -gt 0 ]] ||
        die "No valid targets supplied"

    mapfile -t TARGETS < <(
        printf '%s\n' "${TARGETS[@]}" |
            sort -fu
    )
}

# ------------------------------------------------------------
# Find Subfinder
# ------------------------------------------------------------

find_subfinder() {
    local candidate
    local go_path

    if command -v subfinder >/dev/null 2>&1; then
        command -v subfinder
        return 0
    fi

    if command -v go >/dev/null 2>&1; then

        go_path="$(go env GOPATH 2>/dev/null || true)"

        if [[ -n "$go_path" &&
              -x "$go_path/bin/subfinder" ]]; then

            printf '%s\n' "$go_path/bin/subfinder"
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

# ------------------------------------------------------------
# Install Subfinder
# ------------------------------------------------------------

install_subfinder() {
    local go_cmd=""
    local go_path=""

    if command -v go >/dev/null 2>&1; then
        go_cmd="$(command -v go)"
    elif [[ -x "/usr/local/go/bin/go" ]]; then
        go_cmd="/usr/local/go/bin/go"
        export PATH="/usr/local/go/bin:$PATH"
    else
        die "Go is required to automatically install Subfinder"
    fi

    log "Using Go $go_cmd"
    log "Installing Subfinder"

    if ! "$go_cmd" install \
        github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    then
        die "Subfinder installation failed"
    fi

    go_path="$("$go_cmd" env GOPATH)"

    export PATH="$go_path/bin:$PATH"

    [[ -x "$go_path/bin/subfinder" ]] ||
        die "Subfinder installation completed but binary was not found"

    printf '%s\n' "$go_path/bin/subfinder"
}

setup_subfinder() {
    local binary

    binary="$(find_subfinder 2>/dev/null || true)"

    if [[ -n "$binary" ]]; then
        printf '%s\n' "$binary"
        return 0
    fi

    if (( INSTALL_MISSING )); then
        install_subfinder
        return 0
    fi

    cat >&2 <<EOF

${RED}[!] Subfinder was not found${RESET}

Install it with

  go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

Or let Subenum install it

  $0 -i example.com

EOF

    exit 1
}

# ------------------------------------------------------------
# Prepare target
# ------------------------------------------------------------

prepare_target() {
    local domain="$1"
    local target_dir="$OUT/$domain"

    mkdir -p \
        "$target_dir/raw" \
        "$target_dir/hosts" \
        "$target_dir/dns"
}

# ------------------------------------------------------------
# Resolve DNS
# ------------------------------------------------------------

resolve_hosts() {
    local hosts="$1"
    local output="$2"

    local host
    local ip

    : > "$output"

    while IFS= read -r host; do

        [[ -z "$host" ]] && continue

        while IFS= read -r ip; do

            [[ -z "$ip" ]] && continue

            printf '%s\tA\t%s\n' \
                "$host" \
                "$ip" >> "$output"

        done < <(
            dig +short A "$host" 2>/dev/null |
                grep -E \
                    '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' |
                sort -u
        )

        while IFS= read -r ip; do

            [[ -z "$ip" ]] && continue

            printf '%s\tAAAA\t%s\n' \
                "$host" \
                "$ip" >> "$output"

        done < <(
            dig +short AAAA "$host" 2>/dev/null |
                grep -E ':' |
                sort -u
        )

    done < "$hosts"

    sort -u "$output" -o "$output"
}

# ------------------------------------------------------------
# DNS host classification
# ------------------------------------------------------------

build_dns_host_lists() {
    local hosts="$1"
    local dns="$2"
    local resolved="$3"
    local unresolved="$4"

    : > "$resolved"
    : > "$unresolved"

    if [[ -s "$dns" ]]; then

        cut -f1 "$dns" |
            sort -fu > "$resolved"

    fi

    comm -23 \
        <(sort -fu "$hosts") \
        <(sort -fu "$resolved") \
        > "$unresolved"
}

# ------------------------------------------------------------
# Enumerate target
# ------------------------------------------------------------

enumerate_target() {
    local domain="$1"
    local target_dir="$OUT/$domain"

    local raw_file="$target_dir/raw/subfinder.raw.txt"
    local host_file="$target_dir/hosts/subdomains.txt"
    local dns_file="$target_dir/dns/subdomains-ip.txt"
    local resolved_file="$target_dir/dns/resolved-hosts.txt"
    local unresolved_file="$target_dir/dns/unresolved-hosts.txt"

    prepare_target "$domain"

    : > "$raw_file"
    : > "$host_file"

    log "Enumerating $domain"

    if ! "$SUBFINDER_BIN" \
        -d "$domain" \
        -all \
        -recursive \
        -silent \
        -o "$raw_file"
    then

        warn "Subfinder failed for $domain"
        return 1
    fi

    if [[ ! -s "$raw_file" ]]; then
        warn "No subdomains returned for $domain"
        return 0
    fi

    # --------------------------------------------------------
    # Normalize and strictly enforce domain boundary
    #
    # IMPORTANT
    # This avoids the multiline awk syntax error that caused
    # the previous implementation to return zero hosts.
    # --------------------------------------------------------

    awk -v domain="$domain" '
        {
            gsub(/\r/, "")
            gsub(/^[[:space:]]+|[[:space:]]+$/, "")

            host = tolower($0)
            suffix = "." domain

            if (host == domain) {
                print host
                next
            }

            if (length(host) > length(suffix) && substr(host, length(host) - length(suffix) + 1) == suffix) {
                print host
            }
        }
    ' "$raw_file" |
        sed 's/\.$//' |
        sort -fu > "$host_file"

    local count
    count="$(wc -l < "$host_file")"

    log "$domain discovered $count hosts"

    if (( RESOLVE )); then

        resolve_hosts \
            "$host_file" \
            "$dns_file"

        build_dns_host_lists \
            "$host_file" \
            "$dns_file" \
            "$resolved_file" \
            "$unresolved_file"

        log "$domain resolved $(wc -l < "$resolved_file") hosts"

    fi

    return 0
}

# ------------------------------------------------------------
# Display DNS results
# ------------------------------------------------------------

display_results() {
    local dns="$1"
    local hosts="$2"

    echo
    printf '%s\n' \
        "${BOLD}${CYAN}======================================================================${RESET}"

    printf '%s\n' \
        "${BOLD}                       SUBDOMAIN / IP${RESET}"

    printf '%s\n' \
        "${BOLD}${CYAN}======================================================================${RESET}"

    echo

    printf '%-70s %s\n' "SUBDOMAIN" "IP"

    printf '%-70s %s\n' \
        "----------------------------------------------------------------------" \
        "----------------"

    if [[ -s "$dns" ]]; then

        awk -F '\t' '
            {
                printf "%-70s %s\n", $1, $3
            }
        ' "$dns"

    fi

    while IFS= read -r unresolved_host; do

        [[ -z "$unresolved_host" ]] && continue

        printf '%-70s %s\n' \
            "$unresolved_host" \
            "NO DNS RECORD"

    done < <(
        comm -23 \
            <(sort -fu "$hosts") \
            <(cut -f1 "$dns" 2>/dev/null | sort -fu)
    )

    echo
}

# ------------------------------------------------------------
# Combined results
# ------------------------------------------------------------

build_combined_results() {
    local combined_hosts="$OUT/all-subdomains.txt"
    local combined_ips="$OUT/all-subdomains-ip.txt"

    : > "$combined_hosts"
    : > "$combined_ips"

    local target
    local hosts
    local dns

    for target in "${TARGETS[@]}"; do

        hosts="$OUT/$target/hosts/subdomains.txt"
        dns="$OUT/$target/dns/subdomains-ip.txt"

        [[ -f "$hosts" ]] &&
            cat "$hosts" >> "$combined_hosts"

        [[ -f "$dns" ]] &&
            cat "$dns" >> "$combined_ips"

    done

    sort -fu \
        "$combined_hosts" \
        -o "$combined_hosts"

    sort -u \
        "$combined_ips" \
        -o "$combined_ips"
}

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

build_summary() {
    local summary="$OUT/summary.txt"

    {
        echo "SUBENUM REPORT"
        echo "=============="
        echo
        echo "Program"
        echo "$PROGRAM"
        echo
        echo "Version"
        echo "$VERSION"
        echo
        echo "Made By"
        echo "$AUTHOR"
        echo
        echo "Generated UTC"
        date -u '+%Y-%m-%d %H:%M:%S'
        echo
        echo "Targets"
        echo "${#TARGETS[@]}"
        echo

        local target
        local hosts
        local dns
        local resolved
        local unresolved

        for target in "${TARGETS[@]}"; do

            hosts="$OUT/$target/hosts/subdomains.txt"
            dns="$OUT/$target/dns/subdomains-ip.txt"
            resolved="$OUT/$target/dns/resolved-hosts.txt"
            unresolved="$OUT/$target/dns/unresolved-hosts.txt"

            echo "Target"
            echo "$target"

            echo "Subdomains"

            if [[ -f "$hosts" ]]; then
                wc -l < "$hosts"
            else
                echo "0"
            fi

            if (( RESOLVE )); then

                echo "Resolved hosts"

                if [[ -f "$resolved" ]]; then
                    wc -l < "$resolved"
                else
                    echo "0"
                fi

                echo "Unresolved hosts"

                if [[ -f "$unresolved" ]]; then
                    wc -l < "$unresolved"
                else
                    echo "0"
                fi

                echo "DNS records"

                if [[ -f "$dns" ]]; then
                    wc -l < "$dns"
                else
                    echo "0"
                fi

            fi

            echo

        done

        echo "Combined subdomains"

        if [[ -f "$OUT/all-subdomains.txt" ]]; then
            wc -l < "$OUT/all-subdomains.txt"
        else
            echo "0"
        fi

        if (( RESOLVE )); then

            echo
            echo "Combined DNS mappings"

            if [[ -f "$OUT/all-subdomains-ip.txt" ]]; then
                wc -l < "$OUT/all-subdomains-ip.txt"
            else
                echo "0"
            fi

        fi

    } > "$summary"
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

main() {

    local positional=()
    local arg

    while [[ $# -gt 0 ]]; do

        case "$1" in

            -h|--help)
                show_help
                exit 0
                ;;

            -v|--version)
                show_version
                exit 0
                ;;

            -f)
                [[ $# -ge 2 ]] ||
                    die "-f requires a file"

                TARGET_FILE="$2"
                shift 2
                ;;

            --file=*)
                TARGET_FILE="${1#*=}"
                shift
                ;;

            -o)
                [[ $# -ge 2 ]] ||
                    die "-o requires a directory"

                OUT="$2"
                shift 2
                ;;

            --output=*)
                OUT="${1#*=}"
                shift
                ;;

            -r|--resolve)
                RESOLVE=1
                shift
                ;;

            -i|--install)
                INSTALL_MISSING=1
                shift
                ;;

            -q|--quiet)
                QUIET=1
                shift
                ;;

            --)
                shift

                while [[ $# -gt 0 ]]; do
                    positional+=("$1")
                    shift
                done

                ;;

            -*)
                die "Unknown option $1"
                ;;

            *)
                positional+=("$1")
                shift
                ;;

        esac

    done

    # --------------------------------------------------------
    # Dependencies
    # --------------------------------------------------------

    need_command awk
    need_command sed
    need_command grep
    need_command sort
    need_command tr
    need_command mkdir
    need_command tee
    need_command mktemp
    need_command date
    need_command wc

    if (( RESOLVE )); then
        need_command dig
        need_command cut
        need_command comm
    fi

    # --------------------------------------------------------
    # Targets
    # --------------------------------------------------------

    load_targets "${positional[@]}"

    # --------------------------------------------------------
    # Output
    # --------------------------------------------------------

    mkdir -p "$OUT" ||
        die "Unable to create output directory $OUT"

    [[ -w "$OUT" ]] ||
        die "Output directory is not writable $OUT"

    TMP_DIR="$(mktemp -d)"

    # --------------------------------------------------------
    # Subfinder
    # --------------------------------------------------------

    SUBFINDER_BIN="$(setup_subfinder)"

    [[ -x "$SUBFINDER_BIN" ]] ||
        die "Subfinder executable is not usable $SUBFINDER_BIN"

    # --------------------------------------------------------
    # Banner
    # --------------------------------------------------------

    if (( ! QUIET )); then

        echo

        printf '%s\n' \
            "${BOLD}${CYAN}======================================================================${RESET}"

        printf '%s\n' \
            "${BOLD}                              SUBENUM${RESET}"

        printf '%s\n' \
            "${DIM}              Passive Subdomain Enumeration${RESET}"

        printf '%s\n' \
            "${DIM}              Made By Taylor Christian Newsome${RESET}"

        printf '%s\n' \
            "${BOLD}${CYAN}======================================================================${RESET}"

        echo

        printf '%-20s %s\n' \
            "Version" \
            "$VERSION"

        printf '%-20s %s\n' \
            "Subfinder" \
            "$SUBFINDER_BIN"

        printf '%-20s %s\n' \
            "Targets" \
            "${#TARGETS[@]}"

        printf '%-20s %s\n' \
            "Output" \
            "$OUT"

        printf '%-20s %s\n' \
            "DNS Resolution" \
            "$([[ $RESOLVE -eq 1 ]] && echo enabled || echo disabled)"

        echo

    fi

    # --------------------------------------------------------
    # Enumeration
    # --------------------------------------------------------

    local failed=0
    local target

    for target in "${TARGETS[@]}"; do

        if ! enumerate_target "$target"; then
            failed=$((failed + 1))
        fi

    done

    # --------------------------------------------------------
    # Combined output
    # --------------------------------------------------------

    build_combined_results
    build_summary

    # --------------------------------------------------------
    # Display DNS mappings
    # --------------------------------------------------------

    if (( RESOLVE )); then

        for target in "${TARGETS[@]}"; do

            local target_dns="$OUT/$target/dns/subdomains-ip.txt"
            local target_hosts="$OUT/$target/hosts/subdomains.txt"

            if [[ -f "$target_hosts" ]]; then

                printf '\n%sTarget %s%s\n' \
                    "$BOLD" \
                    "$target" \
                    "$RESET"

                display_results \
                    "$target_dns" \
                    "$target_hosts"

            fi

        done

    fi

    # --------------------------------------------------------
    # Final report
    # --------------------------------------------------------

    echo

    printf '%s\n' \
        "${BOLD}${GREEN}======================================================================${RESET}"

    printf '%s\n' \
        "${BOLD}                         ENUMERATION COMPLETE${RESET}"

    printf '%s\n' \
        "${BOLD}${GREEN}======================================================================${RESET}"

    echo

    printf '%-25s %s\n' \
        "Targets" \
        "${#TARGETS[@]}"

    printf '%-25s %s\n' \
        "Unique subdomains" \
        "$(wc -l < "$OUT/all-subdomains.txt")"

    if (( RESOLVE )); then

        printf '%-25s %s\n' \
            "DNS mappings" \
            "$(wc -l < "$OUT/all-subdomains-ip.txt")"

    fi

    printf '%-25s %s\n' \
        "Failed targets" \
        "$failed"

    echo

    printf '%-25s %s\n' \
        "All subdomains" \
        "$OUT/all-subdomains.txt"

    if (( RESOLVE )); then

        printf '%-25s %s\n' \
            "Subdomain IP map" \
            "$OUT/all-subdomains-ip.txt"

    fi

    printf '%-25s %s\n' \
        "Summary" \
        "$OUT/summary.txt"

    echo

    printf '%s\n' \
        "${DIM}Made By Taylor Christian Newsome${RESET}"

    echo

    if (( failed > 0 )); then
        exit 2
    fi
}

main "$@"
