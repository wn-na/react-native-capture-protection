# Migration Guide

## From v1.x to v2.x

### Breaking Changes

1. **Hook Return Value Changes**

   ```diff
   - const { isPrevent, status } = useCaptureProtection();
   + const { protectionStatus, status } = useCaptureProtection();
   ```

2. **Method Name Changes**

   ```diff
   - CaptureProtection.preventScreenRecord();
   - CaptureProtection.allowScreenRecord();
   + CaptureProtection.prevent({ record: true });
   + CaptureProtection.allow({ record: true });

   - CaptureProtection.setScreenRecordScreenWithText("test");
   + CaptureProtection.prevent({ record: { text: "test" } });

   - CaptureProtection.setScreenRecordScreenWithImage(require(""));
   + CaptureProtection.prevent({ record: { image: require("") } });

   - CaptureProtection.preventBackground();
   - CaptureProtection.allowBackground();
   + CaptureProtection.prevent({ appSwitcher: true });
   + CaptureProtection.allow({ appSwitcher: true });
   ```

### New Features

1. **Unified API**

   - Single `prevent()` and `allow()` methods with options
   - Platform-specific options for iOS and Android

2. **Enhanced Event Types**

   - New event types for better capture event handling
   - Improved event listener system

3. **Improved Type Safety**
   - Better TypeScript support
   - More precise type definitions

### Migration Steps

1. Update the package:

   ```bash
   npm install react-native-capture-protection@latest
   # or
   yarn add react-native-capture-protection@latest
   ```

2. Update your imports:

   ```diff
   - import {
   -   CaptureProtection,
   -   CaptureProtectionModuleStatus,
   -   isCapturedStatus
   - } from 'react-native-capture-protection';
   + import {
   +   CaptureProtection,
   +   useCaptureProtection,
   +   CaptureEventType
   + } from 'react-native-capture-protection';
   ```

3. Update your hook usage:

   ```diff
   - const { isPrevent, status } = useCaptureProtection();
   + const { protectionStatus, status } = useCaptureProtection();
   ```

4. Update your method calls:

   ```diff
   - CaptureProtection.preventScreenRecord();
   + CaptureProtection.prevent({ record: true });
   ```

5. Update your event listeners:
   ```diff
   - CaptureProtection.addListener((event) => {
   -   // Handle event
   - });
   + CaptureProtection.addListener((event) => {
   +   switch (event) {
   +     case CaptureEventType.CAPTURED:
   +       // Handle capture
   +       break;
   +     case CaptureEventType.RECORDING:
   +       // Handle recording
   +       break;
   +     // ... other cases
   +   }
   + });
   ```
