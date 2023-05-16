/* eslint-disable react-hooks/exhaustive-deps */
import * as React from 'react';
import { StyleSheet, View, Text } from 'react-native';
import {
  CaptureProtectionModuleStatus,
  useCaptureProtection,
} from 'react-native-capture-protection';

export default function SecretContent() {
  const { isPrevent, status, bindProtection, releaseProtection } =
    useCaptureProtection();

  React.useEffect(() => {
    bindProtection();
    return () => {
      releaseProtection(true);
    };
  }, []);

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
      <Text>it is Screct View!!</Text>
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
