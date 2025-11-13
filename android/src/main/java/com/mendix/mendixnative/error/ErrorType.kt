package com.mendix.mendixnative.error

import com.facebook.react.devsupport.interfaces.ErrorType

enum class ErrorType {
  JS,
  NATIVE,
  UNDEFINED;

  companion object {
    fun fromReactErrorType(errorType: ErrorType?) = when (errorType) {
      ErrorType.JS -> JS
      ErrorType.NATIVE -> NATIVE
      else -> UNDEFINED
    }
  }
}
