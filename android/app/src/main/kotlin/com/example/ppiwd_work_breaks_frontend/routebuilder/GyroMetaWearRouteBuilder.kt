package com.example.ppiwd_work_breaks_frontend.routebuilder

import com.mbientlab.metawear.data.AngularVelocity
import io.flutter.plugin.common.MethodChannel

class GyroMetaWearRouteBuilder(channel: MethodChannel, callbackName: String)
    : MetaWearRouteBuilder<AngularVelocity>(channel, callbackName) {
    override val aClass = AngularVelocity::class.java

    override fun getData(result: AngularVelocity): FloatArray {
        return floatArrayOf(result.x(), result.y(), result.z())
    }
}