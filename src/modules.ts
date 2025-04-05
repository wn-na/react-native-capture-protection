import { NativeEventEmitter, NativeModules, Platform } from 'react-native';
import {
  CaptureProtectionAndroidNativeModules,
  CaptureProtectionFunction,
  CaptureProtectionIOSNativeModules,
} from './type';

const CaptureProtectionModule = NativeModules?.CaptureProtection ?? {};

const CaptureProtectionAndroidModule =
  CaptureProtectionModule as CaptureProtectionAndroidNativeModules;
const CaptureProtectionIOSModule =
  CaptureProtectionModule as CaptureProtectionIOSNativeModules;

const isPlatformSupported = Platform.OS === 'ios' || Platform.OS === 'android';

const CaptureNotificationEmitter = isPlatformSupported
  ? new NativeEventEmitter(CaptureProtectionModule)
  : undefined;

const CaptureProtectionEventType = 'CaptureProtectionListener' as const;

const allow: CaptureProtectionFunction['allow'] = async (option) => {
  if (Platform.OS === 'android') {
    return await CaptureProtectionAndroidModule?.allow?.();
  }
  if (Platform.OS === 'ios') {
    const {
      record = false,
      appSwitcher = false,
      screenshot = false,
    } = option ?? {
      record: true,
      appSwitcher: true,
      screenshot: true,
    };

    if (screenshot) {
      await CaptureProtectionIOSModule?.allowScreenShot?.();
    }

    if (appSwitcher) {
      await CaptureProtectionIOSModule?.allowAppSwitcher?.();
    }

    if (record) {
      await CaptureProtectionIOSModule?.allowScreenRecord?.();
    }
  }
};

const prevent: CaptureProtectionFunction['prevent'] = async (option) => {
  if (Platform.OS === 'android') {
    return await CaptureProtectionAndroidModule?.prevent?.();
  }
  if (Platform.OS === 'ios') {
    const {
      record = false,
      appSwitcher = false,
      screenshot = false,
    } = option ?? {
      record: true,
      appSwitcher: true,
      screenshot: true,
    };

    if (screenshot) {
      await CaptureProtectionIOSModule?.preventScreenShot?.();
    }

    if (appSwitcher) {
      if (typeof appSwitcher === 'boolean') {
        await CaptureProtectionIOSModule?.preventAppSwitcher?.();
      } else if (typeof appSwitcher === 'object') {
        if ('image' in appSwitcher) {
          await CaptureProtectionIOSModule?.preventAppSwitcherWithImage?.(
            appSwitcher.image
          );
        } else {
          await CaptureProtectionIOSModule?.preventAppSwitcherWithText?.(
            appSwitcher.text,
            appSwitcher?.textColor,
            appSwitcher?.backgroundColor
          );
        }
      }
    }

    if (record) {
      if (typeof record === 'boolean') {
        await CaptureProtectionIOSModule?.preventScreenRecord?.();
      } else if (typeof record === 'object') {
        if ('image' in record) {
          await CaptureProtectionIOSModule?.preventScreenRecordWithImage?.(
            record.image
          );
        } else {
          await CaptureProtectionIOSModule?.preventScreenRecordWithText?.(
            record.text,
            record?.textColor,
            record?.backgroundColor
          );
        }
      }
    }
  }
};

const protectionStatus: CaptureProtectionFunction['protectionStatus'] =
  async () => {
    if (Platform.OS === 'android') {
      const status = await CaptureProtectionAndroidModule?.protectionStatus?.();
      return {
        record: status,
        appSwitcher: status,
        screenshot: status,
      };
    }
    if (Platform.OS === 'ios') {
      return await CaptureProtectionIOSModule?.protectionStatus?.();
    }
    return { record: undefined, appSwitcher: undefined, screenshot: undefined };
  };

const hasListener: CaptureProtectionFunction['hasListener'] = async () => {
  if (Platform.OS === 'android') {
    return await CaptureProtectionAndroidModule?.hasListener?.();
  }
  if (Platform.OS === 'ios') {
    return await CaptureProtectionIOSModule?.hasListener?.();
  }
  return undefined;
};

const addListener: CaptureProtectionFunction['addListener'] = (callback) => {
  if (!isPlatformSupported) {
    return;
  }
  return CaptureNotificationEmitter?.addListener?.(
    CaptureProtectionEventType,
    callback
  );
};

const removeListener: CaptureProtectionFunction['removeListener'] = async (
  emitter
) => {
  if (!isPlatformSupported) {
    return;
  }
  if (emitter) {
    emitter.remove();
  }
};

const isScreenRecording: CaptureProtectionFunction['isScreenRecording'] =
  async () => {
    if (Platform.OS === 'android') {
      return await CaptureProtectionAndroidModule?.isScreenRecording?.();
    }
    if (Platform.OS === 'ios') {
      return await CaptureProtectionIOSModule?.isScreenRecording?.();
    }
    return undefined;
  };

const requestPermission: CaptureProtectionFunction['requestPermission'] =
  async () => {
    if (Platform.OS !== 'android') {
      console.warn(
        '[react-native-capture-protection] requestPermission is only available on Android'
      );
      return false;
    }

    try {
      return await CaptureProtectionAndroidModule?.requestPermission?.();
    } catch (e) {
      console.error(
        '[react-native-capture-protection] requestPermission throw error',
        e
      );
      return false;
    }
  };

export const CaptureProtection: CaptureProtectionFunction = {
  addListener,
  hasListener,
  isScreenRecording,
  requestPermission,
  allow,
  prevent,
  removeListener,
  protectionStatus,
};
