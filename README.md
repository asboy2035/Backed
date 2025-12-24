![Backed](/Images/Desktop.jpeg)

# Backed
Backed is a macOS application that allows you to use video files as live desktop wallpapers. 
It provides a clean SwiftUI-based interface for managing a personal wallpaper library and runs a performant, hardware-accelerated video wallpaper behind your desktop icons.
The project intentionally focuses on **desktop wallpapers only**. 
Lock screen and login screen backgrounds are explicitly out of scope for the main app due to macOS architectural constraints.

## Features
- Use videos as wallpapers
- Manage your wallpapers in the Backed library
- Beautiful interface :3


## Non-Goals
Backed deliberately does **not** attempt to:

- Replace the macOS lock screen or login background
- Render video behind the login UI
- Modify system files or disable SIP
- Use ScreenSaverEngine or `.saver` bundles

These behaviors require separate pipelines and are intentionally excluded to keep Backed stable, understandable, and user-space safe.


## Requirements
- macOS 14.6 or later
- Apple Silicon or Intel Mac
- Swift 5.9+
- Xcode 16+


## Building
1. Clone the repository
2. Open the project in Xcode
3. Select the Backed target
4. Set your development team for signing, or sign for running locally 
5. Build and run!

No special entitlements or system permissions are required.


## Notes on Lock Screen Wallpapers
While some third-party apps appear to set animated lock screen wallpapers, they do so using **ScreenSaverEngine-based pipelines**, not AppKit or SwiftUI windows.
Backed intentionally avoids this approach in the main app. 
If lock screen support is ever added, it would be implemented as a separate ScreenSaver target, not as an AppKit window.
