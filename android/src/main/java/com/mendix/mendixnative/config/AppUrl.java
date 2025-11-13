package com.mendix.mendixnative.config;

import android.annotation.SuppressLint;
import android.content.Context;

import com.mendix.mendixnative.util.ResourceReader;

public class AppUrl {
    private static final String RUNTIME_URL = "%s/";

    @SuppressLint("DefaultLocale")
    protected static String forBundle(String host, int port) {
        return String.format("%s:%d", host, port);
    }

    public static String forRuntime(String url) {
        return String.format(RUNTIME_URL, ensureProtocol(removeTrailingSlash(url)));
    }

    public static String removeTrailingSlash(String url) {
        if (url.endsWith("/")) {
            url = url.substring(0, url.length() - 1);
        }
        return url;
    }

    public static String ensureProtocol(String url) {
        if (!url.matches("https?://.*")) {
            url = "http://" + url;
        }
        return url;
    }

    public static String getUrlFromResource(Context context) {
        return ResourceReader.readString(context, "runtime_url");
    }
}
