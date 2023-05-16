import {
  Image,
  NativeEventEmitter,
  NativeModules,
  Platform,
} from 'react-native';
import {
  CaptureEventListenerCallback,
  CaptureEventStatus,
  CaptureProtectionModuleStatus,
} from './type';
import React, {
  createContext,
  useContext,
  useEffect,
  useRef,
  useState,
} from 'react';

const LINKING_ERROR =
  `The package 'react-native-capture-protection' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const CaptureProtectionModule = NativeModules.CaptureProtection
  ? NativeModules.CaptureProtection
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

const CaptureNotificationEmitter =
  Platform.OS === 'ios'
    ? new NativeEventEmitter(CaptureProtectionModule)
    : undefined;

const CaptureProtectionEventType = 'CaptureProtectionListener' as const;
/**
 *
 *  **This function only work in `iOS`**
 *
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
    CaptureProtectionEventType,
    callback
  );
}

/**
 *  **This function only work in `iOS`**
 *
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
 *  **This function only work in `iOS`**
 *
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
  if (Platform.OS === 'android') {
    return await CaptureProtectionModule?.allowScreenshot?.();
  }
  if (Platform.OS === 'ios') {
    return await CaptureProtectionModule?.allowScreenRecord?.(removeListener);
  }
  return undefined;
};

/**
 *  prevent screen record
 *
 *  if detect screen record, screen will be change protect screen (setting with `setScreenRecordScreenWithText` or `setScreenRecordScreenWithImage`)
 *
 * if `isImmediate` is `true`, screen is already recording, change immediate, default is `false`
 */
const preventScreenRecord = async (isImmediate = false): Promise<void> => {
  if (Platform.OS === 'android') {
    return await CaptureProtectionModule?.preventScreenshot?.();
  }
  if (Platform.OS === 'ios') {
    return await CaptureProtectionModule?.preventScreenRecord?.(isImmediate);
  }
  return undefined;
};

/**
 *  allow screenshot
 *
 * - if `removeListener` is `true`, listener will be removed else listener is alive, default is `false`
 */
const allowScreenshot = async (removeListener = false): Promise<void> => {
  if (Platform.OS === 'android') {
    return await CaptureProtectionModule?.allowScreenshot?.();
  }
  if (Platform.OS === 'ios') {
    return await CaptureProtectionModule?.allowScreenshot?.(removeListener);
  }
  return undefined;
};

/**
 *  prevent screenshot
 *
 * if user take screenshot, screenshot image will be black screen
 */
const preventScreenshot = async (): Promise<void> => {
  if (Platform.OS === 'android') {
    return await CaptureProtectionModule?.preventScreenshot?.();
  }
  if (Platform.OS === 'ios') {
    return await CaptureProtectionModule?.preventScreenshot?.();
  }
  return undefined;
};

/**
 *  **This function only work in `iOS`**
 *
 *  add only screen record event listener
 */
const addScreenRecordListener = async (): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.addScreenRecordListener?.();
};

/**
 *  **This function only work in `iOS`**
 *
 *  remove only screen record event listener
 */
const removeScreenRecordListener = async (): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.removeScreenRecordListener?.();
};

/**
 *  **This function only work in `iOS`**
 *
 *  add only screenshot event listener
 */
const addScreenshotListener = async (): Promise<void> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.addScreenshotListener?.();
};

/**
 *  **This function only work in `iOS`**
 *
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

/**
 *  **This function only work in `iOS`**
 *
 * return listener regist status */
const hasListener = async (): Promise<CaptureEventStatus | undefined> => {
  if (Platform.OS !== 'ios') {
    return;
  }
  return await CaptureProtectionModule?.hasListener?.();
};

/**
 *  **This function only work in `iOS`**
 *
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

/**
 * return prevent status
 */
const getPreventStatus = async (): Promise<CaptureEventStatus | undefined> => {
  if (Platform.OS === 'android') {
    return await CaptureProtectionModule?.getPreventStatus?.();
  }
  if (Platform.OS === 'ios') {
    return await CaptureProtectionModule?.getPreventStatus?.();
  }
  return undefined;
};

export const useCaptureProtectionFunction = () => {
  const [status, setStatus] = useState<CaptureProtectionModuleStatus>();
  const [isPrevent, setPrevent] = useState<CaptureEventStatus>();
  useEffect(() => {
    hasListener().then((listener) => {
      if (!listener?.record && !listener?.screenshot) {
        addScreenRecordListener();
        addScreenshotListener();
      }
    });

    addEventListener((callback) => {
      setPrevent(callback.isPrevent);
      setStatus(
        callback.status === CaptureProtectionModuleStatus.UNKNOWN
          ? undefined
          : callback.status
      );
      if (callback.status === CaptureProtectionModuleStatus.CAPTURE_DETECTED) {
        setTimeout(() => setStatus(undefined), 1000);
      }
    });
  }, []);

  const allowScreenshotFunc = () => allowScreenshot();
  const allowScreenRecordFunc = () => allowScreenRecord();

  return {
    isPrevent,
    /** if Capture detect, status will change `CaptureProtectionModuleStatus.CAPTURE_DETECTED` to unknown in `1000ms` */
    status,
    allowScreenshot: allowScreenshotFunc,
    preventScreenshot,
    allowScreenRecord: allowScreenRecordFunc,
    preventScreenRecord,
  };
};

const CaptureProtectionContext = createContext<{
  isPrevent: CaptureEventStatus | undefined;
  /** if Capture detect, status will change `CaptureProtectionModuleStatus.CAPTURE_DETECTED` to unknown in `1000ms` */
  status: CaptureProtectionModuleStatus | undefined;
  /** prevent all capture, record event */
  bindProtection: () => Promise<void>;
  /** if use `rollback`, status will change before use `bindProtection` */
  releaseProtection: (rollback?: boolean) => Promise<void>;
}>({
  isPrevent: undefined,
  status: undefined,
  bindProtection: async () => undefined,
  releaseProtection: async () => undefined,
});

/**
 * Capture Protection Context API
 *
 * use hook `useCaptureProtection`
 * 
 * if Platform is Android, `status`, `isPrevent` may not be the case
 *
 */
export const CaptureProtectionProvider = ({ children }: any) => {
  const [status, setStatus] = useState<CaptureProtectionModuleStatus>();
  const [isPrevent, setPrevent] = useState<CaptureEventStatus>();

  const beforePrevent = useRef<CaptureEventStatus>();

  const bindProtection = async () => {
    if (isPrevent) {
      beforePrevent.current = { ...isPrevent };
    }
    if (Platform.OS === 'android') {
      const realPreventStatus = await getPreventStatus();
      if (realPreventStatus) {
        beforePrevent.current = { ...realPreventStatus };
      }
    }
    preventScreenRecord(true);
    preventScreenshot();
  };

  const releaseProtection = async (rollback?: boolean) => {
    if (rollback) {
      if (!beforePrevent.current?.record) {
        allowScreenRecord();
      }
      if (!beforePrevent.current?.screenshot) {
        allowScreenshot();
      }
      beforePrevent.current = undefined;
    } else {
      allowScreenRecord();
      allowScreenshot();
    }
  };

  useEffect(() => {
    addScreenRecordListener();
    addScreenshotListener();

    getPreventStatus().then((prevent) => {
      setPrevent(prevent);
    });

    isScreenRecording().then((recording) => {
      if (recording) {
        setStatus(CaptureProtectionModuleStatus.RECORD_DETECTED_START);
      }
    });

    addEventListener((callback) => {
      setPrevent({ ...callback.isPrevent });
      setStatus(
        callback.status === CaptureProtectionModuleStatus.UNKNOWN
          ? undefined
          : callback.status
      );
      if (callback.status === CaptureProtectionModuleStatus.CAPTURE_DETECTED) {
        setTimeout(() => setStatus(undefined), 1000);
      }
    });
    return () => {
      CaptureNotificationEmitter?.removeAllListeners(
        CaptureProtectionEventType
      );
    };
  }, []);

  return (
    <CaptureProtectionContext.Provider
      value={{ isPrevent, status, bindProtection, releaseProtection }}
    >
      <>{children}</>
    </CaptureProtectionContext.Provider>
  );
};

export const useCaptureProtection = () => useContext(CaptureProtectionContext);

export const CaptureProtection = {
  addEventListener,
  setScreenRecordScreenWithText,
  setScreenRecordScreenWithImage,
  allowScreenshot,
  preventScreenshot,
  allowScreenRecord,
  preventScreenRecord,
  /**
   * @deprecated
   */
  addScreenshotListener,
  /**
   * @deprecated
   */
  removeScreenshotListener,
  /**
   * @deprecated
   */
  addScreenRecordListener,
  /**
   * @deprecated
   */
  removeScreenRecordListener,
  /**
   * @deprecated
   */
  hasListener,
  isScreenRecording,
  getPreventStatus,
  useCaptureProtection: useCaptureProtectionFunction,
};

export { CaptureProtectionModuleStatus, CaptureEventStatus } from './type';
