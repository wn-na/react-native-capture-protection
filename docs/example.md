# Example

## How to prevent the screen in App switcher only (Android)

```typescript
useEffect(() => {
  const appStateFocusSub = AppState.addEventListener('focus', () => {
    CaptureProtection.allow();
  });
  const appStateBlurSub = AppState.addEventListener('blur', () => {
    CaptureProtection.prevent();
  });

  return () => {
    appStateFocusSub.remove();
    appStateBlurSub.remove();
  };
}, []);
```

- [source](https://github.com/wn-na/react-native-capture-protection/issues/80#issuecomment-2854515681)
