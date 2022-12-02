import { NativeEventEmitter, NativeModules, Platform } from 'react-native';
import type { CaptureNotificationListenerCallback } from './type';
const LINKING_ERROR =
  `The package 'react-native-capture-protection' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const CaptureProtectionModule = Platform.select({
  ios: NativeModules.CaptureProtectionModule
    ? NativeModules.CaptureProtectionModule
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
 * create listener `initCaptureProtectionModuleListener`
 */
function initCaptureProtectionModuleListener(
  callback: CaptureNotificationListenerCallback
): void {
  if (Platform.OS !== 'ios') {
    return;
  }
  CaptureNotificationEmitter?.addListener?.(
    'CaptureProtectionModuleListener',
    callback
  );
}

/**
 * set `RecordCaptureProtecter`, if already record screen then change protector screen.
 *
 * if already exist `RecordCaptureProtecter` return `false`, otherwise return `true`
 */
async function addRecordCaptureProtecter(
  screenName = 'ScreenRecordProtect.png'
): Promise<boolean> {
  if (Platform.OS !== 'ios') {
    return Promise.reject(
      new Error('Only IOS Support addRecordCaptureProtecter function')
    );
  }
  try {
    const result = await CaptureProtectionModule?.addRecordCaptureProtecter?.(
      screenName
    );
    return !!result;
  } catch (e) {
    return Promise.reject(e);
  }
}

/**
 * remove `RecordCaptureProtecter` and protecter screen.
 *
 * if any `RecordCaptureProtecter` is not exist, return `false`, otherwise return `true`
 */
async function removeRecordCaptureProtecter(): Promise<boolean> {
  if (Platform.OS !== 'ios') {
    return Promise.reject(
      new Error('Only IOS Support removeRecordCaptureProtecter function')
    );
  }
  try {
    return !!(await CaptureProtectionModule?.removeRecordCaptureProtecter?.());
  } catch (e) {
    return Promise.reject(e);
  }
}

/**
 * return UIScreen value of `isCaptured`
 *
 * more information, visit `https://developer.apple.com/documentation/uikit/uiscreen/2921651-captured`
 */
async function isCaptured(): Promise<boolean> {
  if (Platform.OS !== 'ios') {
    return Promise.reject(new Error('Only IOS Support isCaptured function'));
  }
  return !!(await CaptureProtectionModule?.isCaptured?.());
}

/**
 * return `react-native-capture-protection` is init
 */
async function hasRecordCapturedListener(): Promise<boolean> {
  if (Platform.OS !== 'ios') {
    return Promise.reject(
      new Error('Only IOS Support hasRecordCapturedListener function')
    );
  }
  return !!(await CaptureProtectionModule?.hasRecordCapturedListener?.());
}

export const CaptureProtection = {
  initCaptureProtectionModuleListener,
  isCaptured,
  hasRecordCapturedListener,
  addRecordCaptureProtecter,
  removeRecordCaptureProtecter,
};
