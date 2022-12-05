import * as React from 'react';
import { StyleSheet, View, Button, Alert, Text } from 'react-native';
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
      <Text>Record</Text>
      <Button
        title="prevent"
        onPress={() => {
          CaptureProtection.startPreventRecording().then((res) => {
            console.log('startPreventRecording', res);
            Alert.alert(
              'startPreventRecording',
              res ? 'Success' : 'already start'
            );
          });
        }}
      />
      <Button
        title="remove"
        onPress={() => {
          CaptureProtection.stopPreventRecording().then((res) => {
            console.log('stopPreventRecording', res);
            Alert.alert(
              'stopPreventRecording',
              res ? 'Success' : 'already stop'
            );
          });
        }}
      />
      <Text>Screenshot</Text>
      <Button
        title="prevent"
        onPress={() => {
          CaptureProtection.startPreventScreenshot().then((res) => {
            console.log('startPreventScreenshot', res);
            Alert.alert(
              'startPreventScreenshot',
              res ? 'prevent Success' : 'fail'
            );
          });
        }}
      />
      <Button
        title="remove"
        onPress={() => {
          CaptureProtection.stopPreventScreenshot().then((res) => {
            console.log('stopPreventScreenshot', res);
            Alert.alert(
              'stopPreventScreenshot',
              res ? 'remove Success' : 'fail'
            );
          });
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
