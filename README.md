# react-native-capture-protection

> 🚀 Simple control capture event (like screenshot, screen record) in Android, iOS + React Native

![Simulator Screen Recording](https://user-images.githubusercontent.com/37437842/206644553-e4c3f2bc-b624-47ac-a005-132199e049b2.gif)

![Simulator Screen Recording - iPhone 15 Pro - 2024-07-02 at 21 19 17](https://github.com/0xlethe/react-native-capture-protection/assets/37437842/ac98e942-8dba-4e5d-9f23-fa10f946b26b)

## Features

- iOS Capture Event via screen recording, capture capture with Listener
- allow, prevent Android, iOS Capture Event
- allow, prevent iOS Record Screen
- Provider, Hooks
- > = RN 0.64
- support Android 14

## Installation

```sh
npm install react-native-capture-protection
```

- Expo

> Only Expo Dev client compatible
> This library has native code, so it's not work for Expo Go but it's compatible with custom dev client.

```
npx expo install react-native-capture-protection
```

```js
import {
  CaptureProtection,
  CaptureProtectionModuleStatus,
  isCapturedStatus
} from 'react-native-capture-protection';

const Component = (props) => {
  const { isPrevent, status } = useCaptureProtection();

  React.useEffect(() => {
    console.log('Prevent Status is', isPrevent);
  }, [isPrevent]);
  React.useEffect(() => {
    console.log('Capture Status is', isCapturedStatus(status));
  }, [status]);

  const onPrevent = () => {
    CaptureProtection.preventScreenRecord();
  }
  const onAllow = () => {
    CaptureProtection.allowScreenRecord();
  }

  ...

};
```

## Docs

- [method](https://github.com/0xlethe/react-native-capture-protection/wiki/method)
- [type](https://github.com/0xlethe/react-native-capture-protection/wiki/type)

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
