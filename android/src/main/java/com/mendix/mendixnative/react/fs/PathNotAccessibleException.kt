package com.mendix.mendixnative.react.fs

internal class PathNotAccessibleException(path: String?) : Exception(
  ("Cannot write to "
    + path
    + ". Path needs to be an absolute path to the apps accessible space.")
)
