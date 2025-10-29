# iPhone Deployment with Cloudflare Tunnel

## Overview
You have two options to run your Flutter app on iPhone:

### Option 1: Native iOS App (Recommended)
Run the Flutter app directly on your iPhone as a native iOS app.

### Option 2: Flutter Web + Cloudflare Tunnel
Access your app via Safari on iPhone through a Cloudflare tunnel.

---

## Option 1: Native iOS App Setup

### Prerequisites
1. **Physical iPhone** connected via USB
2. **Developer Mode** enabled on iPhone:
   - Go to Settings > Privacy & Security > Developer Mode
   - Toggle ON and restart iPhone
3. **Trust Computer**: When iPhone prompts "Trust This Computer?", tap Trust
4. **Flutter iOS Setup**:
   ```bash
   flutter doctor
   ```
   Ensure iOS toolchain is installed

### Steps to Run

1. **Connect iPhone via USB cable**

2. **Run the batch file**:
   ```bash
   RUN_ON_IPHONE_NATIVE.bat
   ```
   OR manually:
   ```bash
   cd Feasible-App/coach_app
   flutter devices
   flutter run
   ```

3. **Select your iPhone** from the device list when prompted

4. **First-time setup**:
   - Open Settings on iPhone
   - Go to General > VPN & Device Management
   - Trust your developer certificate

### Troubleshooting
- If "No devices found", check USB connection
- Ensure iPhone is unlocked during deployment
- May need Mac with Xcode for signing (if on Windows, use Option 2)

---

## Option 2: Flutter Web + Cloudflare Tunnel

Perfect for testing on iPhone when you don't have Mac/Xcode!

### Prerequisites
- Cloudflare Tunnel installed (already done!)
- iPhone connected to internet (WiFi or cellular)

### Steps to Run

1. **Run the Cloudflare tunnel script**:
   ```bash
   RUN_ON_IPHONE_CLOUDFLARE.bat
   ```

   This will:
   - Start Flutter web server on port 8080
   - Create a Cloudflare tunnel
   - Generate a public URL (e.g., `https://random-name.trycloudflare.com`)

2. **Copy the Cloudflare URL** displayed in the terminal

   Look for output like:
   ```
   https://gentle-snow-1234.trycloudflare.com
   ```

3. **Open on iPhone**:
   - Open Safari on your iPhone
   - Navigate to the Cloudflare URL
   - App will run in browser!

### Advantages
- No Mac/Xcode required
- No USB cable needed
- Test from anywhere (even different WiFi networks)
- Share link with others for testing
- More secure than ngrok

### How It Works
```
[Your PC]
   Flutter Web :8080
        ↓
   Cloudflare Tunnel
        ↓
[Public URL: https://xyz.trycloudflare.com]
        ↓
[iPhone Safari]
```

---

## Comparison

| Feature | Native App | Web + Tunnel |
|---------|-----------|--------------|
| Performance | Excellent | Good |
| Native Features | Full Access | Limited |
| Setup Complexity | Medium-High | Low |
| Requires Mac | Sometimes | No |
| Hot Reload | Yes | Yes |
| Testing Speed | Fast | Fast |
| Share with Others | No | Yes (URL) |

---

## Quick Start Commands

### Native iOS:
```bash
flutter run
```

### Web + Cloudflare:
```bash
# Terminal 1
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0

# Terminal 2
cloudflared tunnel --url http://localhost:8080
```

---

## Notes

- **Supabase Backend**: Already configured with cloud URL - no local backend needed!
- **Google OAuth**: May need additional setup for iOS (see GOOGLE_CLOUD_SETUP.md)
- **Hot Reload**: Works with both methods
- **Cloudflare URLs**: Change each time you restart the tunnel (free version)
- **Permanent Tunnel**: Requires Cloudflare account (can create named tunnels)

---

## Next Steps

1. Choose your deployment method
2. Run the appropriate batch file
3. Test the app on your iPhone
4. Report any issues

For production deployment to App Store, you'll need:
- Mac with Xcode
- Apple Developer Account ($99/year)
- Code signing certificates
- App Store Connect setup
