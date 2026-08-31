import type { TurboModule, CodegenTypes } from 'react-native';

const TurboModuleRegistry =
  require('react-native/Libraries/TurboModule/TurboModuleRegistry') as {
    getEnforcing: <T extends object>(name: string) => T;
  };

type BlobData = {
  blobId: string;
  offset: number;
  size: number;
  name?: string;
  type?: string;
  lastModified?: number;
};

type FsConstants = {
  DocumentDirectoryPath: string;
  SUPPORTS_DIRECTORY_MOVE: boolean;
  SUPPORTS_ENCRYPTION: boolean;
};

export interface Spec extends TurboModule {
  readonly getConstants: () => FsConstants;
  save(blob: CodegenTypes.UnsafeObject, filePath: string): Promise<void>;
  read(filePath: string): Promise<BlobData>;
  move(filePath: string, newPath: string): Promise<void>;
  remove(filePath: string): Promise<void>;
  list(dirPath: string): Promise<string[]>;
  readAsDataURL(filePath: string): Promise<string>;
  readAsText(filePath: string): Promise<string>;
  fileExists(filePath: string): Promise<boolean>;
  writeJson(data: CodegenTypes.UnsafeObject, filepath: string): Promise<void>;
  readJson(filepath: string): Promise<CodegenTypes.UnsafeObject | null>;
  setEncryptionEnabled(enabled: boolean): void;
}

let cachedModule: Spec | undefined;
const getModule = (): Spec => {
  if (!cachedModule) {
    cachedModule = TurboModuleRegistry.getEnforcing<Spec>('MxFileSystem');
  }
  return cachedModule;
};

// Resolves the native module lazily (on first property access) instead of at import time,
// so requiring this file on web, where TurboModuleRegistry is stubbed out, never crashes.
const NativeMxFileSystem = new Proxy({} as Spec, {
  get(_target, prop) {
    return getModule()[prop as keyof Spec];
  },
});

export default NativeMxFileSystem;

export type { BlobData, FsConstants };
