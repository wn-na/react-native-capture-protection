import {
  Image,
  NativeEventEmitter,
  NativeModules,
  Platform,
} from 'react-native';
import type { CaptureEventListenerCallback, CaptureEventType } from './type';
const LINKING_ERROR =
  `The package 'react-native-capture-protection' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const CaptureProtectionModule = Platform.select({
  ios: NativeModules.CaptureProtection
    ? NativeModules.CaptureProtection
    : new Proxy(
        {},
        {
          get() {
            throw new Error(LINKING_ERROR);
          },
        }
      ),
  default: undefined,
});

const CaptureNotificationEmitter = Platform.select({
  ios: new NativeEventEmitter(CaptureProtectionModule),
  default: undefined,
});

/**
 * create listener `addRecordEventListener`
 *
 * `RECORD_DETECTED_START`, `RECORD_DETECTED_END` status will be call when `startPreventRecording` event call
 *
 * `CAPTURE_DETECTED` status will be call when `startPreventCapture` event call
 */
function addEventListener(callback: CaptureEventListenerCallback): void {
  if (Platform.OS !== 'ios') {
    return;
  }
  CaptureNotificationEmitter?.addListener?.(
    'CaptureProtectionListener',
    callback
  );
}

/**
 * setting Record Protect Screen with only Text
 */
const setScreenRecordScreenWithText = async (
  message: string
): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.setScreenRecordScreenWithText?.(
    message
  );
};

/**
 * setting Record Protect Screen with only Image
 */
const setScreenRecordScreenWithImage = async (
  image: NodeRequire
): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.setScreenRecordScreenWithImage?.(
    Image.resolveAssetSource(image as any)
  );
};

const allowScreenRecord = async (removeListener = false): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.allowScreenRecord?.(removeListener);
};

const preventScreenRecord = async (isImmediate = false): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.preventScreenRecord?.(isImmediate);
};

const allowScreenshot = async (removeListener = false): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.allowScreenshot?.(removeListener);
};

const preventScreenshot = async (): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.preventScreenshot?.();
};

const addScreenRecordListener = async (): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.addScreenRecordListener?.();
};

const removeScreenRecordListener = async (): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.removeScreenRecordListener?.();
};

const addScreenshotListener = async (): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.addScreenshotListener?.();
};

const removeScreenshotListener = async (): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.removeScreenshotListener?.();
};

const hasListener = async (): Promise<
  Record<CaptureEventType, boolean> | undefined
> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.hasListener?.();
};

const isScreenRecording = async (): Promise<boolean | undefined> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.isScreenRecording?.();
};

export const CaptureProtection = {
  addEventListener,
  setScreenRecordScreenWithText,
  setScreenRecordScreenWithImage,
  allowScreenshot,
  preventScreenshot,
  allowScreenRecord,
  preventScreenRecord,
  addScreenshotListener,
  removeScreenshotListener,
  addScreenRecordListener,
  removeScreenRecordListener,
  hasListener,
  isScreenRecording,
};

export { CaptureProtectionModuleStatus } from './type';
