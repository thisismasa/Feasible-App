# HOW TO GET A PERMANENT CLOUDFLARE TUNNEL URL

## Current Situation

Right now, you're using **Quick Tunnels** which generate random URLs like:
- ❌ `chronic-speed-price-best.trycloudflare.com` (old, dead)
- ❌ `sticky-share-wedding-write.trycloudflare.com` (current, but temporary)

**These URLs change every time the tunnel restarts.**

---

## Solution: Named Tunnel (Permanent URL)

With a **Named Tunnel**, you get:
- ✅ **Same URL forever** - Never changes
- ✅ **Your custom subdomain** - Like `feasible-app.your-domain.com`
- ✅ **Free** - Cloudflare tunnels are 100% free

---

## Setup Instructions (2 Options)

### Option 1: AUTOMATIC SETUP (Recommended)

**Just double-click:**
```
SETUP_PERMANENT_TUNNEL.bat
```

This will:
1. Open Cloudflare login in your browser
2. Create a tunnel named "feasible-app"
3. Give you a permanent URL
4. Configure everything automatically

**Then to start the tunnel:**
```
START_PERMANENT_TUNNEL.bat
```

---

### Option 2: MANUAL SETUP

If the automatic script doesn't work, follow these steps:

#### Step 1: Login to Cloudflare
```bash
cloudflared tunnel login
```
- Browser will open
- Login with your Cloudflare account (create free account if needed)
- Authorize the tunnel

#### Step 2: Create Named Tunnel
```bash
cloudflared tunnel create feasible-app
```
- Copy the tunnel ID (long string shown)

#### Step 3: Create Config File
Create `%USERPROFILE%\.cloudflared\config.yml`:

```yaml
tunnel: YOUR_TUNNEL_ID_HERE
credentials-file: C:\Users\masathomard\.cloudflared\YOUR_TUNNEL_ID_HERE.json

ingress:
  - hostname: feasible-app.yourdomain.com
    service: http://localhost:8080
  - service: http_status:404
```

#### Step 4: Route DNS
```bash
cloudflared tunnel route dns feasible-app feasible-app.yourdomain.com
```

#### Step 5: Run Tunnel
```bash
cloudflared tunnel run feasible-app
```

---

## For Now: Use Current Temporary URL

Until you set up the permanent tunnel, your updated app is available at:

**https://sticky-share-wedding-write.trycloudflare.com**

This URL has the **latest code with all booking fixes** applied.

---

## Important Notes

1. **Free tunnels generate random URLs** - This is by design from Cloudflare
2. **Named tunnels require a Cloudflare account** - 100% free to create
3. **The app code is updated** - Regardless of URL, port 8080 has the fixes
4. **All booking validations are fixed** - The "0 hours advance" error is gone

---

## What Got Fixed (Already Applied)

✅ Time validation logic - 3 code changes
✅ Same-minute booking enabled
✅ All slots 7 AM - 10 PM available
✅ Database: 0 sessions blocking Oct 27

The fixes are **LIVE RIGHT NOW** on any URL pointing to port 8080!

---

## Summary

**Current Status:**
- ✅ Fixed code is running on port 8080
- ✅ Accessible via temporary URL: `sticky-share-wedding-write.trycloudflare.com`
- ⏳ Permanent URL requires: Running `SETUP_PERMANENT_TUNNEL.bat`

**After Setup:**
- ✅ Fixed code running on port 8080
- ✅ Accessible via **permanent URL** that never changes
- ✅ No more URL changes ever again!
