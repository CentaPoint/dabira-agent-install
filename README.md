# Dabira Agent Installation

Official installation scripts for the Dabira Database Agent.

## Quick Install

### Linux / macOS
```bash
curl -fsSL https://raw.githubusercontent.com/CentaPoint/dabira-agent-install/main/install.sh | bash
```

### Windows
```powershell
Invoke-WebRequest -Uri "https://github.com/CentaPoint/dabira-server-agent/releases/latest/download/dabira-agent-windows-x86_64.exe" -OutFile "dabira-agent.exe"
Move-Item dabira-agent.exe C:\Windows\System32\
```

## Manual Installation

Download the binary for your platform:

| Platform | Architecture | Download Link |
|----------|--------------|---------------|
| Linux | x86_64 | [dabira-agent-linux-x86_64](https://github.com/CentaPoint/dabira-server-agent/releases/latest/download/dabira-agent-linux-x86_64) |
| Linux | ARM64 | [dabira-agent-linux-aarch64](https://github.com/CentaPoint/dabira-server-agent/releases/latest/download/dabira-agent-linux-aarch64) |
| macOS | Intel | [dabira-agent-macos-x86_64](https://github.com/CentaPoint/dabira-server-agent/releases/latest/download/dabira-agent-macos-x86_64) |
| macOS | Apple Silicon | [dabira-agent-macos-aarch64](https://github.com/CentaPoint/dabira-server-agent/releases/latest/download/dabira-agent-macos-aarch64) |
| Windows | x86_64 | [dabira-agent-windows-x86_64.exe](https://github.com/CentaPoint/dabira-server-agent/releases/latest/download/dabira-agent-windows-x86_64.exe) |

Then install:
```bash
# Download (Linux x86_64 example)
curl -LO https://github.com/CentaPoint/dabira-server-agent/releases/latest/download/dabira-agent-linux-x86_64

# Make executable
chmod +x dabira-agent-linux-x86_64

# Install
sudo mv dabira-agent-linux-x86_64 /usr/local/bin/dabira-agent

# Verify
dabira-agent --version
```

## Verify Installation
```bash
# Download checksum
curl -LO https://github.com/CentaPoint/dabira-server-agent/releases/latest/download/dabira-agent-linux-x86_64.sha256

# Verify
sha256sum -c dabira-agent-linux-x86_64.sha256
```

## Getting Started
```bash
# Configure agent
dabira-agent setup

# Check status
dabira-agent status

# View help
dabira-agent --help
```

## System Requirements

- **OS**: Linux (glibc 2.27+), macOS 10.15+, Windows 10+
- **Architecture**: x86_64 or ARM64
- **Memory**: 128 MB minimum
- **Disk**: 50 MB for binary

## Support

- **Documentation**: https://dabira.com/docs
- **Issues**: https://github.com/CentaPoint/dabira-server-agent/issues
- **Email**: aloc.mass@gmail.com