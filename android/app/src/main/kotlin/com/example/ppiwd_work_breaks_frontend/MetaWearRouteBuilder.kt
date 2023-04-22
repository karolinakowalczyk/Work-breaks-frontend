package com.example.ppiwd_work_breaks_frontend

import android.os.Handler
import android.os.Looper
import com.mbientlab.metawear.builder.RouteBuilder
import com.mbientlab.metawear.builder.RouteComponent
import io.flutter.plugin.common.MethodChannel

class MetaWearRouteBuilder(private var channel: MethodChannel,
                           private var aClass: Class<*>,
                           private var callbackName: String) : RouteBuilder {

    override fun configure(source: RouteComponent) {
        source.stream { data, _ ->
            try {
                val result = data.value(aClass)
                Handler(Looper.getMainLooper()).post {
                    channel.invokeMethod(callbackName, mapOf("data" to result.toString()))
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}