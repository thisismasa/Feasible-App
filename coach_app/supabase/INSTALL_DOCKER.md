# Docker Desktop Installation Guide

## Why You Need Docker Desktop

Supabase CLI runs locally using Docker containers. This allows you to:
- ✅ Run Supabase database locally
- ✅ Test changes before deploying
- ✅ Work offline
- ✅ See database results in terminal (so I can help debug!)

## Installation Steps

### Option 1: Download and Install (RECOMMENDED)

1. **Download Docker Desktop:**
   - Go to: https://www.docker.com/products/docker-desktop/
   - Click "Download for Windows"
   - Or direct link: https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe

2. **Run the Installer:**
   - Double-click `Docker Desktop Installer.exe`
   - **IMPORTANT:** Check "Use WSL 2 instead of Hyper-V"
   - Click "OK" and wait for installation
   - Restart your computer when prompted

3. **Start Docker Desktop:**
   - Launch Docker Desktop from Start Menu
   - Wait for it to start (you'll see a whale icon in system tray)
   - Accept the license agreement

4. **Verify Installation:**
   ```bash
   docker --version
   docker compose version
   ```

### Option 2: Winget (If Available)

```bash
winget install Docker.DockerDesktop
```

### Option 3: Scoop (Already Tried - Windows Containers Only)

```bash
scoop install docker
# This only works for Windows containers, NOT for Supabase!
```

## After Docker is Installed

Once Docker Desktop is running, you can:

### 1. Initialize Supabase Local Project

```bash
cd "d:\Users\masathomard\Desktop\Feasible APP v.2\Feasible-App\coach_app"
supabase init
```

### 2. Start Local Supabase

```bash
supabase start
```

This will start:
- PostgreSQL database (local)
- Studio (database UI)
- Auth server
- Storage server
- All Supabase services locally!

### 3. Link to Your Remote Project

```bash
supabase link --project-ref dkdnpceoanwbeulhkvdh
```

### 4. Pull Remote Schema

```bash
supabase db pull
```

This downloads your remote database schema so you can work locally!

## Benefits

With Docker + Supabase CLI, I can:
- ✅ See your database structure
- ✅ Run queries and see results
- ✅ Test fixes locally before deploying
- ✅ Help you debug issues faster

## System Requirements

- Windows 10/11 64-bit (Pro, Enterprise, or Education)
- WSL 2 enabled
- 4GB RAM minimum (8GB recommended)
- Virtualization enabled in BIOS

## Troubleshooting

### WSL 2 Not Installed?

Run in PowerShell (Admin):
```powershell
wsl --install
```

### Virtualization Not Enabled?

1. Restart computer
2. Enter BIOS (usually F2, F10, or Del during boot)
3. Enable "Intel VT-x" or "AMD-V"
4. Save and exit

---

**Current Status:**
- ✅ Supabase CLI installed
- ❌ Docker Desktop NOT installed
- ⏳ Pending: Manual Docker Desktop installation

**After you install Docker Desktop, run `docker --version` and tell me!**
