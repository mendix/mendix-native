package com.mendix.mendixnative.react

import java.io.Serializable

data class MendixApp(
  val runtimeUrl: String,
  val warningsFilter: MxConfiguration.WarningsFilter,
  val showExtendedDevMenu: Boolean = false,
  val attachCustomDeveloperMenu: Boolean = false
) : Serializable
