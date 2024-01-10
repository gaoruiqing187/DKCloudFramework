//
//  DKCloudKit.swift
//  DKCloudManager
//
//  Created by Mr Mac on 2023/12/28.
//

import Foundation
import linphonesw

struct DKAccount : Codable{
    var projectId : String = ""
    var agentId : String = ""
    var extensionId : String = ""
    var host : String = ""
    var port : String = ""
    var token : String = ""
    var password : String = ""
    var domain : String = ""
    var agentState : Int = 0
    var phoneNum : String = ""
    var linkedId : String = ""
    var telx : String?
    var userfield: String?
    var numberGroupId : String?
    var reason : String?
    
    mutating func clearCallInfo() {
        linkedId = ""
        phoneNum = ""
        telx = nil
        userfield = nil
        numberGroupId = nil
    }
}

struct SocketInfo : Codable {
    var `extension`:String?
    var projectId: String?
    var data:SocketData?
    var token: String?
    var code: String?
    var message: String?
    var agentid: String?
    var source: String?
    var eventType: String
    var reason: String?
    var type: String?
    var queue: String?
    var state: Int?
    var retCode: String?
    
    var originate_telb: String?
    var originate_tela: String?
    var originate_option: String?
    var connectedLineNum: String?
    var originate_agentId: String?
    var channel: String?
    var cause: String?
    var language: String?
    var privilege: String?
    var exten: String?
    var channelState: Int?
    var duration: String?
    var callerIdNum: String?
    var systemName: String?
    var dateReceived: Double?
    var context: String?
    var callerRole: String?
    var bothbillsec: String?
    var billsec: String?
    var linkedId: String?
    var accountCode: String?
    var originate_dialmode: String?
    var priority: Int?
    var answer_status_code: String?
    var callerId: String?
    var channelStateDesc: String?
    var causeTxt: String?
    var uniqueId: String?
    var bridgeNumChannels: Int?
    var bridgeTechnology: String?
    var bridgeType: String?
    var bridgeUniqueId: String?
}

struct SocketData : Codable {
    var webrtcip: String?
    var pjsipport: Int?
    var sipport: Int?
    var realm: String?
}

public protocol DKCloudKitDelegate {
    func registrationSuccessful()
    func registrationFailedWithError(_ error:String)
}

public enum CallStatus {
    case dialing
    case incomingCall
    case ringing
    case connected
    case onLine
    case ended
    case pause
    case error
}

enum EventType {
    case call
    case setAgent
}

private let shared = DKCloudKit()

public class DKCloudKit : DKWebSocketDelegate{

    public class var manager: DKCloudKit {

      return shared
    }

    private var loggedIn = false
    
    private var isActiveCall = false
    
    private var hasNetwork = true

    private var mCore:Core!

    private var mRegistrationDelegate : CoreDelegate!
    
    private var socketManager = WebSocketManager.shard

    private var userAccount = DKAccount()
    
    private var onRegisteBlock: ((Bool, String?) -> Void)?
    
    private var registeBlock:(()->Void)?
    
    private var onCallBlock: ((CallStatus, String?)->Void)?
    
    private var answerCallBlock: ((CallStatus, String?)->Void)?

    private var onSetAgentBlock: ((Bool, Int, String?)->Void)?
    
    private var onTestExtensionBlock: (()->Void)?
    
    var eventType : EventType = .call
    
    var currentCallStatus = CallStatus.ended
            
