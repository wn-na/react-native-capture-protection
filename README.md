# 🛡️ react-native-capture-protection

A React Native library to **prevent screen capture, screenshots, and app switcher previews**—providing enhanced security for your app.  
Fully compatible with **React Native CLI** and **Expo (Dev Client only)**.

---

## 📸 Screenshots

| Screenshot Protection                                                                                                      | App Switcher Protection                                                                                                        |
| -------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| ![Screen Recording](https://user-images.githubusercontent.com/37437842/206644553-e4c3f2bc-b624-47ac-a005-132199e049b2.gif) | ![App Switcher](https://github.com/wn-na/react-native-capture-protection/assets/37437842/ac98e942-8dba-4e5d-9f23-fa10f946b26b) |

---

## ✨ Features

- 🔒 iOS: Screenshot, Screen Recording & App Switcher protection
- 🔒 Android: Screenshot & Screen Recording protection
- 📡 Event listeners for capture events
- 🧩 Hooks & Provider support
- 📱 Android 14 support

---

## 🚀 Installation

> ⚠️ **Using React Native < 0.70?**  
> The latest v2.x version may not be compatible with versions below 0.70.  
> It is recommended to use [`v1.9.17`](https://github.com/wn-na/react-native-capture-protection/releases/tag/v1.9.17) for better stability with older React Native projects.

### Using npm

```sh
npm install react-native-capture-protection
```

### Using yarn

```sh
yarn add react-native-capture-protection
```

### Using with Expo

> ⚠️ Expo Dev Client only
> This library includes native code, so it does not work with Expo Go. You must use a custom dev client.

```sh
npx expo install react-native-capture-protection
```

### 🔧 iOS Setup

If you're developing for iOS, don't forget to install CocoaPods dependencies after installing the package.

```sh
cd ios && pod install
```

## ⚙️ Android Configuration (Required)

By default, it supports capture prevention, capture permission, and capture detection on Android 14 and above.
If you want capture detection(not prevent, only listener) support for versions below 14 (Android 10–13), please refer to the [Support Below Android 14, Capture Detection (Optional)](#support-below-android-14-capture-detection-optional) below.

### **React Native CLI**

add to `android/app/build.gradle`

```gradle
defaultConfig {
    ...
    missingDimensionStrategy "react-native-capture-protection", "base"
}
```

### **Expo (Dev Client only)**

add to `app.json`

```json
{
  ...
  "plugins": [
    ...,
    [
      "react-native-capture-protection",
      {
        "captureType": "base"
      }
    ]
  ]
}
```

## Support Below Android 14, Capture Detection (Optional)

On Android versions below 14, it detects screen captures using the sensitive READ_MEDIA_IMAGES permission.
If you want detection to work on Android versions below 14, please configure the settings as follows.

### Google Play Store Policy (READ_MEDIA_IMAGES)

If publishing to the Play Store, explain the usage of READ_MEDIA_IMAGES like this:

```
Used by the application to detect screenshots, by checking for screenshot files in the user’s media storage.
```

### **React Native CLI**

add to `android/app/build.gradle`

```gradle
defaultConfig {
    ...
    missingDimensionStrategy "react-native-capture-protection", "callbackTiramisu"
}
```

### **Expo (Dev Client only)**

add to `app.json`

```json
{
  ...
  "plugins": [
    ...,
    [
      "react-native-capture-protection",
      {
        "captureType": "callbackTiramisu"
      }
    ]
  ]
}
```

## 📦 Usage

```js
import {
  CaptureProtection,
  useCaptureProtection,
  CaptureEventType
} from 'react-native-capture-protection';

const Component = () => {
  const { protectionStatus, status } = useCaptureProtection();

  React.useEffect(() => {
    // Prevent all capture events
    CaptureProtection.prevent();

    // Or prevent specific events
    CaptureProtection.prevent({
      screenshot: true,
      record: true,
      appSwitcher: true
    });
  }, []);

  React.useEffect(() => {
    // Check if any capture is prevented
    console.log('Prevent Status:', protectionStatus);

    // Check current protection status
    console.log('Protection Status:', status);
  }, [protectionStatus, status]);

  // Allow all capture events
  const onAllow = async () => {
    await CaptureProtection.allow();
  };

  // Allow specific events
  const onAllowSpecific = async () => {
    await CaptureProtection.allow({
      screenshot: true,
      record: false,
      appSwitcher: true
    });
  };

  // Check if screen is being recorded
  const checkRecording = async () => {
    const isRecording = await CaptureProtection.isScreenRecording();
    console.log('Is Recording:', isRecording);
  };

  return (
    // Your component JSX
  );
};
```

## Jest integration

### With Jest Setup

1. Add to your `jest.config.js`:

```javascript
module.exports = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
};
```

2. Create jest.setup.js:

```javascript
jest.mock('react-native-capture-protection', () =>
  require('react-native-capture-protection/jest/capture-protection-mock')
);
```

### Overriding mock

```typescript
import { CaptureProtection } from "react-native-capture-protection/jest/capture-protection-mock";

...

    test("prevent is called", async () => {
        await CaptureProtection.prevent();
        expect(CaptureProtection.prevent).toHaveBeenCalled();
    });

```

## 📚 Documentation

🧪 [Methods](./docs/method.md) – All available API methods

📘 [Types](./docs/type.md) – Type definitions and interfaces

🛠 [Migration Guide](./docs/MIGRATION.md) – From v1.x to v2.x

## 🤝 Contributing

See CONTRIBUTING.md for details on contributing to this project.

## 📄 License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
