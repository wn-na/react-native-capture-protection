import { NativeEventEmitter, NativeModules, Platform } from 'react-native';
import {
  CaptureProtectionAndroidNativeModules,
  CaptureProtectionFunction,
  CaptureProtectionIOSNativeModules,
  IOSProtectionCustomScreenOption,
} from './type';

const CaptureProtectionModule = NativeModules?.CaptureProtection ?? {};

const CaptureProtectionAndroidModule =
  CaptureProtectionModule as CaptureProtectionAndroidNativeModules;
const CaptureProtectionIOSModule =
  CaptureProtectionModule as CaptureProtectionIOSNativeModules;

const CaptureNotificationEmitter =
  Platform.OS === 'ios' || Platform.OS === 'android'
    ? new NativeEventEmitter(CaptureProtectionModule)
    : undefined;

const CaptureProtectionEventType = 'CaptureProtectionListener' as const;

const allow: CaptureProtectionFunction['allow'] = async (option) => {
  if (Platform.OS === 'android') {
    return await CaptureProtectionAndroidModule?.allow?.();
  }
  if (Platform.OS === 'ios') {
    const {
      record = true,
      appSwitcher = true,
      screenShot = true,
    } = option ?? {};

    if (screenShot) {
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
      record = true,
      appSwitcher = true,
      screenShot = true,
    } = option ?? {};

    if (screenShot) {
      await CaptureProtectionIOSModule?.preventScreenShot?.();
    }

    if (appSwitcher) {
      if (typeof appSwitcher === 'boolean') {
        await CaptureProtectionIOSModule?.preventAppSwitcher?.();
      } else if (typeof appSwitcher === 'object') {
        if ('image' in appSwitcher) {
          await CaptureProtectionIOSModule?.preventAppSwitcherWithImage?.(
            (appSwitcher as any).image
          );
        } else {
          await CaptureProtectionIOSModule?.preventAppSwitcher?.(
            appSwitcher as IOSProtectionCustomScreenOption
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
            (record as any).image
          );
        } else {
          await CaptureProtectionIOSModule?.preventScreenRecord?.(
            record as IOSProtectionCustomScreenOption
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
        screenShot: status,
      };
    }
    if (Platform.OS === 'ios') {
      return await CaptureProtectionIOSModule?.protectionStatus?.();
    }
    return { record: undefined, appSwitcher: undefined, screenShot: undefined };
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
  if (Platform.OS !== 'ios' && Platform.OS !== 'android') {
    return;
  }
  CaptureNotificationEmitter?.addListener?.(
    CaptureProtectionEventType,
    callback
  );
};

const removeListener: CaptureProtectionFunction['removeListener'] =
  async () => {
    if (Platform.OS !== 'ios' && Platform.OS !== 'android') {
      return;
    }
    CaptureNotificationEmitter?.removeAllListeners?.(
      CaptureProtectionEventType
    );
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
    if (Platform.OS === 'android') {
      try {
        return await CaptureProtectionAndroidModule?.requestPermission?.();
      } catch (e) {
        console.error(
          '[react-native-capture-protection] requestPermission throw error',
          e
        );
        return false;
      }
    } else {
      console.warn(
        '[react-native-capture-protection] requestPermission is only available on Android'
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
