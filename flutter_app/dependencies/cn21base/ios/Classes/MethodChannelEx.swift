//
//  MethodChannelEx.swift
//
//  Created by luogh on 2019/9/18.
//

import Foundation
import Flutter

/**
 * 调度执行器接口，负责运行指定的任务函数
 */
public protocol Executor {
    func execute(_ entry: @escaping ()->Void)
}

/**
* [MethodChannelEx]编解码调度器提供者对象，用于提供
* 用于执行不同编解码任务的[Executor]实例
 */
public protocol MethodChannelScheduler {
    /*
    * 获取用于编码任务的[ScheduleExecute]调度器函数实例
    * @param data 将要被编码的对象实例
    * @param refMethodCall 涉及的[MethodCall]对象，nullable
    * @param caller true表示用于作为调用方的参数编码(即data
    * 是调用invokeMethod时的参数)，false表示用于作为被调用方
    * 返回数据时的结果编码(即data是处理来自Native的invokeMethod
    * 调用后需要返回的结果)
    * @return [Executor]调度器函数或null表示不需要额外调度
     */
    func schedulerForEncode(
    _ data: Any, _ refMethodCall: FlutterMethodCall?, caller: Bool) -> Executor
    
    /*
    * 获取用于解码任务的[ScheduleExecute]调度器函数实例
    * @param data 将要被解码的原始数据
    * @param refMethodCall 涉及的[MethodCall]对象，nullable
    * @param caller true表示用于作为调用方获取到返回结果解码(即data
    * 是调用invokeMethod后返回的结果)，false表示用于作为被调用方
    * 对接收到的参数的解码(即data是处理来自Native的invokeMethod
    * 调用中的参数)
    * @return [Executor]调度器函数或null表示不需要额外调度
     */
    func schedulerForDecode(
        _ data: Data, _ refMethodCall: FlutterMethodCall?, _ caller: Bool) -> Executor
    
    /**
     * 获取用于消息(方法调用)处理的[Executor]调度器函数实例
     * @param refMethodCall 涉及的[MethodCall]对象
     * @return [Executor]调度器函数或null表示不需要额外调度
     */
    func schedulerForHandleMessage(_ refMethodCall: FlutterMethodCall) -> Executor
}

/**
 * 列表数据分批迭代器对象
 */
public class Iterable<T> {
    public init(count: Int, iterator: AnyIterator<T>) {
        self.count = count
        self.iterator = iterator
    }
    let count: Int // 迭代器中T元素总数量
    let iterator: AnyIterator<T> // T元素迭代器实例
}

/**
 * 方法调用返回的数据通道描述对象
 * dataChannelName: 数据通道名称，全局唯一
 * elementCount: 列表元素的总数量（非分批数量）
 */
private class MethodStreamDataDesc {
    var dataChannelName: String
    var elementCount: Int
    init(dataChannelName: String, elementCount: Int) {
        self.dataChannelName = dataChannelName
        self.elementCount = elementCount
    }
}

// FIXME: Is MethodCodecEx thread-safe?
/**
 * 方法编解码包装类
 */
private class MethodCodecEx : NSObject, FlutterMethodCodec {

    static let sInstance = MethodCodecEx(wrappedCodec: FlutterStandardMethodCodec.sharedInstance())

    static func sharedInstance() -> Self {
        func sharedInstanceImpl<T>() -> T {
            return sInstance as! T
        }
        return sharedInstanceImpl()
    }

    let wrappedCodec: FlutterMethodCodec
    init(wrappedCodec: FlutterMethodCodec) {
        self.wrappedCodec = wrappedCodec
        super.init()
    }

    func decodeMethodCall(_ data: Data) -> FlutterMethodCall {
        return self.wrappedCodec.decodeMethodCall(data)
    }

    func encodeErrorEnvelope(_ error: FlutterError) -> Data {
        return self.wrappedCodec.encodeErrorEnvelope(error)
    }

    func encode(_ methodCall: FlutterMethodCall) -> Data {
        return self.wrappedCodec.encode(methodCall)
    }

    func encodeSuccessEnvelope(_ result: Any?)-> Data {
        var wrapResult: Array<Any>
        if (result is MethodStreamDataDesc) {
            // 用流式数据通道传送数据
            let desc = result as! MethodStreamDataDesc
            wrapResult = [1, // 流式数据
                desc.dataChannelName, // 数据通道名称
                desc.elementCount] // 列表元素数量
            return wrappedCodec.encodeSuccessEnvelope(wrapResult)
        }
        // 用普通方式(非分割)编码
        wrapResult = [0, result as Any]
        return wrappedCodec.encodeSuccessEnvelope(wrapResult)
    }

