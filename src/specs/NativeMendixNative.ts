import { TurboModuleRegistry, type TurboModule } from 'react-native';
import type { StackFrame } from 'stacktrace-parser';

import {
  type EventEmitter,
  type Int32,
  type Double,
} from 'react-native/Libraries/Types/CodegenTypes';

export interface Spec extends TurboModule {
  encryptedStorageSetItem(key: string, value: string): Promise<void>;
  encryptedStorageGetItem(key: string): Promise<string | null>;
  encryptedStorageRemoveItem(key: string): Promise<void>;
  encryptedStorageClear(): Promise<void>;
  encryptedStorageIsEncrypted(): boolean;

  splashScreenShow(): void;
  splashScreenHide(): void;

  cookieClearAll(): Promise<void>;

  reloadHandlerReload(): Promise<void>;
  reloadHandlerExitApp(): Promise<void>;

  downloadHandlerDownload(
    url: string,
    downloadPath: string,
    config: GenericMap
  ): Promise<void>;

  mxConfigurationGetConfig(): Configuration;

  otaDownload(config: GenericMap): Promise<OtaDownloadResponse>;
  otaDeploy(config: GenericMap): Promise<void>;

  fsConstants(): GenericMap;
  fsSave(blob: GenericMap, filePath: string): Promise<void>;
  fsRead(filePath: string): Promise<BlobData>;
  fsMove(filePath: string, newPath: string): Promise<void>;
  fsRemove(filePath: string): Promise<void>;
  fsList(dirPath: string): Promise<string[]>;
  fsReadAsDataURL(filePath: string): Promise<string>;
  fsReadAsText(filePath: string): Promise<string>; //Android only
  fsFileExists(filePath: string): Promise<boolean>;
  fsWriteJson(data: GenericMap, filepath: string): Promise<void>;
  fsReadJson(filepath: string): Promise<GenericMap | GenericArray>;
  fsSetEncryptionEnabled(enabled: boolean): void;

  errorHandlerHandle(message: string, stackTrace: StackFrame[]): void;

  navigationModeIsNavigationBarActive(): boolean;
  navigationModeGetNavigationBarHeight(): Double;

  readonly onReloadWithState: EventEmitter<void>;
  readonly onDownloadProgress: EventEmitter<DownloadProgress>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MendixNative');

// Codegen could not recognize types placed in other files hence placed here

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

type Configuration = {
  RUNTIME_URL: string;
  APP_NAME: string | null;
  /**
   * Do not use directly
   * @deprecated
   */
  FILES_DIRECTORY_NAME: string;
  DATABASE_NAME: string;
  WARNINGS_FILTER_LEVEL: string;
  OTA_MANIFEST_PATH: string;
  NATIVE_DEPENDENCIES?: { [key: string]: string };
  IS_DEVELOPER_APP?: boolean;
  /**
   * @deprecated
   */
  CODE_PUSH_KEY?: string;
  NATIVE_BINARY_VERSION?: Int32;
  APP_SESSION_ID?: string;
};

type DownloadConfig = {
  connectionTimeout?: Int32;
  mimeType?: string;
};

type OtaDownloadConfig = {
  url: string;
};

type OtaDeployConfig = {
  otaDeploymentID: string;
  otaPackage: string;
  extractionDir: string;
};

type OtaDownloadResponse = {
  otaPackage: string;
};

type DownloadProgress = {
  receivedBytes: Double;
  totalBytes: Double;
};

export type {
  BlobData,
  GenericMap,
  GenericArray,
  Configuration,
  DownloadConfig,
  OtaDownloadConfig,
  OtaDeployConfig,
  OtaDownloadResponse,
  DownloadProgress,
};
