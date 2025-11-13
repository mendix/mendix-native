import Mx, { type BlobData } from './specs/NativeMendixNative';

const initFs = () => {
  const {
    DocumentDirectoryPath,
    SUPPORTS_DIRECTORY_MOVE,
    SUPPORTS_ENCRYPTION,
  } = Mx.fsConstants();
  const docDirPath = DocumentDirectoryPath as string;
  return {
    //Constants
    DocumentDirectoryPath: docDirPath,
    SUPPORTS_DIRECTORY_MOVE: cast<boolean>(SUPPORTS_DIRECTORY_MOVE),
    SUPPORTS_ENCRYPTION: cast<boolean>(SUPPORTS_ENCRYPTION),

    //Methods - signature matches with specs
    read: Mx.fsRead,
    list: Mx.fsList,
    readAsDataURL: Mx.fsReadAsDataURL,
    readAsText: Mx.fsReadAsText, //Android only
    fileExists: Mx.fsFileExists,
    move: Mx.fsMove,
    remove: Mx.fsRemove,
    setEncryptionEnabled: Mx.fsSetEncryptionEnabled,

    //Methods - signature modified since specs does not recognize Record<string, any> and generics
    save: (blob: BlobData, filePath: string) => Mx.fsSave(blob, filePath),
    writeJson: (data: Record<string, any>, filepath: string) =>
      Mx.fsWriteJson(data, filepath),
    readJson: <T>(filepath: string) => Mx.fsReadJson(filepath) as Promise<T>,

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
