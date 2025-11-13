package com.mendix.mendixnative.react

import kotlin.reflect.KClass

@Target(
    AnnotationTarget.FUNCTION,
    AnnotationTarget.PROPERTY_GETTER,
    AnnotationTarget.PROPERTY_SETTER,
    AnnotationTarget.FIELD,
    AnnotationTarget.CLASS
)
@Retention(AnnotationRetention.SOURCE)
annotation class CopiedFrom(val value: KClass<*>, val method: String = "")
