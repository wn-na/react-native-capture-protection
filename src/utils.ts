import { CaptureProtectionModuleStatus } from './type';

export const isCapturedStatus = (
  status: CaptureProtectionModuleStatus | undefined
) => {
  return (
    status === CaptureProtectionModuleStatus.RECORD_DETECTED_START ||
    status === CaptureProtectionModuleStatus.CAPTURE_DETECTED
  );
};
