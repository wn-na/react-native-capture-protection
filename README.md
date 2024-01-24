# react-native-capture-protection

> 🚀 Simple control capture event (like screenshot, screen record) in Android, iOS + React Native

![Simulator Screen Recording](https://user-images.githubusercontent.com/37437842/206644553-e4c3f2bc-b624-47ac-a005-132199e049b2.gif)

## Features

- iOS Capture Event via screen recording, capture capture with Listener
- allow, prevent Android, iOS Capture Event
- allow, prevent iOS Record Screen
- Provider, Hooks
- >= RN 0.64

## Installation

```sh
npm install react-native-capture-protection
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
