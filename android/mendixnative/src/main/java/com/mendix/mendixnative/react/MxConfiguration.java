package com.mendix.mendixnative.react;

import static com.mendix.mendixnative.react.ota.OtaHelpersKt.getNativeDependencies;
import static com.mendix.mendixnative.react.ota.OtaHelpersKt.getOtaManifestFilepath;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.mendix.mendixnative.MendixApplication;
import com.mendix.mendixnative.config.AppUrl;

import org.jetbrains.annotations.NotNull;

import java.util.HashMap;
import java.util.Map;

public class MxConfiguration extends ReactContextBaseJavaModule {
    MxConfiguration(ReactApplicationContext reactContext) {
        super(reactContext);
    }
    /**
     *  Increment NATIVE_BINARY_VERSION to 4 for React native upgrade to version 0.72.7
     */
    public static final int NATIVE_BINARY_VERSION = 4;
    static final String NAME = "MxConfiguration";
    static String defaultDatabaseName = "default";
    @Deprecated
    static String defaultFilesDirectoryName = "files/default";

    public static String defaultAppName = null;
    public static String runtimeUrl;
    public static MxConfiguration.WarningsFilter warningsFilter;

    /**
     * Setter for the application name constant
     *
     * @param name the unique name or identifier that represents the application. This value should always be set to null for non-sample apps
     */
    public static void setDefaultAppNameOrDefault(String name) {
        defaultAppName = name;
    }

    public static void setDefaultDatabaseNameOrDefault(String name) {
        defaultDatabaseName = name != null ? name : "default";
    }

    public static void setDefaultFilesDirectoryOrDefault(String path) {
        defaultFilesDirectoryName = path != null ? path : "files/default";
    }

    @Override
    public Map<String, Object> getConstants() {
        final MendixApplication application = ((MendixApplication) this.getReactApplicationContext().getApplicationContext());

        if (runtimeUrl == null) {
            if (warningsFilter != WarningsFilter.none) {
                application.getReactNativeHost()
                        .getReactInstanceManager()
                        .getDevSupportManager()
                        .showNewJavaError("Runtime URL not specified.", new Throwable("Without the runtime URL, the app cannot retrieve any data.\n\nPlease redeploy the app."));

                return new HashMap<>();
            }

            throw new IllegalStateException("Runtime URL not set in the MxConfiguration");
        }

        final Map<String, Object> constants = new HashMap<>();
        constants.put("RUNTIME_URL", AppUrl.forRuntime(runtimeUrl));
        constants.put("APP_NAME", defaultAppName);
        constants.put("DATABASE_NAME", defaultDatabaseName);
        constants.put("FILES_DIRECTORY_NAME", defaultFilesDirectoryName); // Not to be removed as it is required for backwards compatibility.
        constants.put("WARNINGS_FILTER_LEVEL", warningsFilter.toString());
        constants.put("CODE_PUSH_KEY", application.getCodePushKey());
        constants.put("OTA_MANIFEST_PATH", getOtaManifestFilepath(getReactApplicationContext()));
        constants.put("NATIVE_DEPENDENCIES", getNativeDependencies(getReactApplicationContext()));
        constants.put("IS_DEVELOPER_APP", application.getUseDeveloperSupport());
        constants.put("NATIVE_BINARY_VERSION", NATIVE_BINARY_VERSION);
        constants.put("APP_SESSION_ID", application.getAppSessionId());
        return constants;
    }

    @NotNull
    @Override
    public String getName() {
        return NAME;
    }

    public enum WarningsFilter {
        all, partial, none
    }
}
