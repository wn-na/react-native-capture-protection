import { EmitterSubscription } from 'react-native';

export enum CaptureEventType {
  NONE,
  RECORDING,
  END_RECORDING,
  CAPTURED,
  APP_SWITCHING,
  UNKNOWN,
  ALLOW = 8,
  PREVENT_SCREEN_CAPTURE = 16,
  PREVENT_SCREEN_RECORDING = 32,
  PREVENT_SCREEN_APP_SWITCHING = 64,
}

export type CaptureProtectionModuleStatus = {
  screenshot?: boolean;
  record?: boolean;
  appSwitcher?: boolean;
};

export type IOSProtectionCustomScreenOption = {
  text: string;
  textColor?: `#${string}`;
  backgroundColor?: `#${string}`;
};

export type IOSProtectionScreenOption =
  | {
      image: NodeRequire;
    }
  | IOSProtectionCustomScreenOption;

export type PreventOption = {
  screenshot?: boolean;
  record?: boolean | IOSProtectionScreenOption;
  appSwitcher?: boolean | IOSProtectionScreenOption;
};

export type AllowOption = {
  screenshot?: boolean;
  record?: boolean;
  appSwitcher?: boolean;
};

export type CaptureEventCallback = (eventType: CaptureEventType) => void;

export interface CaptureProtectionIOSNativeModules {
  allowScreenshot: () => Promise<void>;
  preventScreenshot: () => Promise<void>;
  allowScreenRecord: () => Promise<void>;
  preventScreenRecord: () => Promise<void>;
  preventScreenRecordWithText: (
    text: string,
    textColor?: `#${string}`,
    backgroundColor?: `#${string}`
  ) => Promise<void>;
  preventScreenRecordWithImage: (image: NodeRequire) => Promise<void>;
  allowAppSwitcher: () => Promise<void>;
  preventAppSwitcher: () => Promise<void>;
  preventAppSwitcherWithText: (
    text: string,
    textColor?: `#${string}`,
    backgroundColor?: `#${string}`
  ) => Promise<void>;
  preventAppSwitcherWithImage: (image: NodeRequire) => Promise<void>;
  hasListener: () => Promise<boolean>;
  protectionStatus: () => Promise<CaptureProtectionModuleStatus>;
  isScreenRecording: () => Promise<boolean | undefined>;
}
export interface CaptureProtectionAndroidNativeModules {
  allow: () => Promise<void>;
  prevent: () => Promise<void>;
  hasListener: () => Promise<boolean>;
  protectionStatus: () => Promise<boolean>;
  isScreenRecording: () => Promise<boolean | undefined>;
  requestPermission: () => Promise<boolean>;
  checkPermission: () => Promise<boolean>;
}

export interface CaptureProtectionFunction {
  /** If no option is specified, all actions are prevent */
  prevent: (option?: PreventOption) => Promise<void>;
  /** If no option is specified, all actions are allow */
  allow: (option?: AllowOption) => Promise<void>;
  addListener: (
    callback: CaptureEventCallback
  ) => EmitterSubscription | undefined;
  removeListener: (emitter: EmitterSubscription) => void;
  hasListener: () => Promise<boolean | undefined>;
  protectionStatus: () => Promise<CaptureProtectionModuleStatus>;
  isScreenRecording: () => Promise<boolean | undefined>;
  requestPermission: () => Promise<boolean>;
}

export type CaptureProtectionContextType = {
  protectionStatus: CaptureProtectionModuleStatus;
  status: CaptureEventType;
  prevent: CaptureProtectionFunction['prevent'];
  allow: CaptureProtectionFunction['allow'];
};
