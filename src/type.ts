export enum CaptureEventType {
  NONE,
  RECORDING,
  END_RECORDING,
  CAPTURED,
  APP_SWITCHING,
}

export type CaptureProtectionModuleStatus = {
  screenShot?: boolean;
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
  screenShot?: boolean;
  record?: boolean | IOSProtectionScreenOption;
  appSwitcher?: boolean | IOSProtectionScreenOption;
};

export type AllowOption = {
  screenShot?: boolean;
  record?: boolean;
  appSwitcher?: boolean;
};

export interface CaptureProtectionIOSNativeModules {
  allowScreenShot: () => Promise<void>;
  preventScreenShot: () => Promise<void>;
  allowScreenRecord: () => Promise<void>;
  preventScreenRecord: (
    option?: IOSProtectionCustomScreenOption
  ) => Promise<void>;
  preventScreenRecordWithImage: (image: NodeRequire) => Promise<void>;
  allowAppSwitcher: () => Promise<void>;
  preventAppSwitcher: (
    option?: IOSProtectionCustomScreenOption
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
  prevent: (option?: PreventOption) => void;
  /** If no option is specified, all actions are allow */
  allow: (option?: AllowOption) => void;
  addListener: (callback: (eventType: CaptureEventType) => void) => void;
  removeListener: () => void;
  hasListener: () => Promise<boolean | undefined>;
  protectionStatus: () => Promise<CaptureProtectionModuleStatus>;
  isScreenRecording: () => Promise<boolean | undefined>;
  requestPermission: () => Promise<boolean>;
}

export type CaptureProtectionContextType = {
  protectionStatus: CaptureProtectionModuleStatus;
  status: CaptureEventType;
  prevent: () => Promise<void>;
  allow: () => Promise<void>;
};
