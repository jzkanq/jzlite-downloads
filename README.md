# JZLite 1.0.5 tester guide

JZLite is currently an **unsigned experimental test build** for compatible ARM64
modems with root ADB access. The source code is private and proprietary.

## Before you begin

You need:

- a Windows 10 or Windows 11 computer;
- the supported modem connected by USB;
- working ADB/root access to the modem;
- a JZLite licence key made for that modem's factory MAC address;
- at least 20 MiB of free modem memory for installation;
- a recovery method in case the modem loses connectivity.

Windows displays **Unknown publisher** because this free test build is not
Authenticode-signed. Do not disable antivirus globally. Stop if the downloaded
file does not pass the checksum check.

## Easy installation

1. Connect the modem to the computer by USB.
2. Open the Start menu, search for **PowerShell**, and open it.
3. Copy the 1-line command below, paste it into PowerShell, and press Enter:

```powershell
irm https://raw.githubusercontent.com/jzkanq/jzlite-downloads/main/install.ps1 | iex
```

Or for manual download and hash verification:

```powershell
$folder = Join-Path $env:USERPROFILE "Downloads\JZLite-1.0.5"
if (Test-Path $folder) { throw "Delete the old $folder folder first, then try again." }
New-Item -ItemType Directory -Path $folder | Out-Null
Set-Location $folder
curl.exe -fSL "https://github.com/jzkanq/jzlite-downloads/releases/download/v1.0.5/JZLite-1.0.5-UNSIGNED-EXPERIMENTAL.tgz" -o JZLite.tgz
if ((Get-FileHash .\JZLite.tgz -Algorithm SHA256).Hash.ToLowerInvariant() -ne "ab7265cb7b73bf0d6cf15ad6a94d694227c4774c053f7f45868ba757e56de36e") { throw "Checksum mismatch. Do not run this download." }
tar.exe -xzf .\JZLite.tgz
.\Verify-JZLite.ps1 -ExtractedFolder . -AllowUnsignedExperimental
.\Install-JZLite.bat
```

The checksum line protects testers from a damaged or replaced download. Do not
remove it from the command.

The repository also contains [`installer.bat`](installer.bat), which performs
the same HTTPS download, archive SHA-256 check, internal manifest verification,
extraction, and temporary installation.

## Installer questions

The installer will:

1. detect the modem, request `adb root` when needed, and verify the architecture,
   root shell, and factory MAC candidate;
2. ask for the JZLite licence key in the CMD window;
3. activate and verify the licence;
4. ask for a factory-administrator password;
5. deploy the temporary JZLite service and perform a health check.

Use a new administrator password with at least 12 characters. Do not reuse an
email, banking, Wi-Fi, or social-media password. Never send anyone your licence
key, administrator password, VLESS UUID, or subscription URL.

## Open JZLite

When installation succeeds, connect to the modem's LAN/Wi-Fi and open the JZLite
HTTPS address printed by the installer. It uses the modem's current
LAN/default-gateway IP plus port `5443`, for example
`https://192.168.8.1:5443`.

The modem creates its own certificate, so the browser will show a certificate
warning. Compare the SHA-256 certificate fingerprint shown by the installer
before continuing. Port `5000` is retained only for health checks and safe
redirects; passwords are never accepted over plaintext HTTP.

Sign in with the factory-administrator password entered during installation.
Import or create a profile and run diagnostics. Whole-modem VPN stays active
until manually stopped or the modem reboots. The main **Connect whole modem** button
tests enabled profiles and starts guarded whole-modem routing automatically.
Health and failure rollback remain armed.

Settings includes an optional **Block ads and trackers with DNS** switch. It
uses AdGuard DNS during whole-modem routing and is off by default. Disconnect
and reconnect after changing it. DNS filtering cannot reliably remove video ads
or advertisements served from the same domains as application content.

## Optional persistent installation

First prove temporary mode works. Then reopen CMD in the extracted folder and run:

```bat
Install-JZLite.bat --install-persistent
```

If XLite is currently installed, use this instead. It backs up XLite and imports
its active VLESS profile before switching the verified firmware boot slot:

```bat
Install-JZLite.bat --migrate-xlite
```

Persistent settings include an optional **Connect after reboot** switch. It is
off by default. To upgrade later, use `Install-JZLite.bat --upgrade-persistent`.
To remove JZLite and restore the XLite backup, use
`Install-JZLite.bat --uninstall`.

## Remove or retry

Temporary JZLite disappears after a modem reboot. To replace a temporary test
copy, run the same installer again with `--clean-install`. Persistent JZLite must
be removed with `--uninstall`. Do not manually delete modem files, firewall rules
or routing rules.

If activation is rejected, check that the key was issued for the detected factory
MAC. If the checksum fails, delete the download and report it—do not continue.

## Official archive checksum

```text
faf0bce4d9db77f93a82e052e2b63eb2338a0aa5251f2a56732c925336a2b68e
```

[View the JZLite 1.0.3 public release](https://github.com/jzkanq/jzlite-downloads/releases/tag/v1.0.3).
