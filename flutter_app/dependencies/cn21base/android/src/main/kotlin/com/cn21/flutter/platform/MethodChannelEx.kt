package com.cn21.flutter.platform

import android.os.Looper
import android.util.Log

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.BinaryMessenger.BinaryMessageHandler
import io.flutter.plugin.common.BinaryMessenger.BinaryReply
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodCodec
import io.flutter.plugin.common.StandardMethodCodec
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor

import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicLong

/**
 * [MethodChannelEx]编解码调度器提供者对象，用于提供
 * 用于执行不同编解码任务的[Executor]实例
 */
interface MethodChannelScheduler {
    /**
     * 获取用于编码任务的[Executor]调度器函数实例
     * @param data 将要被编码的对象实例
     * @param refMethodCall 涉及的[MethodCall]对象，nullable
     * @param caller true表示用于作为调用方的参数编码(即data
     * 是调用invokeMethod时的参数)，false表示用于作为被调用方
     * 返回数据时的结果编码(即data是处理来自Native的invokeMethod
     * 调用后需要返回的结果)
     * @return [Executor]调度器函数或null表示不需要额外调度
     */
    fun schedulerForEncode(
            data: Any, refMethodCall: MethodCall?, caller: Boolean) : Executor

    /**
     * 获取用于解码任务的[Executor]调度器函数实例
     * @param data 将要被解码的原始数据
     * @param refMethodCall 涉及的[MethodCall]对象，nullable
     * @param caller true表示用于作为调用方获取到返回结果解码(即data
     * 是调用invokeMethod后返回的结果)，false表示用于作为被调用方
     * 对接收到的参数的解码(即data是处理来自Native的invokeMethod
     * 调用中的参数)
     * @return [Executor]调度器函数或null表示不需要额外调度
     */
    fun schedulerForDecode(
            data: ByteBuffer, refMethodCall: MethodCall?, caller: Boolean) : Executor

    /**
     * 获取用于消息(方法调用)处理的[Executor]调度器函数实例
     * @param refMethodCall 涉及的[MethodCall]对象
     * @return [Executor]调度器函数或null表示不需要额外调度
     */
    fun schedulerForHandleMessage(refMethodCall: MethodCall) : Executor
}

/**
 * 数据分批迭代提供处理函数定义
 * 当[MethodChannelEx]方法调用需要返回大量数据对象时，可提供该函数用于
 * 对返回的数据对象列表进行分割，以便分批传送处理。这样有利于
 * 1、提高内存的利用率和内存分配压力(小块内存更容易分配)，减少GC
 * 2、均衡对数据进行decode和转换及内存拷贝耗时，避免UI卡顿
 * @param list 需要分割的数据对象列表集合
 * @param refMethodCall 涉及的[MethodCall]对象实例
 * @return 分割的迭代器，每次迭代提供相应的该批次的数据对象子列表
 */
typealias SplitListIteratorHandler = (list: ArrayList<Any>, refMethodCall: MethodCall) -> Iterable<ArrayList<Any>>?

/**
 * 对象转换函数定义
 * 用于将[MethodChannelEx]中Codec解码返回的对象数据进行额外的转换操作
 * 例如[StandardMethodCodec]可能将调用返回的编码数据decode为List，然后
 * 通过此函数可以做任何将List转换为任意目标对象的操作。
 * 注意，此函数必须是顶级函数，不能是类中的方法。
 * @param from 经过Codec解码后的数据
 * @return 经过转换后的对象，作为[MethodChannelEx]中方法调用最终返回的实例。
 * 因此必须与invokeMethodAndConvert<T>中的T具有相容性
 */
typealias ConvertToObject = (from:Any?) -> Any?

/**
 * 扩展的[MethodChannel]，基本用法与[MethodChannel]相同，
 * 但针对[MethodChannel]在UI线程进行参数及返回结果的编解码
 * 进行了以下优化
 * 1、提供调度器机制，耗时的编解码及对象转换操作可在Isolate
 * 中进行处理
 * 2、提供对同时传送大量对象的调用结果进行分批传送机制，从而
 * 避免大内存分批造成的OOM、GC问题，同时避免UI线程的大内存拷贝
 * 耗时造成卡顿问题
 */
