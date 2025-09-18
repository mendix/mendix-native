import { Text, View, StyleSheet, Button, Alert } from 'react-native';
import {
  NativeReloadHandler,
  NativeCookie,
  onReloadWithStateEvent,
} from 'mendix-native';
import { useEffect } from 'react';

export default function App() {
  useEffect(() => {
    const subscription = onReloadWithStateEvent(() =>
      Alert.alert('Reload event received on JS end')
    );

    return () => {
      subscription.remove();
    };
  }, []);

  const runtime = (global as any).nativeFabricUIManager
    ? 'New Architecture'
    : 'Legacy Architecture';

  return (
    <View style={styles.container}>
      <View style={styles.archContainer}>
        <Text style={styles.text}>{runtime}</Text>
      </View>
      <Button title="Exit App" onPress={() => NativeReloadHandler.exitApp()} />
      <Button title="Reload App" onPress={() => NativeReloadHandler.reload()} />
      <Button title="Clear Cookies" onPress={() => NativeCookie.clearAll()} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  archContainer: {
    position: 'absolute',
    top: 65,
    right: 20,
    padding: 10,
    borderRadius: 8,
    backgroundColor: '#eee',
  },
  text: {
    fontWeight: 'bold',
  },
});
