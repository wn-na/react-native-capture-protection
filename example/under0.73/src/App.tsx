import * as React from 'react';
import { CaptureProtectionProvider } from 'react-native-capture-protection';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import Main from './Main';
import SecretContent from './SecretContent';

const Stack = createNativeStackNavigator();

export default function App() {
  return (
    <CaptureProtectionProvider>
      <NavigationContainer>
        <Stack.Navigator
          initialRouteName={'Main'}
          screenOptions={{ headerShown: false }}
        >
          <Stack.Screen name="Main" component={Main} />
          <Stack.Screen name="SecretContent" component={SecretContent} />
        </Stack.Navigator>
      </NavigationContainer>
    </CaptureProtectionProvider>
  );
}