class MethodChannelEx(private val name: String, private val messenger: BinaryMessenger,
                      private val scheduler: MethodChannelScheduler? = null,
                      private val splitListHandler: SplitListIteratorHandler? = null,
                      codec: MethodCodec = StandardMethodCodec.INSTANCE) {

    private val osHandler = android.os.Handler(Looper.getMainLooper())
    private val methodCodec: MethodCodecEx
    private val dataChannelTrackList = arrayListOf<String>()

    init {
        methodCodec = MethodCodecEx(codec)
    }

    /**
     * 方法调用返回的数据通道描述对象
     * dataChannelName: 数据通道名称，全局唯一
     * elementCount: 列表元素的总数量（非分批数量）
     */
    private data class MethodStreamDataDesc(val dataChannelName: String, val elementCount: Int)

    /**
     * 方法编解码包装类
     */
    private inner class MethodCodecEx(val wrappedCodec: MethodCodec) : MethodCodec {
        override fun decodeMethodCall(data: ByteBuffer?): MethodCall {
            return wrappedCodec.decodeMethodCall(data)
        }

        override fun encodeErrorEnvelope(code: String?, message: String?, detail: Any?): ByteBuffer {
            return wrappedCodec.encodeErrorEnvelope(code, message, detail)
        }

        override fun encodeMethodCall(methodCall: MethodCall?): ByteBuffer {
            return wrappedCodec.encodeMethodCall(methodCall)
        }

        override fun encodeSuccessEnvelope(result: Any?): ByteBuffer {
            var wrapResult: ArrayList<*>
            if (result is MethodStreamDataDesc) {
                // 用流式数据通道传送数据
                wrapResult = arrayListOf(1, // 流式数据
                        result.dataChannelName, // 数据通道名称
                        result.elementCount) // 列表元素数量
                return wrappedCodec.encodeSuccessEnvelope(wrapResult)
            }
            // 用普通方式(非分割)编码
            wrapResult = arrayListOf(0, result)
            return wrappedCodec.encodeSuccessEnvelope(wrapResult)
        }

        override fun decodeEnvelope(envelope: ByteBuffer?): Any {
            var result = wrappedCodec.decodeEnvelope(envelope)
            // 执行至此表示没有异常发送
            if (result is ArrayList<*>) {
                val code = result[0] as Int
                if (code == 0) {
                    // 普通数据类型
                    return result[1]
                } else if (code == 1) {
                    // 数据流方式
                    return MethodStreamDataDesc(result[1] as String, result[2] as Int)
                }
            }
            return result
        }
    }

    /**
     * 任务分派调度方法
     * @param run 将在Executor中调度执行的方法
     * @param onResult 成功完成后回调的方法(在UI线程中执行)
     * @param onError 异常时回调的方法(在UI线程中执行)
     */
    private fun <R> autoDispatch(executor:Executor?, run: () -> R, onResult: ((r: R) -> Unit)?, onError: ((e: Throwable) -> Unit)? = null) {
        if (executor != null) {
            executor.execute {
                try {
                    val r = run()
                    if (onResult != null) {
                        osHandler.post { onResult(r) }
                    }
                } catch (e: Throwable) {
                    if (onError != null) {
                        osHandler.post { onError(e) }
                    }
                }
            }
        } else {
            try {
                val r = run()
                if (onResult != null) {
                    onResult(r)
                }
            } catch (e: Throwable) {
                if (onError != null) {
                    onError(e)
                }
            }
        }
    }

    //@UiThread
    fun invokeMethod(method: String, arguments: Any?) {
        invokeMethodInternal(method, arguments, null)
//        this.invokeMethod(method, arguments, null as MethodChannel.Result?)
    }

    //@UiThread
    fun invokeMethod(method: String, arguments: Any?, callback: MethodChannel.Result?) {
        invokeMethodInternal(method, arguments, callback)
//        val call = MethodCall(method, arguments)
//        autoDispatch(scheduler?.schedulerForEncode(call, call, true), {
//            return@autoDispatch this.methodCodec.encodeMethodCall(call)
//        }, onResult = {
//            this.messenger.send(this.name, it, if (callback == null) null else IncomingResultHandler(callback))
//        }, onError = {
//            callback?.error("error", it.message, null)
//        })
    }

    private fun invokeMethodInternal(method: String, arguments: Any?, callback: MethodChannel.Result?, convertHandler: ConvertToObject? = null) {
        val call = MethodCall(method, arguments)
        // 编码请求参数
        autoDispatch(scheduler?.schedulerForEncode(call, call, true), {
            return@autoDispatch methodCodec.encodeMethodCall(call)
        }, onResult = { result : ByteBuffer? ->
            // 构造响应结果的处理函数对象
            val reply = { data: ByteBuffer? ->
                if(callback != null) {
                    if(data == null) {
                        callback.notImplemented()
                    } else {
                        autoDispatch(scheduler?.schedulerForDecode(data, call, true), decodeResult@{
                            return@decodeResult decodeMethodResult(data, convertHandler)
                        }, onResult = { result ->
                            if(result is MethodStreamDataDesc) {
                                // 结果以流的方式由数据通道返回
                                val desc = result
                                var resultList = ArrayList<Any>()
                                resultList.ensureCapacity(desc.elementCount)
                                readResultFromDataChannel(desc, resultList, callback, convertHandler)
                            } else {
                                callback.success(result)
                            }
                        }, onError = {
                            callback.error("error", it.message, null)
                        })
                    }
                }
            }
            messenger.send(name, result, reply)
        }, onError = {
            callback?.error("error", it.message, null)
        })
    }

    // 处理调用返回结果的解码操作
    private fun decodeMethodResult(data: ByteBuffer, convertHandler: ConvertToObject? ) : Any? {
        val result = methodCodec.decodeEnvelope(data)
        // rawData可能是内部使用的[MethodStreamDataDesc]实例，
        // 在调用真正的handler前必须先过滤
        if (convertHandler != null && !(result is MethodStreamDataDesc)) {
            return convertHandler(result)
        } else {
            return result
        }
    }

    private val actionRecv = ByteBuffer.allocate(1)

    // 从指定的数据通道读取分批数据并还原，同时完成对象的转换操作
    private fun readResultFromDataChannel(
            desc: MethodStreamDataDesc, list: ArrayList<Any>, callback: MethodChannel.Result, convertHandler: ConvertToObject?) {
        var resultList = list
        if (resultList.size < desc.elementCount) {
            // 请求获取一次迭代的列表数据
            messenger.send(desc.dataChannelName, actionRecv)  {
                try {
                    if (it != null && it.remaining() > 0) {
                        val pack = methodCodec.wrappedCodec.decodeEnvelope(it) as ArrayList<*>
                        // 第0个元素表示数据传输类型，这里应该恒为0，表示不需要再分割(因为这个
                        // 数据通道就是用于接收已经分割好的各个分片数据)。第1个元素是分片后的数据
                        assert(pack[0] as Int == 0);
                        val result = pack[1] as ArrayList<*>
                        if (convertHandler != null) {
                            resultList.addAll(convertHandler(result) as ArrayList<Any>)
                        } else {
                            resultList.addAll(result)
                        }
                        if(resultList.size >= desc.elementCount) {
                            // 已完成数据接收
                            callback.success(resultList)
                        } else {
                            // 继续接收下一批数据
                            readResultFromDataChannel(desc, resultList, callback, convertHandler)
                        }
                    } else {
                        // 没有数据了
                        assert(resultList.size == desc.elementCount)
                        callback.success(resultList)
                    }
                } catch (e: Throwable) {
                    Log.e(TAG, "readResultFromDataChannel exception:$e")
                }
            }
        } else {
            // 没有数据了
            assert(resultList.size == desc.elementCount)
            callback.success(resultList)
        }
    }

    //@UiThread
    fun setMethodCallHandler(handler: MethodChannel.MethodCallHandler?) {
        this.messenger.setMessageHandler(this.name, if (handler == null) null else IncomingMethodCallHandler(handler))
    }

    private fun createEncodedIterable(codex: MethodCodec, orgIterable: Iterable<ArrayList<*>>): Iterable<ByteBuffer> {
        return orgIterable.map {
            return@map codex.encodeSuccessEnvelope(it)
        }
    }

    private inner class IncomingMethodCallHandler internal constructor(private val handler: MethodChannel.MethodCallHandler) : BinaryMessageHandler {
        private fun tryCreateDataStream(
                list: ArrayList<Any>, refMethodCall: MethodCall): MethodStreamDataDesc? {
            val iterable = splitListHandler?.invoke(list, refMethodCall)
            if (iterable != null) {
                // 需要对列表进行分割，创建额外数据通道进行处理
                val dataChannelName = "${name}_ndata:${sDataChannelsNumber.incrementAndGet()}"
                var currentIndex = 0
                // 在当前线程将所有需要分批传递的数据分别进行Encode，后续将在主线程
                // 将Encode后的ByteBuffer数据进行传递
                val encodedIterable = createEncodedIterable(methodCodec, iterable)
                val iterElementCount = encodedIterable.count()
                osHandler.post {
                    messenger.setMessageHandler(dataChannelName) { message: ByteBuffer?, reply: BinaryReply ->
                        // message非null表明继续接收数据，null表明主动断开数据通道
                        if (message != null) {
                            val result = encodedIterable.elementAt(currentIndex)
                            reply.reply(result)
                            currentIndex++
                            if (currentIndex >= iterElementCount) {
                                // 没有更多数据需要对方获取，关闭数据通道
                                messenger.setMessageHandler(dataChannelName, null)
                                dataChannelTrackList.remove(dataChannelName)
                            }
                            return@setMessageHandler
                        }
                        // reply null表明没有更多数据或数据通道将中断
                        reply.reply(null)
                        messenger.setMessageHandler(dataChannelName, null)
                        dataChannelTrackList.remove(dataChannelName)
                    }
                }
                dataChannelTrackList.add(dataChannelName)
                return MethodStreamDataDesc(dataChannelName, list.size)
            }
            // 无需分批处理
            return null
        }

        //@UiThread
        override fun onMessage(message: ByteBuffer?, reply: BinaryReply) {
            if(message == null) {
                reply.reply(null as ByteBuffer?)
                return
            }
            fun handleError(e: Throwable) {
                Log.e("$TAG" + this@MethodChannelEx.name, "Failed to handle method call", e)
                reply.reply(this@MethodChannelEx.methodCodec.encodeErrorEnvelope("error", e.message, null as Any?))
            }

            fun handleMessage(call: MethodCall) {
                try {
                    this.handler.onMethodCall(call, object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            if(result == null) {
                                osHandler.post {
                                    reply.reply(methodCodec.encodeSuccessEnvelope(null))
                                }
                                return
                            } else if (result is ArrayList<*>) {
                                // 尝试分割列表
                                val desc = tryCreateDataStream(result as ArrayList<Any>, call)
                                if (desc != null) {
                                    // 使用分批传递的方式传送结果数据，此处先创建数据通道
                                    // 并返回对应的通道名称及数据元素的数量
                                    osHandler.post {
                                        reply.reply(methodCodec.encodeSuccessEnvelope(desc))
                                    }
                                    return
                                }
                            }
                            // 不需要分批处理，正常返回result
                            // 调度执行结果的编码
                            autoDispatch(scheduler?.schedulerForEncode(result, call, false), {
                                // 不需要分批处理，正常返回result
                                return@autoDispatch this@MethodChannelEx.methodCodec.encodeSuccessEnvelope(result)
                            }, onResult = {
                                // 当前在ui线程中处理encodeSuccessEnvelope返回的result
                                Log.i(TAG, "MethodChannelEx.methodCodec.encodeSuccessEnvelope done.")
                                reply.reply(it)
                            }, onError = { handleError(it) })
                        }

                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                            osHandler.post {
                                reply.reply(this@MethodChannelEx.methodCodec.encodeErrorEnvelope(errorCode, errorMessage, errorDetails))
                            }
                        }

                        override fun notImplemented() {
                            osHandler.post {
                                reply.reply(null as ByteBuffer?)
                            }
                        }
                    })
                } catch (e: Throwable) {
                    handleError(e)
                }
            }

            autoDispatch(scheduler?.schedulerForDecode(message, null, false), {
                // 解码请求参数
                return@autoDispatch this@MethodChannelEx.methodCodec.decodeMethodCall(message)
            }, onResult = {
                // 正式分派处理到处理函数中执行
                autoDispatch(scheduler?.schedulerForHandleMessage(it), { handleMessage(it) }, onResult = null, onError = { e -> handleError(e)})
            }, onError = { handleError(it) })
        }
    }

//    private inner class IncomingResultHandler internal constructor(private val callback: MethodChannel.Result) : BinaryReply {
//
//        fun handleReplyError(e: Throwable) {
//            Log.e("$TAG" + this@MethodChannelEx.name, "Failed to handle method call result", e)
//        }
//
//        //@UiThread
//        override fun reply(reply: ByteBuffer?) {
//            try {
//                if (reply == null) {
//                    this.callback.notImplemented()
//                } else {
//                    autoDispatch(scheduler?.schedulerForDecode(reply, null, true), {
//                        return@autoDispatch this@MethodChannelEx.methodCodec.decodeEnvelope(reply)
//                    }, onResult = {
//                        this.callback.success(it)
//                    }, onError = {
//                        if (it is FlutterException) {
//                            this.callback.error(it.code, it.message, it.details)
//                        } else {
//                            handleReplyError(it)
//                        }
//                    })
//                }
//            } catch (e: Throwable) {
//                handleReplyError(e)
//            }
//        }
//    }

    companion object {
        private val TAG = "MethodChannelEx#"
        private var sDataChannelsNumber: AtomicLong = AtomicLong(0)
    }
}