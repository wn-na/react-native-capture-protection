import React, {
  createContext,
  PropsWithChildren,
  useContext,
  useState,
} from 'react';
import { useCaptureDetection } from './hooks';
import { CaptureProtection } from './modules';
import {
  AllowOption,
  CaptureEventType,
  CaptureProtectionContextType,
  CaptureProtectionModuleStatus,
  PreventOption,
} from './type';

const CaptureProtectionContext = createContext<CaptureProtectionContextType>({
  protectionStatus: { screenShot: false, record: false, appSwitcher: false },
  status: CaptureEventType.NONE,
  prevent: async () => undefined,
  allow: async () => undefined,
});

const CaptureProtectionProvider = ({
  children,
  option,
}: PropsWithChildren<{ option?: PreventOption }>) => {
  const { status } = useCaptureDetection();
  const [protectionStatus, setProtectionStatus] =
    useState<CaptureProtectionModuleStatus>({
      screenShot: false,
      record: false,
      appSwitcher: false,
    });

  const prevent = async () => {
    CaptureProtection.prevent(option);
    const _protectionStatus = await CaptureProtection.protectionStatus();
    setProtectionStatus(_protectionStatus);
  };

  const allow = async (allowOption?: AllowOption) => {
    CaptureProtection.allow(allowOption);
    const _protectionStatus = await CaptureProtection.protectionStatus();
    setProtectionStatus(_protectionStatus);
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
