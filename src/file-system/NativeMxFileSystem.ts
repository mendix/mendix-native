import { TurboModuleRegistry, type TurboModule } from 'react-native';

type BlobData = {
  blobId: string;
  offset: number;
  size: number;
  name?: string;
  type?: string;
  lastModified?: number;
};

type GenericType =
  | string
  | number
  | boolean
  | null
  | undefined
  | { [key: string]: GenericType }
  | GenericType[];

type GenericMap = { [key: string]: GenericType };
type GenericArray = GenericType[];

export interface Spec extends TurboModule {
  constants(): GenericMap;
  save(blob: GenericMap, filePath: string): Promise<void>;
  read(filePath: string): Promise<BlobData>;
  move(filePath: string, newPath: string): Promise<void>;
  remove(filePath: string): Promise<void>;
  list(dirPath: string): Promise<string[]>;
  readAsDataURL(filePath: string): Promise<string>;
  readAsText(filePath: string): Promise<string>;
  fileExists(filePath: string): Promise<boolean>;
  writeJson(data: GenericMap, filepath: string): Promise<void>;
  readJson(filepath: string): Promise<GenericMap | GenericArray>;
  setEncryptionEnabled(enabled: boolean): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MxFileSystem');

export type { BlobData, GenericMap, GenericArray };
