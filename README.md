# DKCloudFramework

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

DKCloudFramework is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

Add source 'https://gitlab.linphone.org/BC/public/podspec.git'
    source 'git@github.com:gaoruiqing187/DKCloudSource.git'
in your podfile

```ruby
pod 'DKCloudFramework'
```

## connect 链接 
    url: 链接地址
    projectId: 项目ID
    password: 分机密码
    agentId: 坐席ID
    extensionId: 分机ID
    token: token
    state: 链接状态
    reason: 链接失败的原因
        DKCloudKit.manager.loginAccount(url: "", projectId: "", password: "", agentId: "", extensionId: "", token: "") {state, reason in
            if state == true {
                 "连接状态:已连接";
            }else{
                "连接状态:未连接" 
            }
        }

## disconnect 断开连接

        DKCloudKit.manager.logOut()
        
## callOut 外呼
        phoneNum: 呼叫的号码
        telx:
        userfueld:
        numberGroupId:
        DKCloudKit.manager.callOut(phoneNum: "", telx: "", userfueld: "", numberGroupId: "") { status, reason in
            print("")
        }

## hangup 挂断
        DKCloudKit.manager.hangUp()

## answer 应答
        status: 应答状态
        message: 应答信息
        DKCloudKit.manager.answer { status, message in
            
        }

## pause/resume 暂停/接回

        DKCloudKit.manager.pauseOrResume()
        
## changeAgentStatus 修改坐席状态
        reason: 置忙的原因
        agentState: 要设置的坐席状态 1.置忙 0.置闲
        success: 是否成功
        status: 当前状态
        message: 失败原因
        DKCloudKit.manager.changeAgentStatus(reason: "meeting", agentState: 1) { success, status, message in
            
        }
        
## returnCall 转接
        callNum: 转接的号码
        DKCloudKit.manager.changeOver(callNum: "")
        
## returnHangup 转接挂断

        DKCloudKit.manager.changeOverHangUp()
        

## getAgentStatus 获取坐席状态

        DKCloudKit.manager.getAgentStatus()
        
## haveAnyCallOnline 当前是否有通话
        DKCloudKit.manager.haveAnyCallOnline()

## Author

gaoruiqing187, 494063010@qq.com

## License

DKCloudFramework is available under the MIT license. See the LICENSE file for more info.
