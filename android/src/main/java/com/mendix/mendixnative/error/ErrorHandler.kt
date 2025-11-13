package com.mendix.mendixnative.error

import com.facebook.react.devsupport.interfaces.StackFrame

interface ErrorHandler {
  fun handleError(title: String?, stack: Array<out StackFrame>?, type: ErrorType)
}
