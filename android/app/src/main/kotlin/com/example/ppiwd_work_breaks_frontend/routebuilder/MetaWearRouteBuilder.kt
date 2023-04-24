package com.example.ppiwd_work_breaks_frontend.routebuilder

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.mbientlab.metawear.builder.RouteBuilder
import com.mbientlab.metawear.builder.RouteComponent
import io.flutter.plugin.common.MethodChannel

abstract class MetaWearRouteBuilder<T>(
        protected var channel: MethodChannel,
        protected var callbackName: String) : RouteBuilder {

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