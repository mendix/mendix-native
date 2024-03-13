package com.mendix.mendixnative.react.fs;

import static java.util.Objects.requireNonNull;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.modules.blob.BlobModule;
import com.facebook.react.modules.blob.FileReaderModule;
import com.fasterxml.jackson.core.JsonParseException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.jetbrains.annotations.NotNull;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

@ReactModule(name = NativeFsModule.NAME)
public class NativeFsModule extends ReactContextBaseJavaModule {
    static final String NAME = "NativeFsModule";

    private static final String ERROR_INVALID_BLOB = "ERROR_INVALID_BLOB";
    private static final String ERROR_READ_FAILED = "ERROR_READ_FAILED";
    private static final String ERROR_CACHE_FAILED = "ERROR_CACHE_FAILED";
    private static final String ERROR_MOVE_FAILED = "ERROR_MOVE_FAILED";
    private static final String ERROR_SERIALIZATION_FAILED = "ERROR_SERIALIZATION_FAILED";
    private static final String INVALID_PATH = "INVALID_PATH";

    private final ReactApplicationContext reactContext;
    private final FileBackend fileBackend;
    private final String filesDir;
    private final String cacheDir;

    public NativeFsModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        filesDir = reactContext.getFilesDir().getAbsolutePath();
        cacheDir = reactContext.getCacheDir().getAbsolutePath();
        fileBackend = new FileBackend(reactContext);
    }

    @NotNull
    @Override
    public String getName() {
        return NAME;
    }

    @ReactMethod
    public void setEncryptionEnabled(Boolean encryptionEnabled) {
        this.fileBackend.setEncryptionEnabled(encryptionEnabled);
    }

    @ReactMethod
    public void save(ReadableMap blob, String filePath, Promise promise) {
        BlobModule blobModule = reactContext.getNativeModule(BlobModule.class);
        String blobId = blob.getString("blobId");

        byte[] bytes = blobModule.resolve(blobId, blob.getInt("offset"), blob.getInt("size"));
        if (bytes == null) {
            promise.reject(ERROR_INVALID_BLOB, "The specified blob is invalid");
            return;
        }

        try {
            fileBackend.save(bytes, ensureWhiteListedPath(filePath));
        } catch (IOException e) {
            e.printStackTrace();
            promise.reject(ERROR_CACHE_FAILED, "Failed writing file to disk");
            return;
        } catch (PathNotAccessibleException e) {
            e.printStackTrace();
            promise.reject(INVALID_PATH, e);
            return;
        }

        blobModule.release(blobId);
        promise.resolve(null);
    }

    @ReactMethod
    public void read(String filePath, Promise promise) {
        try {
            promise.resolve(read(ensureWhiteListedPath(filePath)));
        } catch (FileNotFoundException e) {
            promise.resolve(null);
        } catch (IOException e) {
            e.printStackTrace();
            promise.reject(ERROR_READ_FAILED, "Failed reading file from disk");
        } catch (PathNotAccessibleException e) {
            e.printStackTrace();
            promise.reject(INVALID_PATH, e);
        }
    }

    @ReactMethod
    public void move(String filePath, String newPath, Promise promise) {
        String fromPath;
        String toPath;

        try {
            fromPath = ensureWhiteListedPath(filePath);
            toPath = ensureWhiteListedPath(newPath);
        } catch (PathNotAccessibleException e) {
            e.printStackTrace();
            promise.reject(INVALID_PATH, e);
            return;
        }

        if (!fileBackend.exists(fromPath)) {
            promise.reject(ERROR_READ_FAILED, "File does not exist");
        }

        try {
            if (fileBackend.isDirectory(fromPath)) {
                fileBackend.moveDirectory(fromPath, toPath);
            } else {
                fileBackend.moveFile(fromPath, toPath);
            }
            promise.resolve(null);
        } catch (IOException e) {
            e.printStackTrace();
            promise.reject(ERROR_MOVE_FAILED, e);
        }
    }

    @ReactMethod
    public void remove(String filePath, Promise promise) {
        try {
            if (fileBackend.isDirectory(filePath)) {
                fileBackend.deleteDirectory(filePath);
            } else {
                fileBackend.deleteFile(ensureWhiteListedPath(filePath));
            }
            promise.resolve(null);
        } catch (PathNotAccessibleException e) {
            e.printStackTrace();
            promise.reject(INVALID_PATH, e);
        }
    }

    @ReactMethod
    public void list(String dirPath, Promise promise) {
        WritableNativeArray result = new WritableNativeArray();

        /*
         This is for backwards compatibility for a assumption/bug(?) in the client. The client assumes
         it can list any path without verifying its validity and expects to get an empty array back as it chains unconditionally.
        */
        File directory = new File(dirPath);
        if (!directory.exists() || !directory.isDirectory()) {
            promise.resolve(result);
            return;
        }

        try {
            for (String file : requireNonNull(fileBackend.list(ensureWhiteListedPath(dirPath)))) {
                result.pushString(file);
            }
            promise.resolve(result);
        } catch (PathNotAccessibleException e) {
            e.printStackTrace();
            promise.reject(INVALID_PATH, e);
        } catch (Exception e) {
            e.printStackTrace();
            promise.reject(e);
        }
    }

    @ReactMethod
    public void readAsDataURL(String filePath, Promise promise) {
        try {
            FileReaderModule fileReaderModule =
                    reactContext.getNativeModule(FileReaderModule.class);
            fileReaderModule.readAsDataURL(read(ensureWhiteListedPath(filePath)), promise);
        } catch (FileNotFoundException e) {
            promise.resolve(null);
        } catch (IOException e) {
            e.printStackTrace();
            promise.reject(ERROR_READ_FAILED, "Failed reading file from disk");
        } catch (PathNotAccessibleException e) {
            e.printStackTrace();
            promise.reject(INVALID_PATH, e);
        }
    }

    @ReactMethod
    public void readAsText(String filePath, Promise promise) {
        try {
            promise.resolve(new String(fileBackend.read(filePath), StandardCharsets.UTF_8));
        } catch (IOException e) {
            promise.reject("no text", e);
        }
    }

    @ReactMethod
    public void fileExists(String filePath, Promise promise) {
        try {
            promise.resolve(fileBackend.exists(ensureWhiteListedPath(filePath)));
        } catch (PathNotAccessibleException e) {
            e.printStackTrace();
            promise.reject(INVALID_PATH, e);
        }
    }

    @ReactMethod
    public void writeJson(ReadableMap data, String filepath, Promise promise) {
        try {
            fileBackend.writeJson(data.toHashMap(), ensureWhiteListedPath(filepath));
            promise.resolve(null);
        } catch (JsonMappingException e) {
            e.printStackTrace();
            promise.reject(ERROR_SERIALIZATION_FAILED, "Failed to serialize JSON", e);
        } catch (IOException e) {
            e.printStackTrace();
            promise.reject(ERROR_CACHE_FAILED, "Failed to write to disk", e);
        } catch (PathNotAccessibleException e) {
            e.printStackTrace();
            promise.reject(INVALID_PATH, e);
        }
    }

    @ReactMethod
    public void readJson(String filepath, Promise promise) {
        try {
            byte[] bytes =
                    fileBackend.read(ensureWhiteListedPath(filepath));
            TypeReference<Map<String, Object>> typeRef =
                    new TypeReference<Map<String, Object>>() {
                    };
            promise.resolve(Arguments.makeNativeMap(new ObjectMapper().readValue(bytes, typeRef)));
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            promise.resolve("null");
        } catch (JsonParseException | JsonMappingException e) {
            e.printStackTrace();
            promise.reject(ERROR_SERIALIZATION_FAILED, "Failed to deserialize JSON", e);
        } catch (IOException e) {
            e.printStackTrace();
            promise.reject(ERROR_READ_FAILED, "Failed reading file from disk");
        } catch (PathNotAccessibleException e) {
            e.printStackTrace();
            promise.reject(INVALID_PATH, e);
        }
    }

    @Override
    public Map<String, Object> getConstants() {
        HashMap<String, Object> constants = new HashMap<>();
        constants.put("DocumentDirectoryPath", filesDir);
        constants.put(
                "SUPPORTS_DIRECTORY_MOVE",
                true); // Client uses this const to identify if functionality is supported
        constants.put(
                "SUPPORTS_ENCRYPTION",
                true);
        return constants;
    }

    private ReadableMap read(String filePath) throws IOException {
        byte[] data;
        data = fileBackend.read(filePath);

        BlobModule blobModule = reactContext.getNativeModule(BlobModule.class);
        WritableMap blob = new WritableNativeMap();
        blob.putString("blobId", blobModule.store(data));
        blob.putInt("offset", 0);
        blob.putInt("size", data.length);
        return blob;
    }

    private String ensureWhiteListedPath(String path) throws PathNotAccessibleException {
        if (!(path.startsWith(filesDir) || path.startsWith(cacheDir))) {
            throw new PathNotAccessibleException(path);
        }
        return path;
    }
}

class PathNotAccessibleException extends Exception {
    PathNotAccessibleException(String path) {
        super(
                "Cannot write to "
                        + path
                        + ". Path needs to be an absolute path to the apps accessible space.");
    }
}
