package com.example.ppiwd_work_breaks_frontend

import android.bluetooth.BluetoothManager
import android.content.ComponentName
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.IBinder
import androidx.annotation.NonNull
import com.mbientlab.metawear.android.BtleService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity(), ServiceConnection {
    private val metaWearChannelSlug = "com.example.ppiwd_work_breaks_frontend/metawear"
    private val metaWearMethodCallHandler = MetaWearMethodCallHandler();

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applicationContext.bindService(Intent(this, BtleService::class.java),
                this, BIND_AUTO_CREATE)
    }

    override fun onDestroy() {
        super.onDestroy()
        applicationContext.unbindService(this)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, metaWearChannelSlug)
        metaWearMethodCallHandler.setChannel(channel)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, metaWearChannelSlug).setMethodCallHandler(metaWearMethodCallHandler)
    }

    override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
        val btManager = getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
        val localBinder = service as BtleService.LocalBinder
        metaWearMethodCallHandler.setService(localBinder, btManager)
    }

    override fun onServiceDisconnected(name: ComponentName?) {
        TODO("Not yet implemented")
    }
}
