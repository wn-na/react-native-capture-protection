const CaptureProtectionMock = {
  addListener: jest.fn(),
  hasListener: jest.fn(async () => false),
  isScreenRecording: jest.fn(async () => false),
  requestPermission: jest.fn(async () => true),
  allow: jest.fn(async () => {}),
  prevent: jest.fn(async () => {}),
  removeListener: jest.fn(),
  protectionStatus: jest.fn(async () => true),
};

module.exports = { CaptureProtection: CaptureProtectionMock };
