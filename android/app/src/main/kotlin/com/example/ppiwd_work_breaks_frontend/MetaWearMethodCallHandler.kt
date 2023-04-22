package com.example.ppiwd_work_breaks_frontend

import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import bolts.Task
import com.mbientlab.metawear.MetaWearBoard
import com.mbientlab.metawear.Route
import com.mbientlab.metawear.android.BtleService.LocalBinder
import com.mbientlab.metawear.data.Acceleration
import com.mbientlab.metawear.data.AngularVelocity
import com.mbientlab.metawear.module.Accelerometer
import com.mbientlab.metawear.module.Gyro
import com.mbientlab.metawear.module.GyroBmi160
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler


class MetaWearMethodCallHandler : MethodCallHandler {
    private lateinit var service: LocalBinder
    private lateinit var btManager: BluetoothManager
    private lateinit var board: MetaWearBoard
    private lateinit var accelerometer: Accelerometer
    private lateinit var gyroBmi160: GyroBmi160
    private lateinit var channel: MethodChannel

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "connect" -> connect(call.argument<String>("mac") ?: return)
            "disconnect" -> disconnect()
        }
    }

    fun setService(service: LocalBinder, btManager: BluetoothManager) {
        this.service = service
        this.btManager = btManager
    }

    fun setChannel(channel: MethodChannel) {
        this.channel = channel
    }

    private fun connect(mac: String) {
        if (!::service.isInitialized || !::btManager.isInitialized) {
            Log.i("ppiwd", "bt service is not initialized")
            return
        }
        if (!::channel.isInitialized) {
            Log.i("ppiwd", "channel is not initialized")
            return
        }
        if (::board.isInitialized && board.isConnected) {
            Log.i("ppiwd", "board already connected")
            return
        }
        val remoteDevice: BluetoothDevice = btManager.adapter.getRemoteDevice(mac)
        board = service.getMetaWearBoard(remoteDevice)
        board.connectAsync().onSuccessTask(this::configureAccel)
                .onSuccessTask(this::configureGyro)
                .continueWith<Void> { task ->
                    if (task.isFaulted) {
                        Log.w("ppiwd", "Failed to configure app", task.error)
                    }
                    null
                }
    }

    private fun configureAccel(task: Task<Void>): Task<Route>? {
        if (task.isFaulted) {
            return null
        }
        accelerometer = board.getModule(Accelerometer::class.java)
        accelerometer.configure()
                .odr(50f)
                .commit()
        return accelerometer.acceleration().addRouteAsync(MetaWearRouteBuilder(channel, Acceleration::class.java, "putAccel"))
    }

    private fun configureGyro(task: Task<Route>): Task<Route>? {
        if (task.isFaulted) {
            return null
        }
        gyroBmi160 = board.getModule(GyroBmi160::class.java)
        gyroBmi160.configure()
                .odr(Gyro.OutputDataRate.ODR_50_HZ)
                .commit()
        return gyroBmi160.angularVelocity().addRouteAsync(MetaWearRouteBuilder(channel, AngularVelocity::class.java, "putGyro"))
    }

    private fun disconnect() {
        if (!::board.isInitialized || !board.isConnected) {
            Log.w("ppiwd", "Board already disconnected")
            return
        }
        board.disconnectAsync().continueWith<Any> {
            this.board.disconnectAsync()
        }
    }
}