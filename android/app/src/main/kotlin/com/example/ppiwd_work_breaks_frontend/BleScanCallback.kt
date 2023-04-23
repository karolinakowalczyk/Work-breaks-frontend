package com.example.ppiwd_work_breaks_frontend

import android.Manifest
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.MethodChannel

class BleScanCallback(private val context: Context, private val channel: MethodChannel,
                      private val callbackName: String) : ScanCallback() {
    private val TAG = "ppiwd/MetaWearBleScanCallback"
    override fun onScanResult(callbackType: Int, result: ScanResult) {
        super.onScanResult(callbackType, result)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
                && ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
            Log.w(TAG, "missing BLUETOOTH_READ permission")
        }
        channel.invokeMethod(callbackName, mapOf(
                "mac" to result.device.address,
                "name" to (result.device.name?: "[no name]")))

    }
}