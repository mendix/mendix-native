import { Text, View, StyleSheet } from 'react-native';
import { NativeDownloadHandler, NativeFileSystem } from 'mendix-native';

const downloadPath = NativeFileSystem.relativeToDocumentsAbsolutePath(
  'downloads/invalid-url.txt'
);

export default function App() {
  const download = async () => {
    const exists = await NativeFileSystem.fileExists(downloadPath);
    if (exists) {
      await NativeFileSystem.remove(downloadPath);
    }

    const config = {
      connectionTimeout: 25,
      mimeType: 'text/plain',
    };

    try {
      await NativeDownloadHandler.download(
        '://definitely-invalid-url',
        downloadPath,
        config
      );
    } catch (error) {
      console.error('Download failed as expected:', error);
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.archContainer}>
        <Text onPress={download}>Download</Text>
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
