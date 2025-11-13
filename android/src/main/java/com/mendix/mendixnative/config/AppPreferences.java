package com.mendix.mendixnative.config;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import com.facebook.react.modules.debug.interfaces.DeveloperSettings;
import com.facebook.react.packagerconnection.PackagerConnectionSettings;
import com.mendix.mendixnative.react.CopiedFrom;

import java.net.URI;

import static com.mendix.mendixnative.config.AppUrl.ensureProtocol;

final public class AppPreferences {
    private static final String LAUNCH_URL_KEY = "MX_APP_URL";
    private static final String DEV_MODE_KEY = "MX_DEV_MODE";
    private static final String REMOTE_DEBUGGING_PACKAGER_PORT = "REMOTE_DEBUGGING_PACKAGER_PORT";

    @CopiedFrom(PackagerConnectionSettings.class)
    private static final String REACT_NATIVE_SERVER_HOST_KEY = "debug_http_host";

    @CopiedFrom(DeveloperSettings.class)
    private static final String REACT_NATIVE_REMOTE_JS_DEBUG_KEY = "remote_js_debug";

    @CopiedFrom(DeveloperSettings.class)
    private static final String PREFS_JS_MINIFY_DEBUG_KEY = "js_minify_debug";

    @CopiedFrom(DeveloperSettings.class)
    private static final String PREFS_JS_DEV_MODE_DEBUG_KEY = "js_dev_mode_debug";

    @CopiedFrom(DeveloperSettings.class)
    private static final String PREFS_JS_BUNDLE_DELTAS_KEY = "js_bundle_deltas";

    @CopiedFrom(DeveloperSettings.class)
    private static final String PREFS_INSPECTOR_DEBUG_KEY = "inspector_debug";

    private final SharedPreferences preferences;

    public AppPreferences(Context applicationContext) {
        preferences = PreferenceManager.getDefaultSharedPreferences(applicationContext);
    }

    public String getAppUrl() {
        return preferences.getString(LAUNCH_URL_KEY, "");
    }

    public void setAppUrl(String appUrl) {
        putString(LAUNCH_URL_KEY, AppUrl.ensureProtocol(appUrl.trim()));
    }

    public void setRemoteDebugging(boolean enabled) {
        putBoolean(REACT_NATIVE_REMOTE_JS_DEBUG_KEY, enabled);
    }

    public void setDevMode(boolean devMode) {
        putBoolean(DEV_MODE_KEY, devMode);

        setDevModeBundle(devMode);
        setJSMinifyBundle(!devMode);
    }

    public void setDeltas(boolean enabled) {
        putBoolean(PREFS_JS_BUNDLE_DELTAS_KEY, enabled);
    }

    public boolean isDevModeEnabled() {
        return preferences.getBoolean(DEV_MODE_KEY, false);
    }

    public void setRemoteDebuggingPackagerPort(int port) {
        putInt(REMOTE_DEBUGGING_PACKAGER_PORT, port);
    }

    public Integer getPackagerPort() {
        return preferences.getInt(REMOTE_DEBUGGING_PACKAGER_PORT, 8083);
    }

    public String getMetroBundlerHost() {
        return preferences.getString(REACT_NATIVE_SERVER_HOST_KEY, getAppUrl());
    }

    public void setElementInspector(boolean enabled) {
        putBoolean(PREFS_INSPECTOR_DEBUG_KEY, enabled);
    }

    public boolean isElementInspectorEnabled() {
        return preferences.getBoolean(PREFS_INSPECTOR_DEBUG_KEY, false);
    }

    public boolean isRemoteJSDebugEnabled() {
        return preferences.getBoolean(REACT_NATIVE_REMOTE_JS_DEBUG_KEY, false);
    }

    public void setDevModeBundle(boolean enabled) {
        putBoolean(PREFS_JS_DEV_MODE_DEBUG_KEY, enabled);
    }

    public void setJSMinifyBundle(boolean enabled) {
        putBoolean(PREFS_JS_MINIFY_DEBUG_KEY, enabled);
    }

    public boolean updatePackagerHost(String appUrl) {
        try {
            URI uri = URI.create(ensureProtocol(appUrl));
            putString(REACT_NATIVE_SERVER_HOST_KEY, AppUrl.forBundle(uri.getHost(), getPackagerPort()));
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private void putInt(String key, int value) {
        preferences.edit().putInt(key, value).commit();
    }

    private void putString(String key, String value) {
        preferences.edit().putString(key, value).commit();
    }

    private void putBoolean(String key, boolean value) {
        preferences.edit().putBoolean(key, value).commit();
    }
}
