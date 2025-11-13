package com.mendix.mendixnative.error

import android.content.Context
import com.facebook.react.devsupport.interfaces.StackFrame
import com.facebook.react.devsupport.interfaces.ErrorType
import com.facebook.react.devsupport.interfaces.RedBoxHandler
import com.mendix.mendixnative.error.ErrorType.Companion.fromReactErrorType


fun mapErrorHandlerToRedBox(errorHandler: ErrorHandler) = object : RedBoxHandler {
  override fun handleRedbox(title: String?, stack: Array<StackFrame>, errorType: ErrorType) =
    errorHandler.handleError(title, stack, fromReactErrorType(errorType))

  override fun isReportEnabled(): Boolean = false
  override fun reportRedbox(
    context: Context,
    title: String,
    stack: Array<StackFrame>,
    sourceUrl: String,
    reportCompletedListener: RedBoxHandler.ReportCompletedListener
  ) {
    // Not supported
  }
}
