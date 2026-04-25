# How to Install Godot and Run the Game

This guide walks you through installing **Godot 4.3+** and running the project
from [github.com/santapong/MMORPG](https://github.com/santapong/MMORPG). The
project targets the **Forward+** renderer (after the 3D migration) and uses
**GDScript** only — no .NET/Mono required.

> Always download the **Standard** build, **not** the .NET build.

---

## Windows

1. Open [godotengine.org/download/windows](https://godotengine.org/download/windows)
   and download **Godot Engine — Standard** (64-bit).
2. Right-click the `.zip` → **Extract All** to a permanent folder
   (e.g. `C:\Godot\`).
3. Double-click `Godot_v4.3-stable_win64.exe`. If **SmartScreen** warns
   *"Windows protected your PC"*, click **More info → Run anyway**.
4. Right-click the running Godot icon in the taskbar → **Pin to taskbar**.
5. *(Optional)* Add Godot to `PATH`: **Settings → System → About → Advanced
   system settings → Environment Variables**, edit `Path`, add the folder that
   holds the `.exe`. You may rename the executable to `godot.exe` for shorter
   commands.

## macOS

1. Open [godotengine.org/download/macos](https://godotengine.org/download/macos)
   and download the **Standard** build. The `.dmg` is a Universal binary that
   runs on both **Apple Silicon (M1/M2/M3/M4)** and **Intel** Macs.
2. Open the `.dmg` and drag **Godot.app** into `/Applications`.
3. First launch fails with *"Godot.app can't be opened because Apple cannot
   check it for malicious software."* Fix it one of two ways:
   - **Finder:** right-click **Godot.app → Open**, then click **Open** again.
   - **Terminal:** `xattr -d com.apple.quarantine /Applications/Godot.app`
4. *(Optional)* Symlink the CLI:
   ```bash
   sudo ln -s /Applications/Godot.app/Contents/MacOS/Godot /usr/local/bin/godot
   ```

## Linux

1. Download the **Standard** Linux x86_64 `.zip` from
   [godotengine.org/download/linux](https://godotengine.org/download/linux).
2. Extract, mark executable, and run:
   ```bash
   unzip Godot_v4.3-stable_linux.x86_64.zip
   chmod +x Godot_v4.3-stable_linux.x86_64
   ./Godot_v4.3-stable_linux.x86_64
   ```
3. **Flatpak (recommended on most distros):**
   ```bash
   flatpak install flathub org.godotengine.Godot
   ```
4. **Distro packages** (may lag the official release — verify the version):
   - Debian/Ubuntu: `sudo apt install godot4`
   - Arch: `sudo pacman -S godot`
   - Fedora: `sudo dnf install godot`
5. **Wayland vs X11:** Godot 4.3 supports Wayland natively. If you see
   flickering or input issues, force X11:
   `./Godot_v4.3-stable_linux.x86_64 --display-driver x11`

## Advanced: Build from Source

For bleeding-edge features, clone
[github.com/godotengine/godot](https://github.com/godotengine/godot) and follow
the [official compile docs](https://docs.godotengine.org/en/stable/contributing/development/compiling/).
Requires SCons, Python 3, and a C++17 toolchain. Not needed for normal play.

---

## Verify the Install

```bash
godot --version
```

Should print `4.3.stable` or newer.

## Clone and Open the Project

1. Clone the repo:
   ```bash
   git clone https://github.com/santapong/MMORPG.git
   ```
2. Launch Godot. In the **Project Manager**, click **Import**.
3. Browse to `MMORPG/godot_project/project.godot` and click
   **Import & Edit**.
4. The **first import takes 1–2 minutes** while assets reimport and shaders
   cache. Subsequent loads are fast.

## Run the Game

- In the editor: press **F5** (Run Project). Set a main scene if prompted.
- From the CLI:
  ```bash
  godot --path godot_project/
  ```

## Common First-Run Issues

- **"Vulkan not supported" / black window** — Open **Project → Project
  Settings → Rendering → Renderer** and switch from **Forward+** to **Mobile**
  or **Compatibility**. Update GPU drivers if possible.
- **Shader compile stutter on first play** — Normal; shaders cache to
  `.godot/` after the first run.
- **"Your video card driver does not support any of the supported Vulkan
  versions"** — Update drivers, or relaunch with
  `--rendering-driver opengl3`.

## Optional: Blender for GLTF Character Models

The 3D migration uses GLTF/`.blend` models for characters and props.

1. Install **Blender 4.x** from [blender.org](https://www.blender.org/download/).
2. In Godot: **Editor → Editor Settings → FileSystem → Import → Blender →
   Blender Path** — point at the `blender` executable so `.blend` files
   import directly.

## Exporting a Build

1. **Project → Export → Manage Export Templates → Download and Install**
   (matches your engine version).
2. Add a preset (Windows Desktop, Linux/X11, macOS, Web, Android…).
3. Click **Export Project**, choose an output path, and uncheck **Export With
   Debug** for release builds.

---

You're ready to develop. For game architecture, see `README.md`. For the
ongoing 2D → 3D rewrite, see `3D_CONVERSION_PLAN.md`.