    init(){
        LoggingService.Instance.logLevel = LogLevel.Debug
        try? mCore = Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)
        try? mCore.start()
        socketManager.delegate = self
        mRegistrationDelegate = CoreDelegateStub(onCallStateChanged:{[self] (core: Core, call: Call, state: Call.State, message: String) in
            var messages = message
            if (state == .OutgoingInit) {
                // First state an outgoing call will go through
                currentCallStatus = .dialing
            } else if (state == .OutgoingProgress) {
                // Right after outgoing init
            } else if (state == .OutgoingRinging) {
                // This state will be reached upon reception of the 180 RINGING
                currentCallStatus = .ringing
            } else if (state == .Connected) {
                // When the 200 OK has been received
                currentCallStatus = .connected
                messages = ""
            } else if (state == .StreamsRunning) {

            } else if (state == .IncomingReceived){
                if isActiveCall {
                    answer(handler: nil)
                }
            } else if (state == .Paused) {
                // When you put a call in pause, it will became Paused
                currentCallStatus = .pause
            } else if (state == .PausedByRemote) {
                // When the remote end of the call pauses it, it will be PausedByRemote
            } else if (state == .Updating) {
                // When we request a call update, for example when toggling video
            } else if (state == .UpdatedByRemote) {
                // When the remote requests a call update
            } else if (state == .Released) {
                // Call state will be released shortly after the End state
                currentCallStatus = .ended
                isActiveCall = false
            } else if (state == .Error) {
                currentCallStatus = .ended
                isActiveCall = false
            }
            onCallBlock?(currentCallStatus,messages)
        }, onAccountRegistrationStateChanged: { [self] (core: Core, account: Account, state: RegistrationState, message: String) in
            
            // If account has been configured correctly, we will go through Progress and Ok states
            // Otherwise, we will be Failed.
            NSLog("New registration state is \(state) for user id \( String(describing: account.params?.identityAddress?.asString()))\n")
            if (state == .Ok) {
                self.loggedIn = true
                onRegisteBlock?(true,nil)
            } else if (state == .Cleared) {
                self.loggedIn = false
            } else if (state == .Failed){
                self.loggedIn = false
                onRegisteBlock?(false,message)
            }
        })
        mCore.addDelegate(delegate: mRegistrationDelegate)
    }

    public func loginAccount(url:String, projectId:String, password:String,
                             agentId:String, extensionId:String, token:String, handler:@escaping (Bool,String?)->Void){
        
        if loggedIn {
            return
        }
        
        onRegisteBlock = handler
        let urls = "wss://\(url)/ws/agent?agentid=\(agentId)&extension=\(extensionId)&projectId=\(projectId)&token=\(token)&source=1&queue="
        userAccount.extensionId = extensionId
        userAccount.projectId = projectId
        userAccount.agentId = agentId
        userAccount.token = token
        userAccount.password = password
        socketManager.registerAccount(url: urls)
    }
    
    private func callOut(){
        var dict :[String:Any] = [:]
        dict["eventType"] = "MakeCall"
        dict["telx"] = userAccount.telx
        dict["userfield"] = userAccount.userfield
        dict["numberGroupId"] = userAccount.numberGroupId
        dict["callednum"] = userAccount.phoneNum
        
        if let jsonString = TransformUtils.dictToJson(dict: dict) {
            socketManager.sendMessage(message: jsonString)
        }
    }
    
    public func callOut(phoneNum: String, telx: String, userfueld: String, numberGroupId: String, handler: ((CallStatus, String?)->Void)?){
        onCallBlock = handler
        eventType = .call
        if phoneNum.isEmpty {
            onCallBlock?(.error,"The phoneNum cannot be empty")
            return
        }
        
        testingLogin {[self] islogin in
            isActiveCall = true
            userAccount.phoneNum = phoneNum
            userAccount.telx = telx
            userAccount.userfield = userfueld
            userAccount.numberGroupId = numberGroupId
            testingExtensionChange()
        }
    }
    
    public func answer(handler:((CallStatus, String?)->Void)?){
        answerCallBlock = handler
        testingLogin {[self] islogin in
            if mCore.currentCall != nil{
                do {
                    try mCore.currentCall?.accept()
                } catch {
                    answerCallBlock?(.error,error.localizedDescription)
                    NSLog(error.localizedDescription)
                }
            }else{
                handler?(.error,"No call is currently in progress")
            }
        }
    }
    
    public func hangUp(){
        testingLogin {[self] islogin in
            if mCore.currentCall != nil{
                do {
                    if (mCore.callsNb == 0) { return }
                    
                    // If the call state isn't paused, we can get it using core.currentCall
                    let coreCall = (mCore.currentCall != nil) ? mCore.currentCall : mCore.calls[0]
                    
                    // Terminating a call is quite simple
                    if let call = coreCall {
                        try call.terminate()
                    }
                } catch {
                    NSLog(error.localizedDescription)
                }
            }else{
                onCallBlock?(.error,"No call is currently in progress")
            }
        }
    }
    
    public func pauseOrResume(){
        testingLogin {[self] islogin in
            do {
                if (mCore.callsNb == 0) { return }
                let coreCall = (mCore.currentCall != nil) ? mCore.currentCall : mCore.calls[0]
                
                if let call = coreCall {
                    if (call.state != Call.State.Paused && call.state != Call.State.Pausing) {
                        // If our call isn't paused, let's pause it
                        try call.pause()
                    } else if (call.state != Call.State.Resuming) {
                        // Otherwise let's resume it
                        try call.resume()
                    }
                }else{
                    onCallBlock?(.error,"No call is currently in progress")
                }
            } catch { NSLog(error.localizedDescription) }
        }
    }
    
    public func changeOver(callNum:String, mode: Int = 0){
        if mCore.currentCall != nil {
            var dict :[String:Any] = [:]
            dict["eventType"] = "AgentInterface"
            dict["type"] = "atxfer"
            dict["agentid"] = userAccount.agentId
            dict["extension"] = userAccount.extensionId
            dict["ext2"] = callNum
            dict["linkedId"] = userAccount.linkedId
            dict["mode"] = mode
            if let jsonString = TransformUtils.dictToJson(dict: dict) {
                socketManager.sendMessage(message: jsonString)
            }
        }
    }
    
    public func changeOverHangUp(){
        if mCore.currentCall != nil {
            var dict :[String:Any] = [:]
            dict["eventType"] = "AgentInterface"
            dict["type"] = "atxferHangup"
            dict["agentid"] = userAccount.agentId
            dict["linkedId"] = userAccount.linkedId
            if let jsonString = TransformUtils.dictToJson(dict: dict) {
                socketManager.sendMessage(message: jsonString)
            }
        }
    }
    
    public func logOut(){
        if let account = mCore.defaultAccount {
            
            if mCore.currentCall != nil{
                do {
                    if (mCore.callsNb == 0) { return }
                    
                    // If the call state isn't paused, we can get it using core.currentCall
                    let coreCall = (mCore.currentCall != nil) ? mCore.currentCall : mCore.calls[0]
                    
                    // Terminating a call is quite simple
                    if let call = coreCall {
                        try call.terminate()
                    }
                } catch {
                    NSLog(error.localizedDescription)
                }
            }
            
            mCore.removeAccount(account: account)
            mCore.clearAccounts()
            mCore.clearAllAuthInfo()
            mCore.refreshRegisters()
            logOutAgent()
        }
    }
    
    private func logOutAgent(){
        var dict :[String:Any] = [:]
        dict["eventType"] = "AgentInterface"
        dict["type"] = "agentlogout"
        dict["agentid"] = userAccount.agentId
        dict["extension"] = userAccount.extensionId
        
        if let jsonString = TransformUtils.dictToJson(dict: dict) {
            socketManager.sendMessage(message: jsonString)
        }
    }
    
    private func setAgentStatus(){
        var dict :[String:Any] = [:]
        dict["eventType"] = "AgentState"
        let state = (userAccount.agentState == 0 ? 1 : 0)
        dict["state"] = state
        if state == 1{
            dict["reason"] = userAccount.reason
        }else{
            dict["reason"] = nil
        }
        if let jsonString = TransformUtils.dictToJson(dict: dict) {
            socketManager.sendMessage(message: jsonString)
        }
    }
    
    public func changeAgentStatus(reason:String?,agentState:Int, handler: ((Bool, Int, String?)->Void)?){
        onSetAgentBlock = handler
        testingLogin { [self] islogin in
            eventType = .setAgent
            userAccount.agentState = agentState
            userAccount.reason = reason
            testingExtensionChange()
        }
    }

    
    private func testingExtensionChange(){
        let dict = ["eventType":"AgentInterface", "type": "getWebrtc"]
        if let jsonString = TransformUtils.dictToJson(dict: dict){
            socketManager.sendMessage(message: jsonString)
        }
    }
    
    private func eventTypeAction(){
        if eventType == .call {
            callOut()
        }else{
            setAgentStatus()
        }
    }
    
    public func websocketDidConnect(){
        print("Socket 已链接")
    }
        /**websocket 连接失败*/
    public func websocketDidDisconnect(error: String){
        print("Socket 链接失败: \(error)")
        onRegisteBlock?(false,"socket error")
    }
        /**websocket 接受文字信息*/
    public func websocketDidReceiveMessage(message: String){
        if message.contains("HangupEvent"){
            return
        }
        if let messageInfo = TransformUtils.convertToStruct(from: message){
            let code = messageInfo.code
            let eventType = messageInfo.eventType
            if eventType == "AgentLogin" {
                if code == "200" {
                    if let data = messageInfo.data {
                        if let realm = data.realm {
                            userAccount.host = realm
                        }

                        if let port = data.pjsipport {
                            userAccount.port = String(port)
                        }
                    }
                    userAccount.domain = userAccount.host + ":" + userAccount.port
                    userAccount.extensionId = messageInfo.extension!
                    registeSip()
                }else if code == "401" {
                    logOut()
                }
            }else if eventType == "Heartbeat"{
                return
            }else if eventType == "MakeCall"{
                userAccount.linkedId = messageInfo.linkedId ?? ""
            }else if eventType == "AgentInterface"{
                NSLog("31312")
                if messageInfo.type == "getWebrtc"{
                    if messageInfo.data?.realm == userAccount.host{
                        eventTypeAction()
                    }else{
                        if let data = messageInfo.data {
                            if let realm = data.realm {
                                userAccount.host = realm
                            }

                            if let port = data.pjsipport {
                                userAccount.port = String(port)
                            }
                        }
                        userAccount.domain = userAccount.host + ":" + userAccount.port
                        registeSip { [self] in
                            eventTypeAction()
                        }
                    }
                } else if messageInfo.type == "atxfer" {
                    print("3")
                } else if messageInfo.type == "atxferHangup" {
                    print("#21")
                } else if messageInfo.type == "agentlogout"{
                    if messageInfo.code == "200"{
                        socketManager.disconnect()
                        userAccount.clearCallInfo()
                        self.loggedIn = false
                        onRegisteBlock?(false,"log Out")
                    }
                }
            }else if eventType == "AgentState"{
                if messageInfo.code == "200" {
                    onSetAgentBlock?(true, userAccount.agentState, "")
                }else{
                    onSetAgentBlock?(false, userAccount.agentState, messageInfo.message)
                }
            }else if eventType == "HangUp"{

            }else if eventType == "BridgeEnterEvent"{
                onCallBlock?(.onLine,"answered successed")
            }
        }
    }
    
    
    private func registeSip(handler:(()->Void)?){
        registeBlock = handler
        do {
            let authInfo = try Factory.Instance.createAuthInfo(username: userAccount.extensionId, userid: "", passwd: userAccount.password, ha1: "", realm: "", domain: "")
            let accountParams = try mCore.createAccountParams()
            
            // A SIP account is identified by an identity address that we can construct from the username and domain
            print("identity ==== \(String("sip:" + userAccount.extensionId + "@" + userAccount.domain))")
            let identity = try Factory.Instance.createAddress(addr: String("sip:" + userAccount.extensionId + "@" + userAccount.domain))
            try! accountParams.setIdentityaddress(newValue: identity)

            // We also need to configure where the proxy server is located
            let address = try Factory.Instance.createAddress(addr: "sip:" + userAccount.domain)

            // We use the Address object to easily set the transport protocol
            try address.setTransport(newValue: TransportType.Udp)
            try accountParams.setServeraddress(newValue: address)
            // And we ensure the account will start the registration process
            accountParams.registerEnabled = true

            // Now that our AccountParams is configured, we can create the Account object
            let account = try mCore.createAccount(params: accountParams)

            // Now let's add our objects to the Core
            mCore.addAuthInfo(info: authInfo)
            try mCore.addAccount(account: account)
            
            // Also set the newly added account as default
            mCore.defaultAccount = account
            
        } catch  {
            NSLog(error.localizedDescription)
        }
    }
    
    private func registeSip(){
        registeSip(handler: nil)
    }
    
    private func testingLogin(handler:@escaping (Bool)->Void){
        print("#1312")
        let status = (socketManager.getConnectedStatus() && mCore.defaultAccount != nil)
        if status == true{
            handler(status)
        }else{
            onSetAgentBlock?(false, userAccount.agentState, "You need to call loginAccount() first")
            onCallBlock?(.error, "You need to call loginAccount() first")
        }
    }
}
