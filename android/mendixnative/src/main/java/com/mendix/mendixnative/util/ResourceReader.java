package com.mendix.mendixnative.util;

import android.content.Context;

import java.io.IOException;
import java.io.InputStream;

public class ResourceReader {
    public static String readString(Context context, String name) {
        int resourceId = context.getResources().getIdentifier(name, "raw", context.getPackageName());

        if (resourceId == 0)
            return "";

        byte[] bytesIn = null;
        try {
            InputStream resIn = context.getResources().openRawResource(resourceId);
            bytesIn = new byte[resIn.available()];
            resIn.read(bytesIn);
            resIn.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return new String(bytesIn).trim();
    }

    public static Boolean readBoolean(Context context, String name) {
        return Boolean.parseBoolean(ResourceReader.readString(context, name));
    }
}
