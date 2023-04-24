package com.example.ppiwd_work_breaks_frontend

import android.Manifest
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import java.util.TreeMap

class BleScanCallback(private val context: Context) : ScanCallback() {
    private val TAG = "ppiwd/MetaWearBleScanCallback"
    val devices = TreeMap<String, Map<String, String>>()

    override fun onScanResult(callbackType: Int, result: ScanResult) {
        super.onScanResult(callbackType, result)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
                && ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
            Log.w(TAG, "missing BLUETOOTH_READ permission")
        }
        if (devices.containsKey(result.device.address)) {
            return
        }
        devices[result.device.address] = mapOf(
                "name" to (result.device.name ?: "[no name]"),
                "mac" to result.device.address)
    }
}