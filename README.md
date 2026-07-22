# JZLite experimental tester guide

JZLite is currently an **unsigned experimental test build** for compatible ARM64
modems with root ADB access. The source code is private and proprietary.

## Before you begin

You need:

- a Windows 10 or Windows 11 computer;
- the supported modem connected by USB;
- working ADB/root access to the modem;
- a JZLite licence key made for that modem's factory MAC address;
- at least 52 MiB of free modem memory;
- a recovery method in case the modem loses connectivity.

Windows displays **Unknown publisher** because this free test build is not
Authenticode-signed. Do not disable antivirus globally. Stop if the downloaded
file does not pass the checksum check.

## Easy installation

1. Connect the modem to the computer by USB.
2. Open the Start menu, search for **PowerShell**, and open it.
3. Copy the entire block below, paste it into PowerShell, and press Enter:

```powershell
$folder = Join-Path $env:USERPROFILE "Downloads\JZLite-0.19.0-test"
if (Test-Path $folder) { throw "Delete the old $folder folder first, then try again." }
New-Item -ItemType Directory -Path $folder | Out-Null
Set-Location $folder
curl.exe -fL "https://github.com/jzkanq/jzlite-downloads/releases/download/v0.19.0-test/JZLite-0.19.0-test-UNSIGNED-EXPERIMENTAL.tgz" -o JZLite.tgz
if ((Get-FileHash .\JZLite.tgz -Algorithm SHA256).Hash.ToLowerInvariant() -ne "6ccc9e4700a0779ad90e08ea6697f7641b023a58bfb4fa3cd661f8d1986e3a13") { throw "Checksum mismatch. Do not run this download." }
tar.exe -xzf .\JZLite.tgz
.\Install-JZLite.bat --clean-install
```

The checksum line protects testers from a damaged or replaced download. Do not
remove it from the command.

## Installer questions

The installer will:

1. detect the modem, architecture, root shell, and factory MAC candidate;
2. ask for the JZLite licence key in the CMD window;
3. activate and verify the licence;
4. ask for a factory-administrator password;
5. deploy the temporary JZLite service and perform a health check.

Use a new administrator password with at least 12 characters. Do not reuse an
email, banking, Wi-Fi, or social-media password. Never send anyone your licence
key, administrator password, VLESS UUID, or subscription URL.

## Open JZLite

When installation succeeds, connect to the modem's LAN/Wi-Fi and open the JZLite
address printed by the installer. It uses the modem's current LAN/default-gateway
IP plus port `5000`, for example `http://192.168.8.1:5000`.

Sign in with the factory-administrator password entered during installation.
Import or create a profile and run diagnostics. Whole-modem VPN stays active
until manually stopped or the modem reboots. Health and failure rollback remain
armed, but do not start routing until diagnostics pass.

## Remove or retry

JZLite runs only from temporary modem storage and should disappear after a modem
reboot. To replace a running test copy, run the same installer again with
`--clean-install`. Do not manually delete unrelated modem firewall or routing
rules.

If activation is rejected, check that the key was issued for the detected factory
MAC. If the checksum fails, delete the download and report it—do not continue.

## Official archive checksum

```text
6ccc9e4700a0779ad90e08ea6697f7641b023a58bfb4fa3cd661f8d1986e3a13
```
