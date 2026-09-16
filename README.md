# Subenum

Production focused passive subdomain enumeration using ProjectDiscovery Subfinder

Subenum provides a clean command line workflow for collecting subdomains across one or more authorized targets, normalizing results, preserving raw enumeration output, and optionally resolving discovered hosts through DNS.

## Features

* Passive subdomain enumeration
* ProjectDiscovery Subfinder integration
* Multiple target support
* Target file support
* Automatic target normalization
* Duplicate removal
* Domain boundary validation
* Optional A record resolution
* Optional AAAA record resolution
* Per target result directories
* Combined hostname output
* Enumeration summary
* Raw Subfinder output preservation
* Automatic Subfinder discovery across common Go installation paths
* Optional Subfinder installation
* Strict Bash error handling
* No port scanning
* No exploitation
* No brute forcing
* No service interaction

## Requirements

* Linux
* Bash
* curl
* awk
* sed
* grep
* sort
* mktemp
* ProjectDiscovery Subfinder

DNS resolution requires

* dig

## Installation

Clone the repository

```bash
git clone https://github.com/SleepTheGod/Subenum.git
cd Subenum
chmod +x subenum.sh
```

Install Subfinder

```bash
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
```

If Go installs Subfinder into the standard Go binary directory

```bash
export PATH="$HOME/go/bin:$PATH"
```

Verify the installation

```bash
subfinder -version
```

## Usage

Single target

```bash
./subenum.sh example.com
```

Multiple targets

```bash
./subenum.sh example.com example.org example.net
```

Target file

```bash
./subenum.sh -f targets.txt
```

Target file with DNS resolution

```bash
./subenum.sh -f targets.txt -r
```

Custom output directory

```bash
./subenum.sh -f targets.txt -r -o /opt/recon
```

Automatically install Subfinder when missing

```bash
./subenum.sh -i example.com
```

Quiet mode

```bash
./subenum.sh -q example.com
```

Display version

```bash
./subenum.sh -v
```

Display help

```bash
./subenum.sh -h
```

## Target Files

Targets can be supplied one per line

```text
example.com
example.org
example.net
```

Comments are supported

```text
example.com
example.org

# Internal assessment target
example.net
```

The script normalizes domains before enumeration and removes duplicate targets.

## Output

The default output directory is

```text
~/subenum-results
```

Results are organized by target

```text
subenum-results/
├── all-subdomains.txt
├── summary.txt
├── example.com/
│   ├── subfinder.raw.txt
│   ├── subdomains.txt
│   └── dns.txt
└── example.org/
    ├── subfinder.raw.txt
    ├── subdomains.txt
    └── dns.txt
```

### Raw Results

`subfinder.raw.txt`

Contains the original Subfinder output for the target.

### Normalized Results

`subdomains.txt`

Contains normalized and deduplicated hostnames belonging to the requested domain.

### DNS Results

`dns.txt`

Created when DNS resolution is enabled.

The format is

```text
hostname    A       address
hostname    AAAA    address
```

### Combined Results

`all-subdomains.txt`

Contains unique normalized results across all requested targets.

### Summary

`summary.txt`

Contains target counts, discovered hostname counts, DNS record counts, execution information, and output locations.

## Options

| Option    | Description                       |
| --------- | --------------------------------- |
| `-f FILE` | Read targets from a file          |
| `-o DIR`  | Set the output directory          |
| `-r`      | Resolve discovered hosts with DNS |
| `-i`      | Install Subfinder when missing    |
| `-q`      | Suppress operational output       |
| `-h`      | Display help                      |
| `-v`      | Display version                   |

## Workflow

Subenum follows a simple collection workflow

```text
Target
  ↓
Input normalization
  ↓
Subfinder enumeration
  ↓
Domain boundary validation
  ↓
Normalization
  ↓
Deduplication
  ↓
Per target storage
  ↓
Optional DNS resolution
  ↓
Combined results
  ↓
Summary
```

The current implementation uses Subfinder as the enumeration engine and keeps discovery results separate from optional DNS observations.

## Security Model

Subenum is designed around passive enumeration.

It does not perform

* Port scanning
* Exploitation
* Credential attacks
* Brute force discovery
* Vulnerability exploitation
* Service interaction

DNS resolution is limited to discovered hostnames when the `-r` option is explicitly enabled.

## Error Handling

The script uses strict Bash execution behavior and validates required dependencies before execution.

It also handles

* Invalid targets
* Missing target files
* Missing dependencies
* Missing Subfinder installations
* Failed enumeration
* Interrupted execution
* Unwritable output directories
* Duplicate targets

