
# phoenix-android

Welcome to the **phoenix-android** repository. This repository contains the source code and configuration files necessary to build and deploy the Phoenix Code trusted web app for Android devices, focusing exclusively on ChromeOS support.

## Prerequisites

Before you begin, ensure the following tools are installed:
- Node.js (v12 or higher)
- npm (typically installed with Node.js)
- Java Development Kit (JDK) 8 or newer
- Android SDK
- Bubblewrap CLI

Install Bubblewrap using npm:
```bash
npm install -g @bubblewrap/cli
```

## Setup

First, clone the repository to your local machine:
```bash
git clone https://github.com/yourusername/phoenix-android.git
cd phoenix-android
```

## Building the TWA

To build the Trusted Web Activity (TWA) APK using Bubblewrap with the existing `twa-manifest.json` configuration, ensure the `twa-manifest.json` includes the correct signing key information:

```json
"signingKey": {
    "path": "/home/charly/repo/phoenix-andriod-prod/android.keystore",
    "alias": "android"
}
```

Then run the following command:
```bash
bubblewrap build
```
This will generate an APK file ready for uploading to the Google Play Store.

## Testing

It’s crucial to test your APK before submission:
1. Install the APK on a ChromeOS device or an Android emulator.
2. Verify that the app opens and renders the web content correctly.
3. Check all functionalities to ensure they perform as expected.

## Deployment

After satisfactory testing:
1. Prepare promotional materials and screenshots as required by the Google Play Store.
2. Submit your APK via the Google Play Console.
3. Monitor the publication status and address any issues flagged by the Play Store.

## Contributing

Contributions are welcome! For guidelines on how to contribute effectively, please refer to the CONTRIBUTING.md file.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
