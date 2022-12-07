import {
  Image,
  NativeEventEmitter,
  NativeModules,
  Platform,
} from 'react-native';
import type { CaptureNotificationListenerCallback } from './type';
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
function addRecordEventListener(
  callback: CaptureNotificationListenerCallback
): void {
  if (Platform.OS !== 'ios') {
    return;
  }
  CaptureNotificationEmitter?.addListener?.(
    'CaptureProtectionListener',
    callback
  );
}

/**
 * set `startPreventRecording`, if already record screen then change protector screen.
 *
 * if already exist `startPreventRecording` return `false`, otherwise return `true`
 */
async function startPreventRecording(): Promise<boolean> {
  if (Platform.OS !== 'ios') {
    return Promise.reject(new Error('Only IOS Support startPreventRecording'));
  }
  try {
    return !!(await CaptureProtectionModule?.startPreventRecording?.());
  } catch (e) {
    return Promise.reject(e);
  }
}

/**
 * remove `stopPreventRecording` and protecter screen.
 *
 * if any `stopPreventRecording` is not exist, return `false`, otherwise return `true`
 */
async function stopPreventRecording(): Promise<boolean> {
  if (Platform.OS !== 'ios') {
    return Promise.reject(new Error('Only IOS Support stopPreventRecording'));
  }
  try {
    return !!(await CaptureProtectionModule?.stopPreventRecording?.());
  } catch (e) {
    return Promise.reject(e);
  }
}

/**
 * return UIScreen value of `isCaptured`
 *
 * more information, visit `https://developer.apple.com/documentation/uikit/uiscreen/2921651-captured`
 */
async function isRecording(): Promise<boolean> {
  if (Platform.OS !== 'ios') {
    return Promise.reject(new Error('Only IOS Support isRecording'));
  }
  return !!(await CaptureProtectionModule?.isRecording?.());
}

/**
 * return `react-native-capture-protection` is init
 */
async function hasRecordEventListener(): Promise<boolean> {
  if (Platform.OS !== 'ios') {
    return Promise.reject(new Error('Only IOS Support hasRecordEventListener'));
  }
  return !!(await CaptureProtectionModule?.hasRecordEventListener?.());
}

/**
 * if start prevent screenshot event return `true` else, return `false`
 */
async function startPreventScreenshot(): Promise<boolean> {
  if (Platform.OS !== 'ios') {
    return Promise.reject(new Error('Only IOS Support startPreventScreenshot'));
  }
  try {
    return !!(await CaptureProtectionModule?.startPreventScreenshot?.());
  } catch (e) {
    return Promise.reject(e);
  }
}

/**
 * if stop prevent screenshot event return `true` else, return `false`
 */
async function stopPreventScreenshot(): Promise<boolean> {
  if (Platform.OS !== 'ios') {
    return Promise.reject(new Error('Only IOS Support stopPreventScreenshot'));
  }

  try {
    return !!(await CaptureProtectionModule?.stopPreventScreenshot?.());
  } catch (e) {
    return Promise.reject(e);
  }
}

/**
 * return is prevent screenshot event
 */
async function isPreventScreenshot(): Promise<boolean> {
  if (Platform.OS !== 'ios') {
    return Promise.reject(new Error('Only IOS Support isPreventScreenshot'));
  }
  return !!(await CaptureProtectionModule?.isPreventScreenshot?.());
}

/**
 * setting Record Protect Screen with only Text
 */
async function setRecordProtectionScreenWithText(
  text = 'ERROR!!'
): Promise<boolean> {
  if (Platform.OS !== 'ios') {
    return Promise.reject(
      new Error('Only IOS Support setRecordProtectionScreenWithText')
    );
  }
  return !!(await CaptureProtectionModule?.setRecordProtectionScreenWithText?.(
    text
  ));
}

/**
 * setting Record Protect Screen with only Image
 */
async function setRecordProtectionScreenWithImage(
  image: NodeRequire
): Promise<boolean> {
  if (Platform.OS !== 'ios') {
    return Promise.reject(
      new Error('Only IOS Support setRecordProtectionScreenWithImage')
    );
  }
  return await CaptureProtectionModule?.setRecordProtectionScreenWithImage?.(
    Image.resolveAssetSource(image as any)
  );
}

export const CaptureProtection = {
  addRecordEventListener,
  hasRecordEventListener,
  startPreventRecording,
  startPreventScreenshot,
  stopPreventRecording,
  stopPreventScreenshot,
  isPreventScreenshot,
  isRecording,
  setRecordProtectionScreenWithText,
  setRecordProtectionScreenWithImage,
};

export { CaptureProtectionModuleStatus } from './type';
