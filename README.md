# Dabira Agent Installation

Official installation scripts for the Dabira Database Agent.

## Quick Install

### Linux / macOS
```bash
curl -fsSL https://install.dabira.com/install.sh | bash
```

### Windows
```powershell
# Download the Windows installer
Invoke-WebRequest -Uri "https://github.com/dabira/agent-server/releases/latest/download/dabira-agent-windows-x86_64.exe" -OutFile "dabira-agent.exe"

# Move to a directory in your PATH
Move-Item dabira-agent.exe C:\Windows\System32\
```

## Manual Installation

### Download Binaries

Download the appropriate binary for your platform:

| Platform | Architecture | Download Link |
|----------|--------------|---------------|
| Linux | x86_64 | [dabira-agent-linux-x86_64](https://github.com/dabira/agent-server/releases/latest/download/dabira-agent-linux-x86_64) |
| Linux | ARM64 | [dabira-agent-linux-aarch64](https://github.com/dabira/agent-server/releases/latest/download/dabira-agent-linux-aarch64) |
| macOS | Intel | [dabira-agent-macos-x86_64](https://github.com/dabira/agent-server/releases/latest/download/dabira-agent-macos-x86_64) |
| macOS | Apple Silicon | [dabira-agent-macos-aarch64](https://github.com/dabira/agent-server/releases/latest/
download/dabira-agent-macos-aarch64) |
| Windows | x86_64 | dabira-agent-windows-x86_64.exe |


# Install Manually

# Download (example for Linux x86_64)
curl -LO https://github.com/dabira/agent-server/releases/latest/download/dabira-agent-linux-x86_64

# Make executable
chmod +x dabira-agent-linux-x86_64

# Move to PATH
sudo mv dabira-agent-linux-x86_64 /usr/local/bin/dabira-agent

# Verify
dabira-agent --version

# Download binary and checksum
curl -LO https://github.com/dabira/agent-server/releases/latest/download/dabira-agent-linux-x86_64
curl -LO https://github.com/dabira/agent-server/releases/latest/download/dabira-agent-linux-x86_64.sha256

# Verify
sha256sum -c dabira-agent-linux-x86_64.sha256


# Install v1.0.0 specifically
curl -fsSL https://install.dabira.com/install.sh | bash -s -- --version v1.0.0

# System Requirements

Operating System: Linux (glibc 2.27+), macOS 10.15+, Windows 10+
Architecture: x86_64 or ARM64
Memory: 128 MB minimum
Disk: 50 MB for binary

# Getting Started
After installation:
bash# Configure agent
dabira-agent setup

# Check status
dabira-agent status

# View help
dabira-agent --help

# Uninstall
bashcurl -fsSL https://install.dabira.com/uninstall.sh | bash

# Troubleshooting
Binary not in PATH
Add /usr/local/bin to your PATH:
bashexport PATH="/usr/local/bin:$PATH"
Add to your shell profile (~/.bashrc, ~/.zshrc, etc.) to make it permanent.
Permission Denied
The installation script needs write access to /usr/local/bin. If you get permission errors:
bash# Make /usr/local/bin writable
sudo chmod 755 /usr/local/bin

# Or install to user directory
mkdir -p ~/.local/bin
mv dabira-agent ~/.local/bin/
export PATH="$HOME/.local/bin:$PATH"
macOS: "Cannot be opened because the developer cannot be verified"
bash# Remove quarantine attribute
xattr -d com.apple.quarantine /usr/local/bin/dabira-agent
```

### Windows: SmartScreen Warning

The binary is not yet code-signed. Click "More info" then "Run anyway".

## Support

- **Documentation**: https://docs.dabira.com
- **Issues**: https://github.com/dabira/agent-server/issues
- **Email**: support@dabira.com

## License

Proprietary - See [LICENSE](../LICENSE)
```

---

