package com.mendix.mendixnative.util;

import java.lang.reflect.Field;

public class ReflectionUtils {
    private static Field findDeclaredField(Class<?> objectClass, String... fieldNames) {
        NoSuchFieldException lastException = null;

        for (String fieldName : fieldNames) {
            try {
                return objectClass.getDeclaredField(fieldName);
            } catch (NoSuchFieldException e) {
                lastException = e;
            }
        }

        throw new RuntimeException(lastException);
    }

    public static void setFieldOfSuperclass(Object object, Object value, String... fieldNames) {
        Field field = findDeclaredField(object.getClass().getSuperclass(), fieldNames);
        setField(object, field, value);
    }

    public static <T> T getFieldOfSuperclass(Object object, String... fieldNames) {
        try {
            Field field = findDeclaredField(object.getClass().getSuperclass(), fieldNames);
            field.setAccessible(true);
            return (T) field.get(object);
        } catch (IllegalAccessException | ClassCastException e) {
            throw new RuntimeException(e);
        }
    }

    private static void setField(Object object, Field field, Object value) {
        try {
            field.setAccessible(true);
            field.set(object, value);
        } catch (IllegalAccessException e) {
            throw new RuntimeException(e);
        } finally {
            field.setAccessible(false);
        }
    }
}
