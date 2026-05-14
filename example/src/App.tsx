import { Text, View, StyleSheet } from 'react-native';
import { AndroidNavigationBar } from 'mendix-native';

export default function App() {
  const runtime = (global as any).nativeFabricUIManager
    ? 'New Architecture'
    : 'Legacy Architecture';

  console.log('Navigation Bar Height:', AndroidNavigationBar.height);
  console.log('Is Navigation Bar Active:', AndroidNavigationBar.isActive);

  return (
    <View style={styles.container}>
      <View style={styles.archContainer}>
        <Text style={styles.text}>{runtime}</Text>
      </View>
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
    padding: 10,
    borderRadius: 8,
    backgroundColor: '#eee',
  },
  text: {
    fontWeight: 'bold',
  },
});
