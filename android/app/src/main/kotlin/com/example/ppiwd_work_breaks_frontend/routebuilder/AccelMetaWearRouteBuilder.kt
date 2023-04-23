package com.example.ppiwd_work_breaks_frontend.routebuilder

import com.mbientlab.metawear.data.Acceleration
import io.flutter.plugin.common.MethodChannel

class AccelMetaWearRouteBuilder(channel: MethodChannel, callbackName: String)
    : MetaWearRouteBuilder<Acceleration>(channel, callbackName) {
    override val aClass = Acceleration::class.java

    override fun getData(result: Acceleration): FloatArray {
        return floatArrayOf(result.x(), result.y(), result.z())
    }
}