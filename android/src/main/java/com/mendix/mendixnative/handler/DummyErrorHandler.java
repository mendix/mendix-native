package com.mendix.mendixnative.handler;

import com.facebook.react.devsupport.interfaces.StackFrame;
import com.mendix.mendixnative.error.ErrorHandler;
import com.mendix.mendixnative.error.ErrorType;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

public class DummyErrorHandler implements ErrorHandler {
  @Override
  public void handleError(@Nullable String title, @Nullable StackFrame[] stack, @NotNull ErrorType type) {
    // Do nothing
  }
}
