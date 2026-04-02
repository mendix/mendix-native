package com.mendix.mendixnative.util;

import java.lang.reflect.Field;

/**
 * Minimal reflection utilities for accessing React Native private fields.
 *
 * **Usage:** Only used by MendixShakeDetector to swap React Native's shake detector.
 * There is no public React Native API for this functionality.
 *
 * **Note:** Reflection should be avoided where possible. This class is kept minimal
 * and only exposes methods that are actively used.
 */
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

    /**
     * Sets a field on the superclass of the given object.
     * Tries multiple field names to handle React Native version differences.
     *
     * @param object The object whose superclass field should be set
     * @param value The value to set
     * @param fieldNames Field names to try (in order of preference)
     */
    public static void setFieldOfSuperclass(Object object, Object value, String... fieldNames) {
        Field field = findDeclaredField(object.getClass().getSuperclass(), fieldNames);
        setField(object, field, value);
    }

    /**
     * Gets a field from the superclass of the given object.
     * Tries multiple field names to handle React Native version differences.
     *
     * @param object The object whose superclass field should be retrieved
     * @param fieldNames Field names to try (in order of preference)
     * @return The field value
     */
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