Subfinder is searched for through the normal executable path as well as common Go installation locations.

## Examples

Basic enumeration

```bash
./subenum.sh example.com
```

Multiple authorized domains

```bash
./subenum.sh example.com example.org
```

Bulk assessment

```bash
./subenum.sh -f targets.txt
```

Bulk assessment with DNS

```bash
./subenum.sh -f targets.txt -r
```

Custom evidence directory

```bash
./subenum.sh -f targets.txt -r -o ./engagement-results
```

## Authorization

Use Subenum only against domains you own or have explicit authorization to assess.

Historical or passive discovery data can contain stale infrastructure. Treat discovered hostnames as enumeration results rather than proof that an asset is currently operated by the target.

## Project

Repository

```text
https://github.com/SleepTheGod/Subenum
```

## License

See the repository for the applicable license.

## Author

SleepTheGod

GitHub

```text
https://github.com/SleepTheGod
```


# Subenum

Production focused passive subdomain enumeration using ProjectDiscovery Subfinder

Subenum provides a clean command line workflow for collecting subdomains across one or more authorized targets, normalizing results, preserving raw enumeration output, and optionally resolving discovered hosts through DNS.

## Subenum V2

`subenumv2.sh` is the newer production focused implementation.

V2 expands the original workflow with improved command line handling, target normalization, dependency validation, automatic Subfinder discovery, optional Subfinder installation, DNS correlation, resolved and unresolved host tracking, combined reporting, colored terminal output, version reporting, and both short and long help options.

The primary V2 feature is direct hostname to IP correlation when DNS resolution is enabled.

Example

```text
api.example.com                                      192.0.2.10
mail.example.com                                     192.0.2.20
www.example.com                                      192.0.2.30
```

IPv6 records are also supported.

```text
api.example.com                                      2001:db8::10
```

V2 preserves the raw enumeration data while keeping normalized hostnames and DNS observations in separate files.

## Features

* Passive subdomain enumeration
* ProjectDiscovery Subfinder integration
* Multiple target support
* Target file support
* Automatic target normalization
* Duplicate removal
* Domain boundary validation
* Optional A record resolution
* Optional AAAA record resolution
* Direct subdomain to IP correlation
* Resolved host tracking
* Unresolved host tracking
* Per target result directories
* Combined hostname output
* Combined DNS mapping output
* Enumeration summary
* Raw Subfinder output preservation
* Automatic Subfinder discovery across common Go installation paths
* Optional Subfinder installation
* Strict Bash error handling
* Graceful interruption handling
* Colored terminal output
* Quiet mode
* Version information
* `-h` help support
* `--help` support
* `-v` version support
* `--version` support
* No port scanning
* No exploitation
* No brute forcing
* No credential attacks
* No service interaction

## Requirements

Linux

Bash

ProjectDiscovery Subfinder

Standard command line utilities

* awk
* sed
* grep
* sort
* tr
* mkdir
* tee

DNS resolution requires

* dig
* cut
* comm

## Installation

Clone the repository

```bash
git clone https://github.com/SleepTheGod/Subenum.git
cd Subenum
```

Make the scripts executable

```bash
chmod +x subenum.sh
chmod +x subenumv2.sh
```

## Install Subfinder

Install ProjectDiscovery Subfinder through Go

```bash
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
```

If Go installs Subfinder into the standard Go binary directory

```bash
export PATH="$HOME/go/bin:$PATH"
```

Verify the installation

```bash
subfinder -version
```

Subenum V2 also searches common Go installation locations for Subfinder.

If Subfinder is not available, V2 can optionally attempt installation when the `-i` option is supplied.

```bash
./subenumv2.sh -i example.com
```

## Subenum V1

The original implementation remains available as

```text
subenum.sh
```

Basic usage

```bash
./subenum.sh example.com
```

DNS resolution

```bash
./subenum.sh -r example.com
```

## Subenum V2 Usage

Basic enumeration

```bash
./subenumv2.sh example.com
```

Enumeration with DNS resolution

```bash
./subenumv2.sh -r example.com
```

Multiple targets

```bash
./subenumv2.sh example.com example.org example.net
```

Target file

```bash
./subenumv2.sh -f targets.txt
```

Target file with DNS resolution

```bash
./subenumv2.sh -f targets.txt -r
```

Custom output directory

```bash
./subenumv2.sh -o /opt/recon example.com
```

Bulk enumeration with custom output

```bash
./subenumv2.sh -f targets.txt -r -o /opt/recon
```

Automatically install Subfinder when missing

```bash
./subenumv2.sh -i example.com
```

Quiet mode

```bash
./subenumv2.sh -q example.com
```

Display help

