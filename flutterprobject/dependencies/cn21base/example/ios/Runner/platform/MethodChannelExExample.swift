import Flutter
import UIKit
import cn21base

class MyScheduler: MethodChannelScheduler {
    let executor = MyExecutor()
    func schedulerForEncode(_ data: Any, _ refMethodCall: FlutterMethodCall?, caller: Bool) -> Executor {
        return executor
    }
    
    func schedulerForDecode(_ data: Data, _ refMethodCall: FlutterMethodCall?, _ caller: Bool) -> Executor {
        return executor
    }
    
    func schedulerForHandleMessage(_ refMethodCall: FlutterMethodCall) -> Executor {
        return executor
    }
    
    public init() {
    }
}

class MyExecutor: Executor {
    let queue = DispatchQueue.global()
    public func execute(_ entry: @escaping () -> Void) {
        queue.async(execute: entry)
    }
}

public class MethodChannelExExample: NSObject, FlutterPlugin {
    
    static let SPLIT_BOUNDRY_SIZE = 2000
    
    private var datalist : Array<Array<Any>>
    private var datamap : Array<Dictionary<String, Any>>
    
    let ELEMENT_COUNT = 100001
    private static var channel : MethodChannelEx? = nil
    
    public override init() {
        datalist = Array<Array<Any>>.init()
        datalist.reserveCapacity(ELEMENT_COUNT)
        for i in 0..<ELEMENT_COUNT {
            datalist.append(MethodChannelExExample.packListData(i + 1))
        }
        datamap = Array<Dictionary<String, Any>>.init()
        datamap.reserveCapacity(ELEMENT_COUNT)
        for i in 0..<ELEMENT_COUNT {
            datamap.append(MethodChannelExExample.packMapData(i + 1));
        }
        super.init()
    }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
//    let channel = FlutterMethodChannel(name: "MethodChannelExExample", binaryMessenger: registrar.messenger())
    if(MethodChannelExExample.channel != nil) {
        return
    }
    MethodChannelExExample.channel = MethodChannelEx(name: "MethodChannelExExample", messenger: registrar.messenger(), scheduler: MyScheduler(),
                                  splitListHandler:
        {(_ list: Array<Any>, _ refMethodCall: FlutterMethodCall) -> Iterable<Array<Any>>? in
            let total = list.count;
            if (total > MethodChannelExExample.SPLIT_BOUNDRY_SIZE && refMethodCall.method == "getDataFromListStream") {
                let count = (total + SPLIT_BOUNDRY_SIZE - 1) / SPLIT_BOUNDRY_SIZE
                var index = 0
                let it: AnyIterator<Array<Any>> = AnyIterator {
                    if(index >= total) {
                        return nil
                    }
                    var sliceSize = (total - index)
                    if (sliceSize > MethodChannelExExample.SPLIT_BOUNDRY_SIZE) {
                        sliceSize = SPLIT_BOUNDRY_SIZE
                    }
                    var subList = Array<Any>()
                    subList.reserveCapacity(sliceSize)
                    for i in index..<(index+sliceSize) {
                        subList.append(list[i])
                    }
                    index += sliceSize
                    return subList
                }
                return Iterable(count: count, iterator: it)
            }
            return nil;
        })
    let instance = MethodChannelExExample()
    MethodChannelExExample.channel!.setMethodCallHandler(handler: {call, callback in
        return instance.handle(call, result: callback)
    })
//    registrar.addMethodCallDelegate(instance, channel: channel)
  }
    
    private static func packListData(_ index: Int) -> Array<Any> {
        let data: Array<Any> = [
            "Person\(index)",
            "PersonId_\(index)",
            "room 201, Some Building, Some Dist, Some City, Some Province, China",
            20,
            1,
            180,
            60,
            "/sdcard/album/camera/img_00000001.jpg",
            "18900000000",
            "Some corp limited",
            "China",
            100000000
        ]
        return data;
    }
    
    private static func packMapData(_ index: Int) -> Dictionary<String, Any> {
        let data: Dictionary<String, Any> = [
            "name": "Person\(index)",
            "idNO": "PersonId_\(index)",
            "address": "room 201, Some Building, Some Dist, Some City, Some Province, China",
            "age": 20,
            "sex": 1,
            "height": 180,
            "weight": 60,
            "avatarImagePath": "/sdcard/album/camera/img_00000001.jpg",
            "phoneNO": "18900000000",
            "corp": "Some corp limited",
            "nature": "China",
            "birthDay": 10000000
        ]
        return data;
    }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if (call.method == ("getPlatformVersion")) {
        result("iOS " + UIDevice.current.systemVersion)
    } else if (call.method == ("getDataFromList")) {
        NSLog("flutter: getDataFromList native call.")
        result(datalist)
        NSLog("flutter: getDataFromList native done.")
    } else if (call.method == ("getDataFromMap")) {
        NSLog("flutter: getDataFromMap native call.")
        result(datamap)
        NSLog("flutter: getDataFromMap native done.")
    } else if (call.method == ("getDataFromListStream")) {
        NSLog("flutter: getDataFromListStream native call.")
        result(datalist)
        NSLog("flutter: getDataFromListStream native done.")
    } else if (call.method == "getDataFromFlutterToNative") {
        NSLog("flutter: getDataFromFlutterToNative native call.")
        MethodChannelExExample.channel?.invokeMethod("getDataFromListStream", nil, {result in
            if(result != nil) {
                if(result is FlutterError) {
                    NSLog("flutter: getDataFromListStream error:\(result!).")
                } else {
                    let list = result as! Array<Any>
                    NSLog("flutter: getDataFromListStream returns and decoded, length=\(list.count)")
                }
            }
            NSLog("flutter: getDataFromFlutterToNative native done.")
        })
        result(nil)
        
    } else {
        result(FlutterMethodNotImplemented)
    }

  }
}
