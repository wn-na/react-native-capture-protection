# react-native-capture-protection

control capture event

## Installation

```sh
npm install react-native-capture-protection
```

## Usage

```js
import {
  CaptureProtection,
  CaptureProtectionModuleStatus,
} from 'react-native-capture-protection';

// ...
CaptureProtection.addRecordEventListener(({ status }) => {
  if (status == CaptureProtectionModuleStatus.RECORD_DETECTED_START) {
    Alert.alert('Warning', 'record detected');
  }
});

await CaptureProtection.startPreventScreenshot();
await CaptureProtection.stopPreventScreenshot();
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