    func decodeEnvelope(_ envelope: Data) -> Any? {
        let result = wrappedCodec.decodeEnvelope(envelope)
        // 执行至此表示没有异常发送
        if (result != nil && result is Array<Any>) {
            let pack:Array<Any> = result as! Array<Any>
            let code:Int = pack[0] as! Int
            if (code == 0) {
                // 普通数据类型
                return pack[1]
            } else if (code == 1) {
                // 数据流方式
                return MethodStreamDataDesc(dataChannelName: pack[1] as! String, elementCount: pack[2] as! Int)
            }
        }
        return result
    }
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
public typealias SplitListIteratorHandler = (_ list: Array<Any>, _ refFlutterMethodCall: FlutterMethodCall) -> Iterable<Array<Any>>?

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
public typealias ConvertToObject = (_ from:Any?) throws -> Any?

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
public class MethodChannelEx {
    private var methodCodec: MethodCodecEx
    private var dataChannelTrackList = [String]()
    private var messenger: FlutterBinaryMessenger
    private var name: String
    private var scheduler: MethodChannelScheduler?
    private var splitListHandler: SplitListIteratorHandler?
    
    public init(name: String, messenger: FlutterBinaryMessenger,
         scheduler: MethodChannelScheduler? = nil,
         splitListHandler: SplitListIteratorHandler? = nil,
        codec: FlutterMethodCodec = FlutterStandardMethodCodec.init(readerWriter: FlutterStandardReaderWriter())) {
        self.name = name
        self.messenger = messenger
        self.methodCodec = MethodCodecEx(wrappedCodec: codec)
        self.scheduler = scheduler
        self.splitListHandler = splitListHandler
    }
    
    /**
     * 任务分派调度方法
     * @param run 将在Executor中调度执行的方法
     * @param onResult 成功完成后回调的方法(在UI线程中执行)
     * @param onError 异常时回调的方法(在UI线程中执行)
     * */
    private func autoDispatch<R>(_ executor: Executor?, _ run: @escaping () throws -> R?, onResult: ((_ r:R?)->Void)?, onError: ((_ e:Error)->Void)? = nil) {
        if (executor != nil) {
            executor!.execute {
                do {
                    let r = try run()
                    if (onResult != nil) {
                        DispatchQueue.main.async {
                            onResult!(r)
                        }
                    }
                } catch let e {
                    if (onError != nil) {
                        DispatchQueue.main.async {
                            onError!(e)
                        }
                    }
                }
            }
        } else {
            do {
                let r = try run()
                if (onResult != nil) {
                    onResult?(r)
                }
            } catch let e {
                if (onError != nil) {
                    onError!(e)
                }
            }
        }
    }
    
    //@UiThread
    public func invokeMethod(_ method: String, _ arguments: Any?) {
        self.invokeMethodInternal(method, arguments, nil)
    }
    
    //@UiThread
    public func invokeMethod(_ method: String, _ arguments: Any?, _ callback: FlutterResult?) {
        self.invokeMethodInternal(method, arguments, callback, nil)
        //        this.messenger.send(this.name, this.methodCodec.encodeFlutterMethodCall(FlutterMethodCall(method, arguments)), if (callback == null) null else IncomingResultHandler(callback))
    }
    
    // 在invokeMethod的基础上对解码后的数据通过convertHandler转换为适合类型的对象
    public func invokeMethodAndConvert(
        _ method: String, _ arguments: Any?, _ callback: FlutterResult?, _ convertHandler: @escaping ConvertToObject) {
        invokeMethodInternal(method, arguments, callback, convertHandler);
    }
    
    private func invokeMethodInternal(_ method: String, _ arguments: Any?, _ callback: FlutterResult?, _ convertHandler: ConvertToObject? = nil) {
        let call = FlutterMethodCall(methodName: method, arguments: arguments)
        // 编码请求参数
        autoDispatch(self.scheduler?.schedulerForEncode(call, call, caller: true), {
            return self.methodCodec.encode(call)
        }, onResult: { result in
            // 构造响应结果的处理函数对象
            let reply = {(_ data: Data?) in
                if(callback != nil) {
                    if(data == nil) {
                        callback!(FlutterMethodNotImplemented)
                    } else {
                        self.autoDispatch(self.scheduler?.schedulerForDecode(data!, call, true), {
                            return try self.decodeMethodResult(data!, convertHandler)
                        }, onResult: { result in
                            if(result is MethodStreamDataDesc) {
                                // 结果以流的方式由数据通道返回
                                let desc = result as! MethodStreamDataDesc
                                var resultList = Array<Any>()
                                resultList.reserveCapacity(desc.elementCount)
                                self.readResultFromDataChannel(desc, resultList, callback!, convertHandler)
                            } else {
                                callback!(result)
                            }
                        }, onError: { error in
                            callback!(self.convertToFlutterError(error))
                        })
                    }
                }
            }
            self.messenger.send(onChannel: self.name, message: result, binaryReply: reply)
        }, onError: { error in
            callback?(self.convertToFlutterError(error))
        })
    }
    
