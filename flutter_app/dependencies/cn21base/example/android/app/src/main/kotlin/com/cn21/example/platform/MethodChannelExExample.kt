package com.cn21.example.platform

import com.cn21.flutter.platform.MethodChannelEx
import com.cn21.flutter.platform.MethodChannelScheduler

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

import java.nio.ByteBuffer
import java.util.HashMap
import java.util.concurrent.Executors
import java.util.concurrent.Executor

import io.flutter.Log
import io.flutter.plugin.common.StandardMethodCodec

/**
 * MethodChannelExExample
 */
class MethodChannelExExample : MethodCallHandler {

    private val datalist = ArrayList<ArrayList<Any>>(100000)
    private val datamap: ArrayList<HashMap<String, Any>>

    init {
        for (i in 0..99999) {
            datalist.add(packListData(i + 1))
        }
        datamap = ArrayList<HashMap<String, Any>>(100000)
        for (i in 0..99999) {
            datamap.add(packMapData(i + 1))
        }
        //    ByteBuffer buffer = StandardMessageCodec.INSTANCE.encodeMessage(list);
        //    Log.i("flutter", "StandardMessageCodec.INSTANCE.encodeMessage(list) pos = "
        //            + buffer.position() + ", remaining = " + buffer.remaining()
        //            + ", offset = " + buffer.arrayOffset());
        //    datalist = buffer.array();
        //    Log.i("flutter", "buffer.array() length = " + datalist.length);
    }

    private fun packListData(index: Int): ArrayList<Any> {
        val data = ArrayList<Any>()
        data.add("Person$index")
        data.add("PersonId_$index")
        data.add("room 201, Some Building, Some Dist, Some City, Some Province, China")
        data.add(20)
        data.add(1)
        data.add(180)
        data.add(60)
        data.add("/sdcard/album/camera/img_00000001.jpg")
        data.add("18900000000")
        data.add("Some corp limited")
        data.add("China")
        data.add(System.currentTimeMillis())
        return data
    }

    /*
    *   MyData.name(
        this.name,
        this.idNO,
        this.address,
        this.age,
        this.sex,
        this.height,
        this.weight,
        this.avatarImagePath,
        this.phoneNO,
        this.corp,
        this.nature,
        this.birthDay);
        */
    private fun packMapData(index: Int): HashMap<String, Any> {
        val data = HashMap<String, Any>()
        data.put("name", "Person$index")
        data.put("idNO", "PersonId_$index")
        data.put("address", "room 201, Some Building, Some Dist, Some City, Some Province, China")
        data.put("age", 20)
        data.put("sex", 1)
        data.put("height", 180)
        data.put("weight", 60)
        data.put("avatarImagePath", "/sdcard/album/camera/img_00000001.jpg")
        data.put("phoneNO", "18900000000")
        data.put("corp", "Some corp limited")
        data.put("nature", "China")
        data.put("birthDay", System.currentTimeMillis())
        return data
    }

    private class MyScheduler : MethodChannelScheduler {

        override fun schedulerForEncode(data: Any, refMethodCall: MethodCall?, caller: Boolean): Executor {
            return MethodChannelExExample.executor
        }

        override fun schedulerForDecode(data: ByteBuffer, refMethodCall: MethodCall?, caller: Boolean): Executor {
            return MethodChannelExExample.executor
        }

        override fun schedulerForHandleMessage(refMethodCall: MethodCall): Executor {
            return MethodChannelExExample.executor
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method.equals("getDataFromList")) {
            Log.i("flutter", "getDataFromList native call.")
            result.success(datalist)
            Log.i("flutter", "getDataFromList native done.")
        } else if (call.method.equals("getDataFromMap")) {
            Log.i("flutter", "getDataFromMap native call.")
            result.success(datamap)
            Log.i("flutter", "getDataFromMap native done.")
        } else if (call.method.equals("getDataFromListStream")) {
            Log.i("flutter", "getDataFromListStream native call.")
            result.success(datalist)
            Log.i("flutter", "getDataFromListStream native done.")
        } else if (call.method.equals("getDataFromFlutterToNative")) {
            Log.i("flutter", "getDataFromFlutterToNative native call.")
            channel!!.invokeMethod("getDataFromListStream", null, object : Result {
                override fun success(data: Any?) {
                    val list = data as ArrayList<Any>
                    Log.i("flutter", "getDataFromListStream returns and decoded, length=" + list.size)
                }

                override fun error(s: String, s1: String?, o: Any?) {
                    Log.i("flutter", "getDataFromListStream error:$s")
                }

                override fun notImplemented() {
                    Log.i("flutter", "getDataFromListStream error: Not implemented.")
                }
            })
            Log.i("flutter", "getDataFromFlutterToNative native done.")
        } else {
            result.notImplemented()
        }
    }

    companion object {

        val SPLIT_BOUNDRY_SIZE = 1000

        private var channel: MethodChannelEx? = null

        /**
         * Plugin registration.
         */
        fun registerWith(registrar: Registrar) {
            //    final MethodChannel channel = new MethodChannel(registrar.messenger(), "myplugin");
            //    channel.setMethodCallHandler(new MethodChannelExExample());
            channel = MethodChannelEx("MethodChannelExExample", registrar.messenger(), MyScheduler(), splitHandler@{ list, refMethodCall ->
                val total = list.size
                if (total > SPLIT_BOUNDRY_SIZE && refMethodCall.method.equals("getDataFromListStream")) {
                    val count = (total + SPLIT_BOUNDRY_SIZE - 1) / SPLIT_BOUNDRY_SIZE
                    var index = 0
                    val splitList = ArrayList<ArrayList<Any>>(count)
                    do {
                        var sliceSize = total - index
                        if (sliceSize > SPLIT_BOUNDRY_SIZE) sliceSize = SPLIT_BOUNDRY_SIZE
                        val subList = ArrayList<Any>(sliceSize)
                        for (i in index until index + sliceSize) {
                            subList.add(list.get(i))
                        }
                        splitList.add(subList)
                        index += sliceSize
                    } while (index < total)
                    return@splitHandler splitList
                }
                return@splitHandler null
            }, StandardMethodCodec.INSTANCE)
            channel!!.setMethodCallHandler(MethodChannelExExample())
        }

        private val executor = Executors.newSingleThreadExecutor()
    }
}
