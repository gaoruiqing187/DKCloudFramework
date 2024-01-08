//
//  WebSocketManager.swift
//  DKCloudManager
//
//  Created by Mr Mac on 2023/12/27.
//

import Foundation
import SwiftUI
import Starscream

protocol DKWebSocketDelegate{
    /**websocket 连接成功*/
    func websocketDidConnect()
        /**websocket 连接失败*/
    func websocketDidDisconnect(error: String)
        /**websocket 接受文字信息*/
    func websocketDidReceiveMessage(message: String)
}

class WebSocketManager :  WebSocketDelegate{

    static let shard = WebSocketManager()

    private var socket: WebSocket!

    var delegate : DKWebSocketDelegate?

    private var isConnected = false

    var onRegiste: ((Bool,String?) -> Void)?
    var onReceiveMessage: ((String) -> Void)?
    var onError: (() -> Void)?

    init(){
        isConnected = false
    }

    func getConnectedStatus() -> Bool{
        return isConnected
    }

    //, handler:@escaping (Bool,String?)->Void
    func registerAccount(url:String){
//        onRegiste = handler
        var request = URLRequest(url: URL(string: url)!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
    }


    func sendMessage(message: String){
        socket.write(string: message)
    }


    func disconnect() {
        socket.disconnect()
    }


    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let dict):
            isConnected = true
            delegate?.websocketDidConnect()
            startHeartbeatTimer()
        case .disconnected(let string, _):
            isConnected = false
            delegate?.websocketDidDisconnect(error: string)
        case .text(let message):
            delegate?.websocketDidReceiveMessage(message: message)
            
        case .binary(let data):
            print(data)
        case .pong(_):
            break
        case .ping(_):
            break
        case .error(let error):
            isConnected = false
            handleError(error)
        case .viabilityChanged(let bool):
            print(bool)
        case .reconnectSuggested(let bool):
            print(bool)
        case .cancelled:
            print(#function + "cancelled")
            isConnected = false
        @unknown default:
            fatalError()
        }
    }

    func handleError(_ error: Error?) {
        if let e = error as? WSError {
            print("websocket encountered an error: \(e.message)")
        } else if let e = error {
            print("websocket encountered an error: \(e.localizedDescription)")
        } else {
            print("websocket encountered an error")
        }
    }

    func startHeartbeatTimer() {
        // 创建一个定时器，每隔一定时间发送心跳包
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { timer in
            // 发送心跳包消息
            self.sendHeartbeat()
        }
    }

    func sendHeartbeat() {
        // 发送心跳包消息到服务器
        var dict : [String:Any] = [:]
        dict["eventType"] = "Heartbeat"
        if let jsonString = TransformUtils.dictToJson(dict: dict) {
            socket.write(string: jsonString)
        }
    }
}

