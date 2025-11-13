package com.mendix.mendixnative;

import com.facebook.react.ReactApplication;
import com.facebook.react.ReactPackage;
import com.mendix.mendixnative.react.splash.MendixSplashScreenPresenter;

import java.util.List;
import java.util.Map;

public interface MendixApplication extends ReactApplication {
  boolean getUseDeveloperSupport();

  MendixSplashScreenPresenter createSplashScreenPresenter();

  List<ReactPackage> getPackages();

  String getJSBundleFile();

  String getAppSessionId();
}
