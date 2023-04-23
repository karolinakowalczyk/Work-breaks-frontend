package com.example.ppiwd_work_breaks_frontend.routebuilder

import android.os.Handler
import android.os.Looper
import com.mbientlab.metawear.builder.RouteBuilder
import com.mbientlab.metawear.builder.RouteComponent
import io.flutter.plugin.common.MethodChannel

abstract class MetaWearRouteBuilder<T>(
        private var channel: MethodChannel,
        private var callbackName: String) : RouteBuilder {

    abstract val aClass: Class<T>

    override fun configure(source: RouteComponent) {
        source.stream { data, _ ->
            try {
                val result = data.value(aClass)
                Handler(Looper.getMainLooper()).post {
                    channel.invokeMethod(callbackName, mapOf(
                            "data" to getData(result),
                            "timestamp" to System.currentTimeMillis()))
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    abstract fun getData(result: T): FloatArray
}