    // 处理调用返回结果的解码操作
    private func decodeMethodResult(_ data: Data, _ convertHandler:ConvertToObject? ) throws -> Any? {
        let result = self.methodCodec.decodeEnvelope(data)
        // rawData可能是内部使用的[MethodStreamDataDesc]实例，
        // 在调用真正的handler前必须先过滤
        if (convertHandler != nil && !(result is MethodStreamDataDesc)) {
            return try convertHandler!(result)
        } else {
            return result
        }
    }
    
    let actionRecv = Data.init(bytes: [0])
    
    // 从指定的数据通道读取分批数据并还原，同时完成对象的转换操作
    private func readResultFromDataChannel(
        _ desc: MethodStreamDataDesc, _ list: Array<Any>, _ callback: @escaping FlutterResult, _ convertHandler: ConvertToObject?) {
        var resultList = list
        if (resultList.count < desc.elementCount) {
            // 请求获取一次迭代的列表数据
            self.messenger.send(onChannel: desc.dataChannelName, message: actionRecv, binaryReply: {data in
                do {
                    if (data != nil && data!.count > 0) {
                        let pack = self.methodCodec.wrappedCodec.decodeEnvelope(data!) as! Array<Any>
                        // 第0个元素表示数据传输类型，这里应该恒为0，表示不需要再分割(因为这个
                        // 数据通道就是用于接收已经分割好的各个分片数据)。第1个元素是分片后的数据
                        assert(pack[0] as! Int == 0);
                        let result = pack[1] as! Array<Any>
                        if (convertHandler != nil) {
                            resultList.append(contentsOf: try convertHandler!(result) as! Array<Any>)
                        } else {
                            resultList.append(contentsOf: result)
                        }
                        if(resultList.count >= desc.elementCount) {
                            // 已完成数据接收
                            callback(resultList)
                        } else {
                            // 继续接收下一批数据
                            self.readResultFromDataChannel(desc, resultList, callback, convertHandler)
                        }
                    } else {
                        // 没有数据了
                        assert(resultList.count == desc.elementCount)
                        callback(resultList);
                    }
                } catch let e {
                    debugPrint("readResultFromDataChannel exception:\(e)");
                }
            })
        } else {
            // 没有数据了
            assert(resultList.count == desc.elementCount)
            callback(resultList)
        }
    }
    
    //@UiThread
    public func setMethodCallHandler(handler: FlutterMethodCallHandler?) {
        var wrapHandler: FlutterBinaryMessageHandler? = nil
        if(handler != nil) {
            wrapHandler = {message, reply in
                if(message == nil) {
                    reply(nil)
                    return
                }
                self.autoDispatch(self.scheduler?.schedulerForDecode(message!, nil, false), { () -> FlutterMethodCall? in
                    // Decode出请求参数
                    let call = self.methodCodec.decodeMethodCall(message!)
                    return call
                }, onResult: { call in
                    self.autoDispatch(self.scheduler?.schedulerForDecode(message!, nil, false), { () -> Data? in
                        // 分发给处理器处理请求
                        handler!(call!, {result in
                            // 处理Native端的执行结果
                            if(result is NSObject && result as! NSObject === FlutterMethodNotImplemented) {
                                DispatchQueue.main.async {
                                    reply(nil)
                                }
                            } else if(result is FlutterError) {
                                DispatchQueue.main.async {
                                    reply(self.methodCodec.encodeErrorEnvelope((result as! FlutterError)))
                                }
                            } else {
                                if(result == nil) {
                                    DispatchQueue.main.async {
                                        reply(self.methodCodec.encodeSuccessEnvelope(nil))
                                    }
                                    return
                                }
                                if (result is Array<Any>) {
                                    // 尝试分割列表
                                    let desc = self.tryCreateDataStream(result as! Array<Any>, call!)
                                    if (desc != nil) {
                                        // 使用分批传递的方式传送结果数据，此处先创建数据通道
                                        // 并返回对应的通道名称及数据元素的数量
                                        DispatchQueue.main.async {
                                            reply(self.methodCodec.encodeSuccessEnvelope(desc))
                                        }
                                        return
                                    }
                                }
                                // 不需要分批处理，正常返回result
                                // 调度执行结果的编码
                                self.autoDispatch(self.scheduler?.schedulerForEncode(result!, call, caller: false), { () -> Data in
                                    return self.methodCodec.encodeSuccessEnvelope(result)
                                }, onResult: {result in
                                    // 当前在ui线程中处理encodeSuccessEnvelope返回的result
                                    NSLog("MethodChannelEx.methodCodec.encodeSuccessEnvelope done.")
                                    reply(result)
                                }, onError: { error in self.handleError(reply, self.convertToFlutterError(error)) })
                            }
                        })
                        return nil
                    }, onResult: nil, onError: { error in self.handleError(reply, self.convertToFlutterError(error)) })
                }, onError: { error in self.handleError(reply, self.convertToFlutterError(error)) })
                
            }
        }
        self.messenger.setMessageHandlerOnChannel(self.name, binaryMessageHandler: wrapHandler)
    }
    
