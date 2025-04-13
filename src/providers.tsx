import React, { createContext, PropsWithChildren, useContext } from 'react';
import { useCaptureDetection } from './hooks';
import { CaptureProtection } from './modules';
import {
  AllowOption,
  CaptureEventType,
  CaptureProtectionContextType,
  PreventOption,
} from './type';

const CaptureProtectionContext = createContext<CaptureProtectionContextType>({
  protectionStatus: { screenshot: false, record: false, appSwitcher: false },
  status: CaptureEventType.NONE,
  prevent: async () => undefined,
  allow: async () => undefined,
});

const CaptureProtectionProvider = ({ children }: PropsWithChildren<{}>) => {
  const { protectionStatus, status } = useCaptureDetection();

  const prevent = async (option?: PreventOption) => {
    CaptureProtection.prevent(option);
  };

  const allow = async (allowOption?: AllowOption) => {
    CaptureProtection.allow(allowOption);
  };

  return (
    <CaptureProtectionContext.Provider
      value={{ protectionStatus, status, prevent, allow }}
    >
      <>{children}</>
    </CaptureProtectionContext.Provider>
  );
};

const useCaptureProtection = () => useContext(CaptureProtectionContext);

export { CaptureProtectionProvider, useCaptureProtection };
