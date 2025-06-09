# react-native-capture-protection

> 🛡️ A React Native library to prevent screen capture, screenshots and app switcher for enhanced security. Fully compatible with both Expo and CLI.

| screenshot                                                                                                                           | app switcher                                                                                                                                                                            |
| ------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ![Simulator Screen Recording](https://user-images.githubusercontent.com/37437842/206644553-e4c3f2bc-b624-47ac-a005-132199e049b2.gif) | ![Simulator Screen Recording - iPhone 15 Pro - 2024-07-02 at 21 19 17](https://github.com/0xlethe/react-native-capture-protection/assets/37437842/ac98e942-8dba-4e5d-9f23-fa10f946b26b) |

## Features

- iOS Capture Protection (Screenshot, Screen Recording, App Switcher)
- Android Capture Protection (Screenshot, Screen Recording)
- Event Listener for Capture Events
- Provider and Hooks Support
- Android 14 Support

## Installation

### Use npm

```sh
npm install react-native-capture-protection
```

### Use yarn

```sh
yarn add react-native-capture-protection
```

### use Expo

> Only Expo Dev client compatible
> This library has native code, so it's not work for Expo Go but it's compatible with custom dev client.

```
npx expo install react-native-capture-protection
```

## Setting

### Android

On Android versions below 14, storage permissions are required to determine if a screen capture is enabled.

- `android/app/build.gradle`

```
    defaultConfig {
        ...
        missingDimensionStrategy "react-native-capture-protection", "fullMediaCapture"
    }
```

### In Play Store

- `Details on Google Play's Photo and Video Permissions policy READ_MEDIA_IMAGES`

```
Used by the application to detect screenshots, to detect the presence of screenshot files on the user's media.
```

### If you want to use it without detecting the capture, please set the following settings.

- `android/app/build.gradle`

```
    defaultConfig {
        ...
        missingDimensionStrategy "react-native-capture-protection", "restrictedCapture"
    }
```

## How to Use

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

## Documentation

- [Methods](./docs/method.md) - Detailed documentation of all available methods
- [Types](./docs/type.md) - Type definitions and interfaces
- [Migration Guide](./docs/MIGRATION.md) - Guide for migrating from v1.x to v2.x

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
