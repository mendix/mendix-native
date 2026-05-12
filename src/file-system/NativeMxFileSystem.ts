import {
  TurboModuleRegistry,
  type TurboModule,
  type CodegenTypes,
} from 'react-native';

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
  constants(): FsConstants;
  save(blob: BlobData, filePath: string): Promise<void>;
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

export default TurboModuleRegistry.getEnforcing<Spec>('MxFileSystem');

export type { BlobData, FsConstants };
