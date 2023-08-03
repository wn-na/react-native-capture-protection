# react-native-capture-protection

simple control capture event (like screenshot, screen record) in Android, iOS Native

## Installation

```sh
npm install react-native-capture-protection
```

## Preview

### prevent, allow screenshot in iOS

![Simulator Screen Recording - iPhone 14 - 2022-12-09 at 16 02 15](https://user-images.githubusercontent.com/37437842/206644553-e4c3f2bc-b624-47ac-a005-132199e049b2.gif)

## Usage

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

More Infomation, please read this

- [method](https://github.com/0xlethe/react-native-capture-protection/wiki/method)
- [type](https://github.com/0xlethe/react-native-capture-protection/wiki/type)
- [migration to v1](https://github.com/0xlethe/react-native-capture-protection/wiki/how-to-migration-v0-to-v1)

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
