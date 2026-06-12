# SecScan

Security scanner for Ubuntu — runs rootkit checks and makes sense of the results.

## What It Does

Runs two rootkit scanners and classifies findings by severity:

1. **rkhunter** — rootkit and malware scan
2. **chkrootkit** — additional rootkit detection

Then it:
- Filters known false positives (safe dotfiles, legitimate WiFi services)
- Classifies findings: Critical → Warning → Info
- Shows remediation steps where needed
- Logs everything with timestamps

## Why

Running rkhunter and chkrootkit is easy. Interpreting their output is not. A raw scan full of "WARNING" on known-safe files isn't useful. This tool shows only what matters.

## Requirements

- Ubuntu (tested on 22.04+)
- `sudo` access
- `rkhunter` and `chkrootkit` installed

```bash
sudo apt install rkhunter chkrootkit
```

## Usage

```bash
# Clone
git clone https://github.com/AhmadMWaddah/SecScan.git
cd SecScan

# Make executable
chmod +x SecScan.sh

# Run
./SecScan.sh
```

## Help

```bash
./SecScan.sh help
```

## Severity Levels

| Level | Color | Meaning |
|-------|-------|---------|
| **CRITICAL** | Red | Immediate action required |
| **WARNING** | Yellow | Review and take action |
| **INFO** | Cyan | Informational — no action needed |

## Project Structure

```
SecScan/
├── SecScan.sh           # Main entry point
├── lib/
│   ├── colors.sh        # Terminal colors
│   ├── runner.sh        # Module loader
│   ├── state.sh         # State tracking (severity levels)
│   ├── ui.sh            # Print functions
│   └── utils.sh         # Utility functions
└── modules/
    └── secscan.sh       # rkhunter + chkrootkit scanning
```

## License

MIT
