import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

type CaptureProtectionModuleStatus = {
  screenshot?: boolean;
  record?: boolean;
  appSwitcher?: boolean;
};

export interface Spec extends TurboModule {
  allowScreenshot: () => Promise<void>;
  preventScreenshot: () => Promise<void>;
  allowScreenRecord: () => Promise<void>;
  preventScreenRecord: () => Promise<void>;
  preventScreenRecordWithText: (
    text: string,
    textColor?: string,
    backgroundColor?: string
  ) => Promise<void>;
  preventScreenRecordWithImage: (
    image: {
      height: number;
      width: number;
      scale: number;
      uri: string;
    },
    backgroundColor?: string,
    contentMode?: number
  ) => Promise<void>;
  allowAppSwitcher: () => Promise<void>;
  preventAppSwitcher: () => Promise<void>;
  preventAppSwitcherWithText: (
    text: string,
    textColor?: string,
    backgroundColor?: string
  ) => Promise<void>;
  preventAppSwitcherWithImage: (
    image: {
      height: number;
      width: number;
      scale: number;
      uri: string;
    },
    backgroundColor?: string,
    contentMode?: number
  ) => Promise<void>;
  hasListener: () => Promise<boolean>;
  protectionStatus: () => Promise<CaptureProtectionModuleStatus>;
  isScreenRecording: () => Promise<boolean | undefined>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('CaptureProtection');
