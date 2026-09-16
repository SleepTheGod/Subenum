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
