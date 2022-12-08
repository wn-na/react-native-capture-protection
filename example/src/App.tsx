import * as React from 'react';
import { StyleSheet, View, Button } from 'react-native';
import {
  CaptureProtection,
  CaptureProtectionModuleStatus,
} from 'react-native-capture-protection';
export default function App() {
  React.useEffect(() => {
    CaptureProtection.addEventListener(({ status, isPrevent }) => {
      console.log(
        'CaptureProtection => ',
        CaptureProtectionModuleStatus[status],
        isPrevent
      );
    });
  }, []);

  return (
    <View style={styles.container}>
      <Button
        title="set Record Protect Screen by Text"
        onPress={() => {
          CaptureProtection.setScreenRecordScreenWithText?.('TEST!');
        }}
      />
      <Button
        title="set Record Protect Screen by Image"
        onPress={() => {
          CaptureProtection.setScreenRecordScreenWithImage?.(
            require('../src/test.png')
          );
        }}
      />
      <Button
        title="allow Record"
        onPress={() => {
          CaptureProtection.allowScreenRecord();
        }}
      />
      <Button
        title="prevent Record"
        onPress={() => {
          CaptureProtection.preventScreenRecord();
        }}
      />
      <Button
        title="allow Screenshot"
        onPress={() => {
          CaptureProtection.allowScreenshot();
        }}
      />
      <Button
        title="prevent Screenshot"
        onPress={() => {
          CaptureProtection.preventScreenshot();
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
