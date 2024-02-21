package com.mendix.mendixnative.util;

import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

public class ReflectionUtils {
    public static ConstructorWrapper findConstructor(String className, Class<?>... parameterTypes) {
        try {
            Constructor constructor = Class.forName(className).getDeclaredConstructor(parameterTypes);
            constructor.setAccessible(true);
            return new ConstructorWrapper(constructor);
        } catch (ClassNotFoundException | NoSuchMethodException e) {
            throw new RuntimeException(e);
        }
    }

    // TODO: replace this with a lambda after upgrading to Java 8
    public static class ConstructorWrapper {
        private final Constructor constructor;

        ConstructorWrapper(Constructor constructor) {
            this.constructor = constructor;
        }

        public <T> T newInstance(Object... args) {
            try {
                return (T) constructor.newInstance(args);
            } catch (InstantiationException | IllegalAccessException | InvocationTargetException e) {
                throw new RuntimeException(e);
            }
        }
    }

    public static MethodWrapper findMethod(Object object, String methodName, Class<?>... parameterTypes) {
        try {
            Method method = object.getClass().getDeclaredMethod(methodName, parameterTypes);
            method.setAccessible(true);
            return new MethodWrapper(method, object);
        } catch (NoSuchMethodException e) {
            throw new RuntimeException(e);
        }
    }

    // TODO: replace this with a lambda after upgrading to Java 8
    public static class MethodWrapper {
        private final Method method;
        private final Object object;

        MethodWrapper(Method method, Object object) {
            this.method = method;
            this.object = object;
        }

        public void invoke(Object... args) {
            try {
                method.invoke(object, args);
            } catch (IllegalAccessException | InvocationTargetException e) {
                throw new RuntimeException(e);
            }
        }
    }

    public static void setFieldOfSuperclass(Object object, String fieldName, Object value) {
        try {
            Field field = object.getClass().getSuperclass().getDeclaredField(fieldName);
            setField(object, field, value);
        } catch (NoSuchFieldException e) {
            throw new RuntimeException(e);
        }
    }

    public static void setField(Object object, String fieldName, Object value) {
        try {
            Field field = object.getClass().getDeclaredField(fieldName);
            setField(object, field, value);
        } catch (NoSuchFieldException e) {
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

    public static <T> T getFieldOfSuperclass(Object object, String fieldName) {
        try {
            Field field = object.getClass().getSuperclass().getDeclaredField(fieldName);
            field.setAccessible(true);
            return (T) field.get(object);
        } catch (NoSuchFieldException | IllegalAccessException | ClassCastException e) {
            throw new RuntimeException(e);
        }
    }

    public static <T> T getField(Object object, String fieldName) {
        try {
            Field field = object.getClass().getDeclaredField(fieldName);
            field.setAccessible(true);
            return (T) field.get(object);
        } catch (NoSuchFieldException | IllegalAccessException | ClassCastException e) {
            throw new RuntimeException(e);
        }
    }

}
