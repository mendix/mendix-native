import NativeMxFileSystem, { type BlobData } from './NativeMxFileSystem';

const initFs = () => {
  const {
    DocumentDirectoryPath,
    SUPPORTS_DIRECTORY_MOVE,
    SUPPORTS_ENCRYPTION,
  } = NativeMxFileSystem.constants();
  const docDirPath = DocumentDirectoryPath as string;
  return {
    //Constants
    DocumentDirectoryPath: docDirPath,
    SUPPORTS_DIRECTORY_MOVE: cast<boolean>(SUPPORTS_DIRECTORY_MOVE),
    SUPPORTS_ENCRYPTION: cast<boolean>(SUPPORTS_ENCRYPTION),

    //Methods - signature matches with specs
    read: NativeMxFileSystem.read,
    list: NativeMxFileSystem.list,
    readAsDataURL: NativeMxFileSystem.readAsDataURL,
    readAsText: NativeMxFileSystem.readAsText, //Android only
    fileExists: NativeMxFileSystem.fileExists,
    move: NativeMxFileSystem.move,
    remove: NativeMxFileSystem.remove,
    setEncryptionEnabled: NativeMxFileSystem.setEncryptionEnabled,

    //Methods - signature modified since specs does not recognize Record<string, any> and generics
    save: (blob: BlobData, filePath: string) =>
      NativeMxFileSystem.save(blob, filePath),
    writeJson: (data: Record<string, any>, filepath: string) =>
      NativeMxFileSystem.writeJson(data, filepath),
    readJson: <T>(filepath: string) =>
      NativeMxFileSystem.readJson(filepath) as Promise<T>,

    //Helpers
    relativeToDocumentsAbsolutePath: (path: string) =>
      path.startsWith(docDirPath) ? path : [docDirPath, path].join('/'),
  };
};

const cast = <T>(value: unknown): T | undefined => {
  if (value === undefined || value === null) {
    return undefined;
  }
  return value as T;
};

export const NativeFileSystem = initFs();
