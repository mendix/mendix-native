import { TurboModuleRegistry, type TurboModule } from 'react-native';
import type { StackFrame } from 'stacktrace-parser';
import type { CodegenTypes } from 'react-native';

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
    config: DownloadConfig
  ): Promise<void>;

  mxConfigurationGetConfig(): Configuration;

  otaDownload(config: OtaDownloadConfig): Promise<OtaDownloadResponse>;
  otaDeploy(config: OtaDeployConfig): Promise<void>;

  fsConstants(): FsConstants;
  fsSave(blob: BlobData, filePath: string): Promise<void>;
  fsRead(filePath: string): Promise<BlobData>;
  fsMove(filePath: string, newPath: string): Promise<void>;
  fsRemove(filePath: string): Promise<void>;
  fsList(dirPath: string): Promise<string[]>;
  fsReadAsDataURL(filePath: string): Promise<string>;
  fsReadAsText(filePath: string): Promise<string>; //Android only
  fsFileExists(filePath: string): Promise<boolean>;
  fsWriteJson(data: CodegenTypes.UnsafeObject, filepath: string): Promise<void>;
  fsReadJson(filepath: string): Promise<CodegenTypes.UnsafeObject | null>;
  fsSetEncryptionEnabled(enabled: boolean): void;

  errorHandlerHandle(message: string, stackTrace: StackFrame[]): void;

  navigationModeIsNavigationBarActive(): boolean;
  navigationModeGetNavigationBarHeight(): CodegenTypes.Double;

  readonly onReloadWithState: CodegenTypes.EventEmitter<void>;
  readonly onDownloadProgress: CodegenTypes.EventEmitter<DownloadProgress>;
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
  NATIVE_BINARY_VERSION?: CodegenTypes.Int32;
  APP_SESSION_ID?: string;
};

type FsConstants = {
  DocumentDirectoryPath: string;
  SUPPORTS_DIRECTORY_MOVE: boolean;
  SUPPORTS_ENCRYPTION: boolean;
};

type DownloadConfig = {
  connectionTimeout?: CodegenTypes.Int32;
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
  receivedBytes: CodegenTypes.Double;
  totalBytes: CodegenTypes.Double;
};

export type {
  BlobData,
  Configuration,
  FsConstants,
  DownloadConfig,
  OtaDownloadConfig,
  OtaDeployConfig,
  OtaDownloadResponse,
  DownloadProgress,
};
