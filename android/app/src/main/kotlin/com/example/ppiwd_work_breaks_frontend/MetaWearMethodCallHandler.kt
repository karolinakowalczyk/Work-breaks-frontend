package com.example.ppiwd_work_breaks_frontend

import android.Manifest
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import bolts.Task
import com.example.ppiwd_work_breaks_frontend.routebuilder.AccelMetaWearRouteBuilder
import com.example.ppiwd_work_breaks_frontend.routebuilder.GyroMetaWearRouteBuilder
import com.mbientlab.metawear.MetaWearBoard
import com.mbientlab.metawear.Route
import com.mbientlab.metawear.android.BtleService.LocalBinder
import com.mbientlab.metawear.module.Accelerometer
import com.mbientlab.metawear.module.Gyro
import com.mbientlab.metawear.module.GyroBmi160
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler


class MetaWearMethodCallHandler(private val context: Context) : MethodCallHandler {
    private val TAG = "ppiwd/MetaWearMethodCallHandler"
    private lateinit var service: LocalBinder
    private lateinit var btManager: BluetoothManager
    private lateinit var board: MetaWearBoard
    private lateinit var accelerometer: Accelerometer
    private lateinit var gyroBmi160: GyroBmi160
    private lateinit var channel: MethodChannel
    private val BLE_SCAN_PERIOD: Long = 10000
    private var bleScanActive = false

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "connect" -> connect(call.argument<String>("mac") ?: return)
            "disconnect" -> disconnect()
            "scan" -> scan()
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
            Log.i(TAG, "bt service is not initialized")
            return
        }
        if (!::channel.isInitialized) {
            Log.i(TAG, "channel is not initialized")
            return
        }
        if (::board.isInitialized && board.isConnected) {
            Log.i(TAG, "board already connected")
            return
        }
        val remoteDevice: BluetoothDevice = btManager.adapter.getRemoteDevice(mac)
        board = service.getMetaWearBoard(remoteDevice)
        board.connectAsync().onSuccessTask(this::configureAccel)
                .onSuccessTask(this::configureGyro)
                .continueWith<Void> { task ->
                    if (task.isFaulted) {
                        Log.w(TAG, "Failed to configure app", task.error)
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
        return accelerometer.acceleration().addRouteAsync(AccelMetaWearRouteBuilder(channel, "putAccel"))
    }

    private fun configureGyro(task: Task<Route>): Task<Route>? {
        if (task.isFaulted) {
            return null
        }
        gyroBmi160 = board.getModule(GyroBmi160::class.java)
        gyroBmi160.configure()
                .odr(Gyro.OutputDataRate.ODR_50_HZ)
                .commit()
        return gyroBmi160.angularVelocity().addRouteAsync(GyroMetaWearRouteBuilder(channel, "putGyro"))
    }

    private fun disconnect() {
        if (!::board.isInitialized || !board.isConnected) {
            Log.w(TAG, "Board already disconnected")
            return
        }
        board.disconnectAsync().continueWith<Any> {
            this.board.disconnectAsync()
        }
    }

    private fun scan() {
        if (!::service.isInitialized || !::btManager.isInitialized) {
            Log.i(TAG, "bt service is not initialized")
            return
        }
        if (!::channel.isInitialized) {
            Log.i(TAG, "channel is not initialized")
            return
        }
        val bleScanner = btManager.adapter.bluetoothLeScanner;
        val bleScannerCallback = MetaWearBleScanCallback(context, channel)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
                && ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED) {
                Log.w(TAG, "missing BLUETOOTH_SCAN permission")
            return
        }
        Handler(Looper.getMainLooper()).postDelayed({
            bleScanner.stopScan(bleScannerCallback)
            bleScanActive = false
        }, BLE_SCAN_PERIOD)
        if (bleScanActive) {
            Log.i(TAG, "ble scan already active")
        } else {
            bleScanner.startScan(bleScannerCallback)
            bleScanActive = true
        }
    }
}