import * as React from 'react';
import { StyleSheet, View, Button } from 'react-native';
import {
  CaptureProtection,
  CaptureProtectionModuleStatus,
} from 'react-native-capture-protection';

export default function App() {
  React.useEffect(() => {
    CaptureProtection.addRecordEventListener(({ status }) => {
      console.log(
        'initCaptureProtectionModuleListener => ',
        CaptureProtectionModuleStatus[status]
      );
    });
  }, []);

  return (
    <View style={styles.container}>
      <Button
        title="event start"
        onPress={() => {
          CaptureProtection.startPreventRecording().then((res) =>
            console.log('addRecordCaptureProtecter', res)
          );
        }}
      />
      <Button
        title="test"
        onPress={() => {
          CaptureProtection.startPreventScreenshot().then((res) =>
            console.log('startPreventScreenshot', res)
          );
        }}
      />
      <Button
        title="test"
        onPress={() => {
          CaptureProtection.stopPreventScreenshot().then((res) =>
            console.log('stopPreventScreenshot', res)
          );
        }}
      />
      <Button
        title="event end"
        onPress={() => {
          CaptureProtection.stopPreventRecording().then((res) =>
            console.log('removeRecordCaptureProtecter', res)
          );
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
