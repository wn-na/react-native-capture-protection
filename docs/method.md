# Method Documentation

## Core Methods

### `prevent(option?: PreventOption)`

Prevents screen capture and recording based on the provided options.

> For Android, prevent specific events is not available. 

**Parameters:**

- `option?: PreventOption` - Configuration object for preventing specific capture events
  ```typescript
  {
    screenshot?: boolean;        // Prevent screenshots
    record?: boolean | IOSProtectionScreenOption;  // Prevent screen recording
    appSwitcher?: boolean | IOSProtectionScreenOption;  // Prevent app switcher capture
  }
  ```

**Example:**

```typescript
// Prevent all capture events
await CaptureProtection.prevent();

// Prevent specific events
await CaptureProtection.prevent({
  screenshot: true,
  record: true,
  appSwitcher: true,
});
```

### `allow(option?: AllowOption)`

Allows screen capture and recording based on the provided options.

> For Android, allow specific events is not available. 

**Parameters:**

- `option?: AllowOption` - Configuration object for allowing specific capture events
  ```typescript
  {
    screenshot?: boolean;        // Allow screenshots
    record?: boolean;           // Allow screen recording
    appSwitcher?: boolean;      // Allow app switcher capture
  }
  ```

**Example:**

```typescript
// Allow all capture events
await CaptureProtection.allow();

// Allow specific events
await CaptureProtection.allow({
  screenshot: true,
  record: false,
  appSwitcher: true,
});
```

### `isScreenRecording()`

Checks if the screen is currently being recorded.

> This behavior may not work properly on **Android**

**Returns:**

- `Promise<boolean | undefined>` - `true` if screen is being recorded, `false` otherwise

**Example:**

```typescript
const isRecording = await CaptureProtection.isScreenRecording();
console.log('Is Recording:', isRecording);
```

### `protectionStatus()`

Gets the current protection status for all capture events.

**Returns:**

- `Promise<CaptureProtectionModuleStatus>` - Object containing protection status for each event type

**Example:**

```typescript
const status = await CaptureProtection.protectionStatus();
console.log('Protection Status:', status);
```

## Hook Methods

### `useCaptureProtection()`

React hook for managing capture protection state.

**Returns:**

```typescript
{
  isPrevent: boolean; // Whether any capture is prevented
  status: CaptureProtectionModuleStatus; // Current protection status
  prevent: CaptureProtectionFunction['prevent'];
  allow: CaptureProtectionFunction['allow'];
}
```

**Example:**

```typescript
const { isPrevent, status, allow, prevent } = useCaptureProtection();
```

### `useCaptureDetection()`

React hook for managing capture protection state.

**Returns:**

```typescript
{
  isPrevent: boolean; // Whether any capture is prevented
  status: CaptureProtectionModuleStatus; // Current protection status
}
```

**Example:**

```typescript
const { isPrevent, status } = useCaptureDetection();
```