```bash
./subenumv2.sh -h
```

Long help option

```bash
./subenumv2.sh --help
```

Display version

```bash
./subenumv2.sh -v
```

Long version option

```bash
./subenumv2.sh --version
```

## V2 Options

| Option         | Description                          |
| -------------- | ------------------------------------ |
| `-f FILE`      | Read targets from a file             |
| `--file=FILE`  | Read targets from a file             |
| `-o DIR`       | Set the output directory             |
| `--output=DIR` | Set the output directory             |
| `-r`           | Resolve discovered hosts through DNS |
| `--resolve`    | Resolve discovered hosts through DNS |
| `-i`           | Install Subfinder when missing       |
| `--install`    | Install Subfinder when missing       |
| `-q`           | Suppress operational output          |
| `--quiet`      | Suppress operational output          |
| `-h`           | Display help                         |
| `--help`       | Display help                         |
| `-v`           | Display version                      |
| `--version`    | Display version                      |

## Target Files

Targets can be supplied one per line

```text
example.com
example.org
example.net
```

Comments are supported

```text
example.com
example.org

# Internal assessment target
example.net
```

V2 removes comments, normalizes target names, validates domains, and removes duplicate targets before enumeration.

## Target Normalization

V2 accepts normalized domain input as well as common URL style input.

For example

```text
example.com
EXAMPLE.COM
example.com.
https://example.com
http://example.com/path
```

The input is normalized before enumeration.

Only valid target domains are passed to the enumeration workflow.

## DNS Correlation

The `-r` option enables DNS resolution.

Each discovered hostname is queried individually for A and AAAA records.

Example terminal output

```text
======================================================================
                       SUBDOMAIN / IP
======================================================================

SUBDOMAIN                                                              IP
----------------------------------------------------------------------  ----------------
api.example.com                                                        192.0.2.10
mail.example.com                                                       192.0.2.20
www.example.com                                                        192.0.2.30
```

If a hostname does not return an A or AAAA record, V2 reports

```text
internal.example.com                                                   NO DNS RECORD
```

This makes the relationship between the discovered hostname and its currently observed DNS address explicit.

## DNS Record Storage

V2 stores DNS observations using a tab separated format

```text
hostname    A       address
hostname    AAAA    address
```

For example

```text
api.example.com    A       192.0.2.10
api.example.com    AAAA    2001:db8::10
```

Multiple addresses for a single hostname are preserved.

## Output

The default output directory is

```text
~/subenum-results
```

V2 organizes results by target

```text
subenum-results/
├── all-subdomains.txt
├── all-subdomains-ip.txt
├── summary.txt
├── example.com/
│   ├── raw/
│   │   └── subfinder.raw.txt
│   ├── hosts/
│   │   └── subdomains.txt
│   └── dns/
│       ├── subdomains-ip.txt
│       ├── resolved-hosts.txt
│       └── unresolved-hosts.txt
└── example.org/
    ├── raw/
    │   └── subfinder.raw.txt
    ├── hosts/
    │   └── subdomains.txt
    └── dns/
        ├── subdomains-ip.txt
        ├── resolved-hosts.txt
        └── unresolved-hosts.txt
```

## Raw Results

`subfinder.raw.txt`

Contains the original output generated by Subfinder for the target.

The raw file is preserved separately from normalized results.

## Normalized Results

`subdomains.txt`

Contains normalized and deduplicated hostnames belonging to the requested domain.

Domain boundary validation prevents unrelated domains from being included in the normalized target results.

## DNS Results

`subdomains-ip.txt`

Contains the hostname, DNS record type, and resolved address.

Example

```text
api.example.com    A       192.0.2.10
mail.example.com   A       192.0.2.20
www.example.com    A       192.0.2.30
```

AAAA records are stored in the same format

```text
api.example.com    AAAA    2001:db8::10
```

## Resolved Hosts

`resolved-hosts.txt`

Contains hostnames for which V2 observed DNS records.

## Unresolved Hosts

`unresolved-hosts.txt`

Contains discovered hostnames for which V2 did not observe an A or AAAA record during the DNS resolution phase.

An unresolved hostname does not necessarily mean that the hostname is invalid or inactive.

DNS configurations can change and different DNS resolvers can return different observations.

## Combined Results

`all-subdomains.txt`

Contains unique normalized subdomains across all requested targets.

`all-subdomains-ip.txt`

Contains combined hostname to DNS address mappings across all requested targets.

## Summary

`summary.txt`

Contains

* Program information
* Version
* Author
* UTC generation time
* Target count
* Per target hostname counts
* Resolved host counts
* Unresolved host counts
* DNS record counts
* Combined result counts

