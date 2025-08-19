package com.captureprotection

import android.view.View
import com.facebook.react.TurboReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ReactShadowNode
import com.facebook.react.uimanager.ViewManager
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider

class CaptureProtectionPackage : TurboReactPackage() {
  override fun getModule(name: String, context: ReactApplicationContext): NativeModule? {
    return if (name == CaptureProtectionModule.NAME) {
      CaptureProtectionModule(context)
    } else null
  }

  override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
    val map = HashMap<String, ReactModuleInfo>()
    map[CaptureProtectionModule.NAME] = ReactModuleInfo(
      /* name */ CaptureProtectionModule.NAME,
      /* className */ CaptureProtectionModule::class.java.name,
      /* canOverrideExistingModule */ false,
      /* needsEagerInit */ false,
      /* hasConstants */ true,
      /* isCxxModule */ false,
      /* isTurboModule */ true
    )
    return ReactModuleInfoProvider { map }
  }

  override fun createViewManagers(
    reactContext: ReactApplicationContext
  ): MutableList<ViewManager<View, ReactShadowNode<*>>> = mutableListOf()
}