    private func convertToFlutterError(_ error: Any) -> FlutterError {
        if(error is NSError) {
            let e = error as! NSError
            return FlutterError(code: String(e.code), message: e.localizedDescription, details: nil)
        } else if(error is NSException) {
            let e = error as! NSException
            return FlutterError(code: e.reason ?? "Error", message: e.name.rawValue, details: nil)
        } else {
            return FlutterError(code: "Error", message: "\(error)", details: nil)
        }
    }
    
    private func handleError(_ reply: FlutterBinaryReply, _ e: FlutterError) {
        NSLog("self.name, Failed to handle method call. code:\(e.code) message:\(e.message ?? "")")
        reply(self.methodCodec.encodeErrorEnvelope(e))
    }
    
    private static func createEncodedIterable(_ codex: FlutterMethodCodec, _ orgIterable: AnyIterator<Array<Any>>) -> AnyIterator<Data> {
        let iterable: AnyIterator<Data> = AnyIterator {
            let value = orgIterable.next()
            if(value != nil) {
                return codex.encodeSuccessEnvelope(value)
            } else {
                return nil
            }
        }
        return iterable
    }
    
    private func tryCreateDataStream(
        _ list: Array<Any>, _ refFlutterMethodCall: FlutterMethodCall) -> MethodStreamDataDesc? {
        let iterable = self.splitListHandler?(list, refFlutterMethodCall)
        if (iterable != nil) {
            // 需要对列表进行分割，创建额外数据通道进行处理
            let number = OSAtomicIncrement64(&(MethodChannelEx.sDataChannelsNumber))
            let dataChannelName = "\(name)_ndata:\(number)"
            var currentIndex = 0
            // 在当前线程将所有需要分批传递的数据分别进行Encode，后续将在主线程
            // 将Encode后的Data数据进行传递
            let encodedIterable = MethodChannelEx.createEncodedIterable(self.methodCodec, iterable!.iterator)
            let iterElementCount = iterable!.count
            DispatchQueue.main.async {
                self.dataChannelTrackList.append(dataChannelName)
                self.messenger.setMessageHandlerOnChannel(dataChannelName, binaryMessageHandler: { (message: Data?, reply: FlutterBinaryReply) in
                    // message非null表明继续接收数据，null表明主动断开数据通道
                    if (message != nil) {
                        let result = encodedIterable.next()
                        reply(result)
                        currentIndex+=1
                        if (currentIndex >= iterElementCount || result == nil) {
                            // 没有更多数据需要对方获取，关闭数据通道
                            self.messenger.setMessageHandlerOnChannel(dataChannelName, binaryMessageHandler:nil)
                            let at = self.dataChannelTrackList.firstIndex(of: dataChannelName)
                            if(at != nil && at! >= 0) {
                                self.dataChannelTrackList.remove(at: at!)
                            }
                        }
                        return
                    }
                    // reply null表明没有更多数据或数据通道将中断
                    reply(nil)
                    self.messenger.setMessageHandlerOnChannel(dataChannelName, binaryMessageHandler:nil)
                    let at = self.dataChannelTrackList.firstIndex(of: dataChannelName)
                    if(at != nil && at! >= 0) {
                        self.dataChannelTrackList.remove(at: at!)
                    }
                })
            }
            return MethodStreamDataDesc(dataChannelName: dataChannelName, elementCount: list.count)
        }
        // 无需分批处理
        return nil
    }
    
    private static let TAG = "MethodChannelEx#"
    private static var sDataChannelsNumber: Int64 = 0
}
