package com.mendix.mendixnative.error

interface ErrorHandlerFactory {
  fun createErrorHandler(): ErrorHandler
}
