# Type Documentation

## Enums

### `CaptureEventType`

Enum representing different types of capture events.

```typescript
enum CaptureEventType {
  NONE = 0, // No capture event
  RECORDING = 1, // Screen recording started
  END_RECORDING = 2, // Screen recording ended
  CAPTURED = 3, // Screen captured
  APP_SWITCHING = 4, // App switcher used
  UNKNOWN = 5, // Unknown event
  ALLOW = 8, // All capture events allowed
  PREVENT_SCREEN_CAPTURE = 16, // Screen capture prevented
  PREVENT_SCREEN_RECORDING = 32, // Screen recording prevented
  PREVENT_SCREEN_APP_SWITCHING = 64, // App switcher capture prevented
}
```

## Interfaces

### `IOSProtectionScreenOption`

Options for iOS screen protection with custom UI.

```typescript
type IOSProtectionCustomScreenOption {
  text: string; // Text to display
  textColor?: `#${string}`; // Text color in hex format, default is Black
  backgroundColor?: `#${string}`; // Background color in hex format, default is White
}
type IOSProtectionScreenOption =
  | {
      image: NodeRequire; // Image to display
    }
  | IOSProtectionCustomScreenOption;
```

### `PreventOption`

Configuration options for preventing capture events.

```typescript
interface PreventOption {
  screenshot?: boolean; // Prevent screenshots
  record?: boolean | IOSProtectionScreenOption; // Prevent screen recording
  appSwitcher?: boolean | IOSProtectionScreenOption; // Prevent app switcher capture
}
```

### `AllowOption`

Configuration options for allowing capture events.

```typescript
interface AllowOption {
  screenshot?: boolean; // Allow screenshots
  record?: boolean; // Allow screen recording
  appSwitcher?: boolean; // Allow app switcher capture
}
```

### `CaptureProtectionModuleStatus`

Status of protection for different capture events.

```typescript
interface CaptureProtectionModuleStatus {
  screenshot: boolean; // Screenshot protection status
  record: boolean; // Screen recording protection status
  appSwitcher: boolean; // App switcher protection status
}
```

### `CaptureEventCallback`

Type for the event listener callback function.

```typescript
type CaptureEventCallback = (event: CaptureEventType) => void;
```
