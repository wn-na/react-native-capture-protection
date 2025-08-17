import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  allow: () => Promise<void>;
  prevent: () => Promise<void>;
  hasListener: () => Promise<boolean>;
  protectionStatus: () => Promise<boolean>;
  isScreenRecording: () => Promise<boolean | undefined>;
  requestPermission: () => Promise<boolean>;
  checkPermission: () => Promise<boolean>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('CaptureProtection');
