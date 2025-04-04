import { useEffect, useState } from 'react';
import { CaptureProtection } from './modules';
import { CaptureEventType, CaptureProtectionModuleStatus } from './type';

const useCaptureDetection = () => {
  const [status, setStatus] = useState<CaptureEventType>(CaptureEventType.NONE);
  const [protectionStatus, setProtectionStatus] =
    useState<CaptureProtectionModuleStatus>({
      screenshot: false,
      record: false,
      appSwitcher: false,
    });

  useEffect(() => {
    CaptureProtection.addListener((eventType) => {
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
      CaptureProtection.removeListener();
    };
  }, []);

  return { status, protectionStatus };
};

export { useCaptureDetection };
