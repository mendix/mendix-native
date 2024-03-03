#import "OtaConstants.h"

#pragma mark - Constants

NSString *const MANIFEST_FILE_NAME = @"manifest.json";
NSString *const OTA_DIR_NAME = @"Ota";

#pragma mark - ErrorCodes

NSString *const INVALID_RUNTIME_URL = @"INVALID_RUNTIME_URL";
NSString *const INVALID_DEPLOY_CONFIG = @"INVALID_DEPLOY_CONFIG";
NSString *const OTA_ZIP_FILE_MISSING = @"OTA_ZIP_FILE_MISSING";
NSString *const OTA_UNZIP_DIR_EXISTS = @"OTA_UNZIP_DIR_EXISTS";
NSString *const OTA_DEPLOYMENT_FAILED = @"OTA_DEPLOYMENT_FAILED";
NSString *const INVALID_DOWNLOAD_CONFIG = @"INVALID_DOWNLOAD_CONFIG";
NSString *const OTA_DOWNLOAD_FAILED = @"OTA_DOWNLOAD_FAILED";

#pragma mark - Download Config Keys

NSString *const DOWNLOAD_CONFIG_URL_KEY = @"url";

#pragma mark - Deploy Config Keys

NSString *const DEPLOY_CONFIG_OTA_DEPLOYMENT_ID_KEY = @"otaDeploymentID";
NSString *const DEPLOY_CONFIG_OTA_PACKAGE_KEY = @"otaPackage";
NSString *const DEPLOY_CONFIG_EXTRACTION_DIR = @"extractionDir";

#pragma mark - Manifest Keys

NSString *const MANIFEST_OTA_DEPLOYMENT_ID_KEY = @"otaDeploymentID";
NSString *const MANIFEST_RELATIVE_BUNDLE_PATH_KEY = @"relativeBundlePath";
NSString *const MANIFEST_APP_VERSION_KEY = @"appVersion";