## Workflow

Subenum V2 follows this collection workflow

```text
Target
  ↓
Argument or target file processing
  ↓
Input normalization
  ↓
Target validation
  ↓
Duplicate removal
  ↓
Subfinder discovery
  ↓
Domain boundary validation
  ↓
Hostname normalization
  ↓
Deduplication
  ↓
Per target storage
  ↓
Optional A resolution
  ↓
Optional AAAA resolution
  ↓
Hostname to IP correlation
  ↓
Resolved and unresolved host tracking
  ↓
Combined results
  ↓
Summary
```

## Subenum V1 Compared With V2

| Capability                      | Subenum | Subenum V2 |
| ------------------------------- | ------- | ---------- |
| Passive Subfinder enumeration   | Yes     | Yes        |
| Multiple targets                | Yes     | Yes        |
| Target files                    | Yes     | Yes        |
| Target normalization            | Yes     | Improved   |
| Domain validation               | Yes     | Yes        |
| A resolution                    | Yes     | Yes        |
| AAAA resolution                 | Yes     | Yes        |
| Host to IP correlation          | Yes     | Improved   |
| Resolved host list              | Yes     | Yes        |
| Unresolved host list            | Yes     | Yes        |
| Combined hostname results       | Yes     | Yes        |
| Combined DNS mappings           | Yes     | Yes        |
| Raw enumeration preservation    | Yes     | Yes        |
| Automatic Subfinder discovery   | Yes     | Yes        |
| Optional Subfinder installation | Yes     | Yes        |
| Quiet mode                      | Yes     | Yes        |
| Version option                  | Yes     | Yes        |
| `-h`                            | Yes     | Yes        |
| `--help`                        | Yes     | Yes        |
| `--version`                     | Yes     | Yes        |
| Colored terminal interface      | Limited | Yes        |
| Structured per target output    | Yes     | Yes        |
| Execution summary               | Yes     | Yes        |

## Security Model

Subenum is designed around passive discovery.

The enumeration workflow does not perform

* Port scanning
* Exploitation
* Credential attacks
* Brute force discovery
* Vulnerability exploitation
* Service interaction

When `-r` is enabled, DNS queries are performed against the discovered hostnames.

DNS resolution is therefore an explicit optional step rather than part of passive hostname collection.

## Error Handling

V2 uses strict Bash execution behavior.

It validates dependencies before beginning enumeration and handles

* Invalid domains
* Invalid target files
* Missing target files
* Missing dependencies
* Missing Subfinder installations
* Subfinder execution failures
* Empty enumeration results
* Invalid output directories
* Unwritable output directories
* Duplicate targets
* Interrupted execution

The script also searches for Subfinder through the normal executable path and common Go installation locations.

## Exit Behavior

A successful enumeration returns exit status `0`.

If one or more targets fail during enumeration, V2 completes the remaining targets and returns exit status `2`.

Invalid command line usage or missing required dependencies results in a nonzero failure status.

## Help

V2 includes both short and long help options

```bash
./subenumv2.sh -h
```

```bash
./subenumv2.sh --help
```

The help screen documents the available options, examples, output structure, DNS correlation behavior, requirements, repository, and authorization guidance.

## Examples

Basic enumeration

```bash
./subenumv2.sh example.com
```

DNS correlated enumeration

```bash
./subenumv2.sh -r example.com
```

Multiple authorized domains

```bash
./subenumv2.sh -r example.com example.org
```

Bulk enumeration

```bash
./subenumv2.sh -f targets.txt
```

Bulk enumeration with DNS

```bash
./subenumv2.sh -f targets.txt -r
```

Custom evidence directory

```bash
./subenumv2.sh -f targets.txt -r -o ./engagement-results
```

Automatic Subfinder installation

```bash
./subenumv2.sh -i example.com
```

Quiet execution

```bash
./subenumv2.sh -q example.com
```

## Authorization

Use Subenum only against domains you own or have explicit authorization to assess.

Subenum is intended for authorized security research, asset inventory, reconnaissance, and defensive assessment workflows.

Historical or passive discovery data can contain stale infrastructure.

A discovered hostname should be treated as enumeration data rather than proof that an asset is currently operated by the target.

DNS addresses can also change over time.

## Project

Repository

```text
https://github.com/SleepTheGod/Subenum
```

## Files

The repository contains the original implementation and the newer V2 implementation

```text
Subenum/
├── subenum.sh
├── subenumv2.sh
└── README.md
```

## Author

Made By Taylor Christian Newsome

GitHub

```text
https://github.com/SleepTheGod
```

## License

See the repository for the applicable license.
