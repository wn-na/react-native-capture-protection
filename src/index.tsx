import { NativeEventEmitter, NativeModules, Platform } from 'react-native';
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
 * set `RecordCaptureProtecter`, if already record screen then change protector screen.
 *
 * if already exist `RecordCaptureProtecter` return `false`, otherwise return `true`
 */
async function startPreventRecording(
  screenName = 'ScreenRecordProtect.png'
): Promise<boolean> {
  if (Platform.OS !== 'ios') {
    return Promise.reject(
      new Error('Only IOS Support startPreventRecording function')
    );
  }
  try {
    const result = await CaptureProtectionModule?.startPreventRecording?.(
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
async function stopPreventRecording(): Promise<boolean> {
  if (Platform.OS !== 'ios') {
    return Promise.reject(
      new Error('Only IOS Support stopPreventRecording function')
    );
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
    return Promise.reject(new Error('Only IOS Support isRecording function'));
  }
  return !!(await CaptureProtectionModule?.isRecording?.());
}

/**
 * return `react-native-capture-protection` is init
 */
async function hasRecordEventListener(): Promise<boolean> {
  if (Platform.OS !== 'ios') {
    return Promise.reject(
      new Error('Only IOS Support hasRecordEventListener function')
    );
  }
  return !!(await CaptureProtectionModule?.hasRecordEventListener?.());
}

async function startPreventScreenshot(): Promise<boolean> {
  return await CaptureProtectionModule?.startPreventScreenshot?.();
}
async function stopPreventScreenshot(): Promise<boolean> {
  return await CaptureProtectionModule?.stopPreventScreenshot?.();
}
async function isPreventScreenshot(): Promise<boolean> {
  return await CaptureProtectionModule?.isPreventScreenshot?.();
}
export const CaptureProtection = {
  addRecordEventListener,
  hasRecordEventListener,
  startPreventRecording,
  stopPreventRecording,
  startPreventScreenshot,
  stopPreventScreenshot,
  isPreventScreenshot,
  isRecording,
};

export { CaptureProtectionModuleStatus } from './type';

/**
 *
 * addRecordEventListener
 * 화면 녹화 방지 화면 세팅함수
 * startPreventRecording
 * 화면 녹화 방지 화면 제거함수
 * stopPreventRecording
 * 화면 녹화 이벤트 리스너 존재여부
 * hasRecordEventListener
 * 현재 녹화중인지 여부
 * isRecording
 */
