import { useEffect, useState } from 'react';
import { CaptureProtection } from './modules';
import { CaptureEventType } from './type';

const useCaptureDetection = (option?: { delay?: number }) => {
  const [status, setStatus] = useState<CaptureEventType>(CaptureEventType.NONE);

  useEffect(() => {
    let timer: NodeJS.Timeout | null = null;
    CaptureProtection.addListener((eventType) => {
      setStatus(eventType);
      if (eventType === CaptureEventType.CAPTURED) {
        timer = setTimeout(
          () => setStatus(CaptureEventType.NONE),
          option?.delay || 1000
        );
      }
    });
    return () => {
      CaptureProtection.removeListener();
      if (timer) {
        clearTimeout(timer);
      }
    };
  }, [option?.delay]);

  return { status };
};

export { useCaptureDetection };
