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
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler


class MetaWearMethodCallHandler(private val context: Context) : MethodCallHandler {
    private val TAG = "ppiwd/MetaWearMethodCallHandler"
    private val PUT_ACCEL_CALBACK_SLUG = "putAccel"
    private val PUT_GYRO_CALLBACK_SLUG = "putGyro"
    private val PUT_BLE_SCANRESULT = "putBleScanResult"
    private val CONNECTED_CALBACK_SLUG = "connected"
    private val DISCONNECTED_CALBACK_SLUG = "disconnected"
    private val CONNECT_FAILURE_CALBACK_SLUG = "connectFailure"
    private val BLE_SCAN_PERIOD: Long = 10000
    private lateinit var service: LocalBinder
    private lateinit var btManager: BluetoothManager
    private lateinit var board: MetaWearBoard
    private lateinit var accelerometer: Accelerometer
    private lateinit var gyro: Gyro
    private lateinit var channel: MethodChannel
    private var bleScanActive = false

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "connect" -> connect(call.argument<String>("mac") ?: return)
            "disconnect" -> disconnect()
            "scan" -> scan(call.argument<Int>("period")?.toLong() ?: BLE_SCAN_PERIOD)
            "startMeasurements" -> startMeasurements()
            "stopMeasurements" -> stopMeasurements()
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
        requireServiceInitialized()
        requireChannelInitialized()
        requireBoardDisconnected()
        val remoteDevice: BluetoothDevice = btManager.adapter.getRemoteDevice(mac)
        board = service.getMetaWearBoard(remoteDevice)
        board.connectAsync().onSuccessTask(this::configureAccel)
                .onSuccessTask(this::configureGyro)
                .onSuccess {
                    handleBoardConnected(board)
                }
                .continueWith<Void> { task ->
                    if (task.isFaulted) {
                        handleBoardConnectFailure(board)
                        Log.w(TAG, "Failed to configure app", task.error)
                    }
                    null
                }
        board.onUnexpectedDisconnect {
            handleBoardDisconnected(board)
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
        return accelerometer.acceleration().addRouteAsync(AccelMetaWearRouteBuilder(channel, PUT_ACCEL_CALBACK_SLUG))
    }

    private fun configureGyro(task: Task<Route>): Task<Route>? {
        if (task.isFaulted) {
            return null
        }
        gyro = board.getModule(Gyro::class.java)
        gyro.configure()
                .odr(Gyro.OutputDataRate.ODR_50_HZ)
                .commit()
        return gyro.angularVelocity().addRouteAsync(GyroMetaWearRouteBuilder(channel, PUT_GYRO_CALLBACK_SLUG))
    }

    private fun disconnect() {
        requireBoardConnected()
        board.disconnectAsync().continueWith<Any> {
            handleBoardDisconnected(board)
        }
    }

    private fun scan(period: Long) {
        requireServiceInitialized()
        requireChannelInitialized()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
                && ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED) {
            Log.w(TAG, "missing BLUETOOTH_SCAN permission")
            return
        }
        val bleScanner = btManager.adapter.bluetoothLeScanner
        val bleScannerCallback = BleScanCallback(context)
        Handler(Looper.getMainLooper()).postDelayed({
            bleScanner.stopScan(bleScannerCallback)
            bleScanActive = false
            channel.invokeMethod(PUT_BLE_SCANRESULT, bleScannerCallback.devices)
        }, period)
        if (bleScanActive) {
            Log.w(TAG, "ble scan already active")
        } else {
            bleScanner.startScan(bleScannerCallback)
            bleScanActive = true
        }
    }

    private fun handleBoardDisconnected(board: MetaWearBoard) {
        Handler(Looper.getMainLooper()).post {
            this.board.disconnectAsync().onSuccess {
                channel.invokeMethod(DISCONNECTED_CALBACK_SLUG, mapOf("mac" to board.macAddress))
            }
        }
    }

    private fun handleBoardConnected(board: MetaWearBoard) {
        Handler(Looper.getMainLooper()).post {
            channel.invokeMethod(CONNECTED_CALBACK_SLUG, mapOf("mac" to board.macAddress))
        }
    }

    private fun handleBoardConnectFailure(board: MetaWearBoard) {
        Handler(Looper.getMainLooper()).post {
            channel.invokeMethod(CONNECT_FAILURE_CALBACK_SLUG, mapOf("mac" to board.macAddress))
        }
    }

    private fun startMeasurements() {
        requireSensorsInitialized()
        requireBoardConnected()
        accelerometer.acceleration().start()
        gyro.angularVelocity().start()
        accelerometer.start()
        gyro.start()
    }

    private fun stopMeasurements() {
        requireSensorsInitialized()
        requireBoardConnected()
        gyro.stop()
        accelerometer.stop()
        gyro.angularVelocity().stop()
        accelerometer.acceleration().stop()
    }


    private fun requireServiceInitialized() {
        if (!::service.isInitialized || !::btManager.isInitialized) {
            throw RuntimeException("bt service is not initialized")
        }
    }

    private fun requireChannelInitialized() {
        if (!::channel.isInitialized) {
            throw RuntimeException("channel is not initialized")
        }
    }

    private fun requireSensorsInitialized() {
        if (!::accelerometer.isInitialized) {
            throw RuntimeException("accelerometer is not initialized")
        }
        if (!::gyro.isInitialized) {
            throw RuntimeException("gyroscope is not initialized")
        }
    }

    private fun requireBoardConnected() {
        if (!::board.isInitialized || !board.isConnected) {
            throw RuntimeException("board is disconnected")
        }
    }

    private fun requireBoardDisconnected() {
        if (::board.isInitialized && board.isConnected) {
            throw RuntimeException("board is connected")
        }
    }
}