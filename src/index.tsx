import {
  Image,
  NativeEventEmitter,
  NativeModules,
  Platform,
} from 'react-native';
import type { CaptureEventListenerCallback, CaptureEventStatus } from './type';
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
 * `RECORD_DETECTED_START`, `RECORD_DETECTED_END`, `CAPTURE_DETECTED` status return with event listener be registered
 *
 *  - return with `prevent status`
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

/**
 *  allow screen record
 *
 * - if `removeListener` is `true`, listener will be removed else listener is alive, default is `false`
 */
const allowScreenRecord = async (removeListener = false): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.allowScreenRecord?.(removeListener);
};

/**
 *  prevent screen record
 *
 *  if detect screen record, screen will be change protect screen (setting with `setScreenRecordScreenWithText` or `setScreenRecordScreenWithImage`)
 *
 * if `isImmediate` is `true`, screen is already recording, change immediate, default is `false`
 */
const preventScreenRecord = async (isImmediate = false): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.preventScreenRecord?.(isImmediate);
};

/**
 *  allow screenshot
 *
 * - if `removeListener` is `true`, listener will be removed else listener is alive, default is `false`
 */
const allowScreenshot = async (removeListener = false): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.allowScreenshot?.(removeListener);
};

/**
 *  prevent screenshot
 *
 * if user take screenshot, screenshot image will be black screen
 */
const preventScreenshot = async (): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.preventScreenshot?.();
};

/**
 *  add only screen record event listener
 */
const addScreenRecordListener = async (): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.addScreenRecordListener?.();
};

/**
 *  remove only screen record event listener
 */
const removeScreenRecordListener = async (): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.removeScreenRecordListener?.();
};

/**
 *  add only screenshot event listener
 */
const addScreenshotListener = async (): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.addScreenshotListener?.();
};

/**
 *  remove only screenshot event listener
 *
 *  this function didnt remove prevent screenshot event
 *
 *  if remove prevent screenshot, use `preventScreenshot`
 */
const removeScreenshotListener = async (): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.removeScreenshotListener?.();
};

/** return listener regist status */
const hasListener = async (): Promise<CaptureEventStatus | undefined> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.hasListener?.();
};

/**
 * return UIScreen value of `isCaptured`
 *
 * more information, visit `https://developer.apple.com/documentation/uikit/uiscreen/2921651-captured`
 */
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

export { CaptureProtectionModuleStatus, CaptureEventStatus } from './type';
