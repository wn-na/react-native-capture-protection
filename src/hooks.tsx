import { useEffect, useState } from 'react';
import { CaptureProtection } from './modules';
import {
  CaptureDetectionHookType,
  CaptureEventType,
  CaptureProtectionModuleStatus,
} from './type';

const useCaptureDetection = (): CaptureDetectionHookType => {
  const [status, setStatus] = useState<CaptureEventType>(CaptureEventType.NONE);
  const [protectionStatus, setProtectionStatus] =
    useState<CaptureProtectionModuleStatus>({
      screenshot: false,
      record: false,
      appSwitcher: false,
    });

  useEffect(() => {
    const listener = CaptureProtection.addListener((eventType) => {
      if (eventType < CaptureEventType.ALLOW) {
        setStatus(eventType);
      } else if (eventType === CaptureEventType.ALLOW) {
        setProtectionStatus((_) => ({
          screenshot: false,
          record: false,
          appSwitcher: false,
        }));
      } else if (eventType > CaptureEventType.ALLOW) {
        setProtectionStatus((prev) => ({
          ...prev,
          screenshot: !!(eventType & CaptureEventType.PREVENT_SCREEN_CAPTURE),
          record: !!(eventType & CaptureEventType.PREVENT_SCREEN_RECORDING),
          appSwitcher: !!(
            eventType & CaptureEventType.PREVENT_SCREEN_APP_SWITCHING
          ),
        }));
      }
    });
    return () => {
      listener?.remove?.();
    };
  }, []);

  return { status, protectionStatus };
};

export { useCaptureDetection };
