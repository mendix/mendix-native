import { describe, test, expect } from 'react-native-harness';
import { NativeFileSystem } from 'mendix-native';

describe('NativeFileSystem', () => {
  const testFile = 'test-file.txt';

  describe('Constants', () => {
    test('should have constants defined', () => {
      const documentDirectory = NativeFileSystem.DocumentDirectoryPath;
      const relativePath =
        NativeFileSystem.relativeToDocumentsAbsolutePath(testFile);
      expect(typeof documentDirectory).toBe('string');
      expect(documentDirectory.length).toBeGreaterThan(0);
      expect(relativePath).toBe(`${documentDirectory}/${testFile}`);
      expect(NativeFileSystem.SUPPORTS_DIRECTORY_MOVE).toBe(true);
      expect(NativeFileSystem.SUPPORTS_ENCRYPTION).toBe(true);
    });
  });

  describe('fileExists', () => {
    test('should return false for non-existent file', async () => {
      const exists = await NativeFileSystem.fileExists(
        NativeFileSystem.relativeToDocumentsAbsolutePath(
          'non-existent-file.txt'
        )
      );
      expect(exists).toBe(false);
    });

    test('should throw for non white listed path', async () => {
      try {
        await NativeFileSystem.fileExists(testFile);
        expect(true).toBe(false); // This should not be reached
      } catch (error: any) {
        const errorMessage =
          'Path needs to be an absolute path to the apps accessible space.';
        expect(error.message).contains(errorMessage);
      }
    });

    test('should return true for created file', async () => {
      // Create a test file first using writeJson
      const testPath =
        NativeFileSystem.relativeToDocumentsAbsolutePath('exists-test.json');
      await NativeFileSystem.writeJson({ test: 'data' }, testPath);

      const exists = await NativeFileSystem.fileExists(testPath);
      expect(exists).toBe(true);

      // Cleanup
      await NativeFileSystem.remove(testPath);
    });
  });

  describe('writeJson and readJson', () => {
    test('should write and read JSON object', async () => {
      const testData = { name: 'John', age: 30, active: true };
      const filePath =
        NativeFileSystem.relativeToDocumentsAbsolutePath('test-object.json');

      await NativeFileSystem.writeJson(testData, filePath);
      const readData =
        await NativeFileSystem.readJson<typeof testData>(filePath);

      expect(readData).toEqual(testData);

      // Cleanup
      await NativeFileSystem.remove(filePath);
    });

    test('should handle nested JSON structures', async () => {
      const testData = {
        user: {
          name: 'Alice',
          address: {
            street: '123 Main St',
            city: 'Springfield',
          },
        },
        items: [1, 2, 3],
      };
      const filePath =
        NativeFileSystem.relativeToDocumentsAbsolutePath('test-nested.json');

      await NativeFileSystem.writeJson(testData, filePath);
      const readData =
        await NativeFileSystem.readJson<typeof testData>(filePath);

      expect(readData).toEqual(testData);

      // Cleanup
      await NativeFileSystem.remove(filePath);
    });

    test('should handle empty object', async () => {
      const testData = {};
      const filePath =
        NativeFileSystem.relativeToDocumentsAbsolutePath('test-empty.json');

      await NativeFileSystem.writeJson(testData, filePath);
      const readData = await NativeFileSystem.readJson(filePath);

      expect(readData).toEqual(testData);

      // Cleanup
      await NativeFileSystem.remove(filePath);
    });

    test('should overwrite existing file', async () => {
      const filePath = NativeFileSystem.relativeToDocumentsAbsolutePath(
        'test-overwrite.json'
      );

      await NativeFileSystem.writeJson({ version: 1 }, filePath);
      await NativeFileSystem.writeJson({ version: 2 }, filePath);

      const readData = await NativeFileSystem.readJson<{ version: number }>(
        filePath
      );
      expect(readData).toEqual({ version: 2 });

      // Cleanup
      await NativeFileSystem.remove(filePath);
    });
  });

  describe('remove', () => {
    test('should remove existing file', async () => {
      const filePath =
        NativeFileSystem.relativeToDocumentsAbsolutePath('test-remove.json');

      await NativeFileSystem.writeJson({ test: 'data' }, filePath);
      await NativeFileSystem.remove(filePath);

      const exists = await NativeFileSystem.fileExists(filePath);
      expect(exists).toBe(false);
    });

    test('should handle removing non-existent file', async () => {
      const filePath =
        NativeFileSystem.relativeToDocumentsAbsolutePath('non-existent.json');

      // Should not throw error
      await expect(NativeFileSystem.remove(filePath)).resolves.not.toThrow();
    });
  });

  describe('move', () => {
    test('should move file to new location', async () => {
      const sourcePath =
        NativeFileSystem.relativeToDocumentsAbsolutePath('source-file.json');
      const destPath =
        NativeFileSystem.relativeToDocumentsAbsolutePath('dest-file.json');

      const testData = { moved: true };
      await NativeFileSystem.writeJson(testData, sourcePath);
      await NativeFileSystem.move(sourcePath, destPath);

      const sourceExists = await NativeFileSystem.fileExists(sourcePath);
      const destExists = await NativeFileSystem.fileExists(destPath);

      expect(sourceExists).toBe(false);
      expect(destExists).toBe(true);

      const readData =
        await NativeFileSystem.readJson<typeof testData>(destPath);
      expect(readData).toEqual(testData);

      // Cleanup
      await NativeFileSystem.remove(destPath);
    });

    test('should preserve file content after move', async () => {
      const sourcePath =
        NativeFileSystem.relativeToDocumentsAbsolutePath('original.json');
      const destPath =
        NativeFileSystem.relativeToDocumentsAbsolutePath('moved.json');

      const testData = { name: 'Test', values: [1, 2, 3] };
      await NativeFileSystem.writeJson(testData, sourcePath);
      await NativeFileSystem.move(sourcePath, destPath);

      const readData =
        await NativeFileSystem.readJson<typeof testData>(destPath);
      expect(readData).toEqual(testData);

      // Cleanup
      await NativeFileSystem.remove(destPath);
    });
  });

  describe('list', () => {
    test('should list files in directory', async () => {
      const dirPath = NativeFileSystem.DocumentDirectoryPath;
      const files = await NativeFileSystem.list(dirPath);

      expect(Array.isArray(files)).toBe(true);
    });

    test('should return array of strings', async () => {
      const dirPath = NativeFileSystem.DocumentDirectoryPath;
      const files = await NativeFileSystem.list(dirPath);

      files.forEach((file) => {
        expect(typeof file).toBe('string');
      });
    });
  });

  describe('relativeToDocumentsAbsolutePath', () => {
    test('should convert relative path to absolute', () => {
      const relativePath = 'test-file.txt';
      const absolutePath =
        NativeFileSystem.relativeToDocumentsAbsolutePath(relativePath);

      expect(absolutePath).toContain(NativeFileSystem.DocumentDirectoryPath);
      expect(absolutePath).toContain(relativePath);
    });

    test('should return same path if already absolute', () => {
      const absolutePath = `${NativeFileSystem.DocumentDirectoryPath}/test.txt`;
      const result =
        NativeFileSystem.relativeToDocumentsAbsolutePath(absolutePath);

      expect(result).toBe(absolutePath);
    });

    test('should handle nested paths', () => {
      const relativePath = 'folder/subfolder/file.txt';
      const absolutePath =
        NativeFileSystem.relativeToDocumentsAbsolutePath(relativePath);

      expect(absolutePath).toContain(NativeFileSystem.DocumentDirectoryPath);
      expect(absolutePath).toContain('folder/subfolder/file.txt');
    });
  });

  describe('setEncryptionEnabled', () => {
    test('should call setEncryptionEnabled with true', () => {
      expect(() => {
        NativeFileSystem.setEncryptionEnabled(true);
      }).not.toThrow();
    });

    test('should call setEncryptionEnabled with false', () => {
      expect(() => {
        NativeFileSystem.setEncryptionEnabled(false);
      }).not.toThrow();
    });

    test('should be callable multiple times', () => {
      expect(() => {
        NativeFileSystem.setEncryptionEnabled(true);
        NativeFileSystem.setEncryptionEnabled(false);
        NativeFileSystem.setEncryptionEnabled(true);
      }).not.toThrow();
    });
  });

  describe('getFileSize', () => {
    test('should throw for non-existent file', async () => {
      const filePath = NativeFileSystem.relativeToDocumentsAbsolutePath(
        'non-existent-size.bin'
      );
      try {
        await NativeFileSystem.getFileSize(filePath);
        expect(true).toBe(false);
      } catch (error: any) {
        expect(error.message).contains('File does not exist');
      }
    });

    test('should return 0 for existing empty file', async () => {
      const filePath =
        NativeFileSystem.relativeToDocumentsAbsolutePath('empty-size.bin');
      await NativeFileSystem.writeChunk('', filePath, 0);

      const size = await NativeFileSystem.getFileSize(filePath);
      expect(size).toBe(0);

      await NativeFileSystem.remove(filePath);
    });

    test('should return correct size for existing file', async () => {
      const filePath =
        NativeFileSystem.relativeToDocumentsAbsolutePath('size-test.json');
      const testData = { hello: 'world' };
      await NativeFileSystem.writeJson(testData, filePath);

      const size = await NativeFileSystem.getFileSize(filePath);
      expect(size).toBeGreaterThan(0);

      await NativeFileSystem.remove(filePath);
    });

    test('should throw for non white listed path', async () => {
      try {
        await NativeFileSystem.getFileSize('invalid-path.bin');
        expect(true).toBe(false);
      } catch (error: any) {
        const errorMessage =
          'Path needs to be an absolute path to the apps accessible space.';
        expect(error.message).contains(errorMessage);
      }
    });
  });

  describe('writeChunk', () => {
    test('should create file and write first chunk with base64', async () => {
      const filePath =
        NativeFileSystem.relativeToDocumentsAbsolutePath('chunk-test.bin');

      await NativeFileSystem.remove(filePath);

      const data = new Uint8Array([1, 2, 3, 4, 5]);
      const base64 = btoa(String.fromCharCode(...Array.from(data)));
      await NativeFileSystem.writeChunk(base64, filePath, 0);

      const size = await NativeFileSystem.getFileSize(filePath);
      expect(size).toBe(5);

      await NativeFileSystem.remove(filePath);
    });

    test('should append chunk at offset with base64', async () => {
      const filePath = NativeFileSystem.relativeToDocumentsAbsolutePath(
        'chunk-append-test.bin'
      );

      await NativeFileSystem.remove(filePath);

      const chunk1 = new Uint8Array([1, 2, 3, 4, 5]);
      const chunk2 = new Uint8Array([6, 7, 8, 9, 10]);

      const base64Chunk1 = btoa(String.fromCharCode(...Array.from(chunk1)));
      const base64Chunk2 = btoa(String.fromCharCode(...Array.from(chunk2)));

      await NativeFileSystem.writeChunk(base64Chunk1, filePath, 0);
      await NativeFileSystem.writeChunk(base64Chunk2, filePath, 5);

      const size = await NativeFileSystem.getFileSize(filePath);
      expect(size).toBe(10);

      await NativeFileSystem.remove(filePath);
    });

    test('should throw for non white listed path', async () => {
      const base64 = btoa(String.fromCharCode(1, 2, 3));
      try {
        await NativeFileSystem.writeChunk(base64, 'invalid-path.bin', 0);
        expect(true).toBe(false);
      } catch (error: any) {
        const errorMessage =
          'Path needs to be an absolute path to the apps accessible space.';
        expect(error.message).contains(errorMessage);
      }
    });
  });

  describe('API methods exist', () => {
    test('should have read method', () => {
      expect(typeof NativeFileSystem.read).toBe('function');
    });

    test('should have readAsDataURL method', () => {
      expect(typeof NativeFileSystem.readAsDataURL).toBe('function');
    });

    test('should have readAsText method', () => {
      expect(typeof NativeFileSystem.readAsText).toBe('function');
    });

    test('should have save method', () => {
      expect(typeof NativeFileSystem.save).toBe('function');
    });

    test('should have getFileSize method', () => {
      expect(typeof NativeFileSystem.getFileSize).toBe('function');
    });

    test('should have writeChunk method', () => {
      expect(typeof NativeFileSystem.writeChunk).toBe('function');
    });
  });
});
