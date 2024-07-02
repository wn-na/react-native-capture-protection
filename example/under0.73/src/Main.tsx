import * as React from 'react';
import { StyleSheet, View, Button, Text } from 'react-native';
import {
  CaptureProtection,
  CaptureProtectionModuleStatus,
  useCaptureProtection,
} from 'react-native-capture-protection';
import { useNavigation } from '@react-navigation/native';
export default function Main() {
  const { isPrevent, status } = useCaptureProtection();
  const navigation = useNavigation<any>();

  React.useEffect(() => {
    console.log('Main Prevent Status is', isPrevent);
  }, [isPrevent]);
  React.useEffect(() => {
    console.log(
      'Main Prevent Status is',
      status ? CaptureProtectionModuleStatus?.[status] : undefined
    );
  }, [status]);

  return (
    <View style={styles.container}>
      <Text style={{ color: isPrevent?.record ? 'blue' : 'black' }}>
        {'Record Prevent : ' + isPrevent?.record}
      </Text>
      <Text style={{ color: isPrevent?.screenshot ? 'blue' : 'black' }}>
        {'Screenshot Prevent : ' + isPrevent?.screenshot}
      </Text>
      <Text style={{ color: 'black' }}>
        {'Status : ' +
          (status ? CaptureProtectionModuleStatus?.[status] : undefined)}
      </Text>
      <Button
        title="set Record Protect Screen by Text"
        onPress={() => {
          CaptureProtection.setScreenRecordScreenWithText?.(
            'This is Text Message!'
          );
        }}
      />
      <Button
        title="go to Record Protect Screen"
        onPress={() => {
          navigation.navigate('SecretContent');
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

      <Button
        title="allow background"
        onPress={() => {
          CaptureProtection.allowBackground();
        }}
      />
      <Button
        title="prevent background"
        onPress={() => {
          CaptureProtection.preventBackground();
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
