# JZLite downloads

This public repository contains **binary releases only**. JZLite source code is
private and proprietary.

## Experimental build warning

JZLite 0.18.2-test is experimental. `JZLite-Setup.exe` is not Authenticode
signed, so Windows displays **Unknown publisher**. It requires root ADB access
and temporarily changes modem routing and firewall state. Test only on compatible
hardware you can recover or replace. Do not disable antivirus globally.

## Download and verify on Windows

```powershell
curl.exe -fL "https://github.com/jzkanq/jzlite-downloads/releases/download/v0.18.2-test/JZLite-0.18.2-test-UNSIGNED-EXPERIMENTAL.tgz" -o JZLite.tgz
if ((Get-FileHash .\JZLite.tgz -Algorithm SHA256).Hash.ToLowerInvariant() -ne "0d118924c8577548ab3531f4957e5b0ec6f5c718ad89b22aa9e045e2ed6a6ea7") { throw "JZLite download checksum mismatch" }
tar.exe -xzf .\JZLite.tgz
```

Only after the checksum succeeds, start the installer from CMD:

```bat
Install-JZLite.bat --clean-install
```

The expected SHA-256 for the archive is:

```text
0d118924c8577548ab3531f4957e5b0ec6f5c718ad89b22aa9e045e2ed6a6ea7
```

Never enter a licence key, password, proxy credential, or modem identifier into
an unofficial script or website.
