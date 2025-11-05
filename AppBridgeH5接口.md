# AppBridgeH5 接口需求清单（需SDK 实现）

> 本文档为统一的 H5 ↔ 原生 SDK 桥接接口规范，适用于公司所有 App WebView 调用场景。  
> 所有方法统一挂载在 `window.AppBridge` 命名空间下。  
> 返回统一：`Promise<{ code:number, data:any, msg?:string }>`，其中 `code=0` 表示成功。  

---

## 模块清单

### 1. core

- **core.getVersion**：桥接版本、App版本、平台。  
- **core.getEnv**：环境信息。  
- **core.ready**：等待原生初始化完成。  
- **core.has(path)**：探测方法是否存在。  如检查，`events.on`, `app.getStatus`
- **core.getCapabilities**：返回可用方法列表。  
- **core.setVpn**：设置vpn 
- **core.addShortcuts**：添加一个快捷方式图标
- **core.appIcon**：切换图标 

### 2. events

- **on/once/emit**：事件订阅与触发。  

### 3. app

- **getStatus**：前后台、省电、VPN状态。  
- **openSettings(section?)**：跳系统设置。  
- **exit/minimize**：退出/最小化。  
- **update.check/apply**：更新管理。  

### 4. nav

- **open/close/replace/setTitle/setBars**：页面与导航控制。  

### 5. ui

- **toast/alert/confirm/actionSheet/loading**：常用 UI。  
- **haptics**：震动反馈。  
- **safeArea**：刘海屏/底栏信息。 

### 6. storage

- **storage.get/set/remove/clear**：普通存储。 

### 7. permission

- **permission.check/request/ensure**：权限管理。  

### 8. device

- **device.getIds**：设备唯一性标识。  
- **device.getInfo**：平台、厂家、型号、系统版本等。  
- **device.getBattery/getStorageInfo/getMemoryInfo/getCpuInfo**：设备状态。 

### 9. share / clipboard

- **share.open({text,url,...})**：系统分享。  
- **share.copyLink({url})**：复制链接。  
- **clipboard.get/set**：剪贴板读写。  

### 10.  notifications

- **notifications.showLocal({title,body,...})**：本地通知。  

### 11. auth / payment

- **auth.getToken/refreshToken**：用户认证。  
- **payment.pay**：内购。  

### 12. download / apk / cache

- **download.start/pause/resume/cancel/status/list**：下载任务。  
- **download.m3u8({url,saveToDir,...})**：下载并合并m3u8。  
- **download.getDefaultDir() / setDefaultDir()**：获取/设置默认下载路径。  
- **download.getFilePath({id})**：获取任务文件路径。  
- **apk.download({url,saveTo?})**：下载APK。  
- **apk.install({path})**：安装APK。  
- **apk.open({packageName,...})**：打开指定App。  
- **apk.isInstalled({packageName})**：检查App是否安装。  
- **cache.getSize/clear**：缓存管理。 

[//]: # (### 13. sms / contacts)
[//]: # (- **sms.list&#40;{count?,from?,unreadOnly?}&#41;**：获取短信列表。  )
[//]: # (- **sms.observe&#40;{}&#41;**：监听新短信。  )
[//]: # (- **contacts.list&#40;{count?,search?}&#41;**：获取联系人列表。  )
[//]: # (- **contacts.getMyNumber&#40;&#41;**：获取本机号码。  )

### 14. appstore / testflight (iOS only)

- **appstore.open/search：打开 App Store 应用页或搜索页。  **
- **testflight.open：打开 TestFlight 邀请链接。  **

### 15. deeplink

- **deeplink.open/parse**：深链（打开第三方 App 内页面或本 App 内部页面）。  。  

### 16. liveActivity

- **liveActivity.start/update/stop**：实况。  

---

## 注意事项

1. **返回值统一**：所有方法返回 `Promise<{code,data,msg}>`，需判断 `code===0` 成功。  
2. **权限策略**：全部采用动态授权（Just-In-Time），推荐使用 `permission.ensure`。  
3. **平台差异**：  
   - APK 管理（apk.*）仅 Android 支持。  
   - appstore/testflight 仅 iOS 支持。  
   - m3u8 下载仅 Android 原生支持。  
   - phone.getNumber 在 iOS 多数情况不可用。  
4. **安全限制**：  
   - 短信/联系人/本机号码读取需用户授权，iOS 有严格限制。  
5. **深链 vs apk.open**：  
   - `deeplink.open` → 打开指定页面/功能（前提是对方 App 支持深链）。  
   - `apk.open` → Android 直接通过包名打开 App 主入口。  
   - 两者互补，不冲突。  

---


## 模块清单功能、参数与返回约束说明

### 1. core
- **core.getVersion**：桥接版本、App版本、平台。  
  
  - 作用：`桥接版本、App版本、平台。`
  - 参数：`无`  
  - 返回:  `Promise<{code:number, data:object, msg?:string}>`  
    - > ```json
      > {
      >   "bridgeVersion": "1.4.3",           // JSBridge 版本
      >   "appId": "com.xxx.app",             // 应用唯一 ID（内部定义）
      >   "appName": "XXX阅读器",              // 应用名称
      >   "packageName": "com.xxx.reader",    // 应用包名（Android）/ Bundle ID（iOS）
      >   "appVersion": "12.3.1",             // 应用版本号
      >   "buildNumber": "12345",             // 内部构建号
      >   "platform": "iOS",                  // 平台类型：iOS / Android
      >   "systemType": "iOS",                // 系统类型：iOS / Android / HarmonyOS
      >   "osVersion": "iOS 17.2",            // 系统版本
      >   "manufacturer": "Apple",            // 厂商
      >   "deviceModel": "iPhone14,2",        // 设备型号代号
      >   "brand": "Apple",                   // 品牌（Android 常见：Huawei, Xiaomi 等）
      >   "sdkInt": 34,                       // Android API Level（iOS 为 null）
      >   "channel": "AppStore",              // 分发渠道
      >   "region": "CN",                     // 地区
      >   "lang": "zh-CN",                    // 系统语言
      >   "isDebug": false                    // 是否 Debug 构建
      > }
      > ```
  
- **core.getEnv**：环境信息。  
  - 作用：环境信息。
  - 参数：`无`
  - 返回:  `Promise<{code:number, data:object, msg?:string}>`
  - > ```json
    > {
    > "env": "prod",                // 当前运行环境：prod / staging / dev
    > "channel": "AppStore",        // 分发渠道（AppStore / GooglePlay / 华为应用市场 / 内测包）
    > "region": "CN",               // 系统地区
    > "lang": "zh-CN",              // 系统语言
    > "timezone": "Asia/Shanghai",  // 当前时区
    > "networkType": "wifi",        // 网络类型：wifi / 4g / 5g / none
    > "isDebug": false,             // 是否 Debug 构建
    > "isEmulator": false,          // 是否模拟器
    > "buildType": "release",       // 构建类型：debug / release
    > "commitHash": "abc1234",      // （可选）代码提交号，用于溯源
    > "featureFlags": ["exp1","exp2"], // 已启用的实验或开关（可选）
    > "appId": "com.xxx.app"        // 应用 ID，方便和 getVersion 对齐
    > "foreground": true,       // 是否在前台
    > "powerSave": false,       // 是否开启省电模式
    > "vpnEnabled": true,       // 是否检测到 VPN/代理
    > "networkRestricted": false // 是否有后台网络限制
    > }
    > ```
  
- **core.ready**：等待原生初始化完成。  
  - 作用：环境信息。
  - 内部机制:  
  - > ```
    > 原生侧：在 WebView 初始化完成、桥接对象挂载完毕后，触发一个 ready 信号。
    > H5 侧：调用 core.ready() 时会等待该信号，确保后续 API 不会失败。
    > 事件触发：原生也可以通过 events.emit('ready') 主动广播。
    > ```
  - 参数：`无`  
  - 返回:  `Promise<{code:number, data: bool, msg?:string}>`    
  
- **core.has(path)**：
  - 作用：探测方法是否存在。
  - 参数：path 是一个字符串，表示方法的路径，例如：
    - "device.getInfo"
    - "apk.install"
  - 返回:  `Promise<{code:number, data: bool, msg?:string}>`    
- **getCapabilities**：返回可用方法列表。  
  - 作用：返回可用方法列表。
  - 参数：`无`
  - 返回:  `Promise<{code:number, array<string>, msg?:string}>`      
- **core.setVpn({on, config})**：设置 VPN。
  
  - 作用：设置 VPN
  - 参数：
    -  on: bool， true:开启, false:关闭
    -  config:  
    - > ```json
      > {
      >   "server": "vpn.example.com",
      >   "port": 443,
      >   "protocol": "IKEv2",   // PPTP / L2TP / IKEv2 / OpenVPN / WireGuard
      >   "username": "user123",
      >   "password": "****",
      >   "certificatePath": "/path/to/cert.pem" // 可选，证书认证时使用
      > }
      > ```
  - 返回:  `Promise<{code:number, array<string>, msg?:string}>`    
- **core.addShortcuts({title,url})**：
  - 作用：在系统桌面（或启动器）添加一个快捷方式图标，点击后可直接打开指定的 H5 页面或应用内路由。
  - 参数：
    - title： 快捷方式标题（显示在桌面图标下方）。：
    - url： 点击图标后跳转的地址（支持 H5 页面或 App 内路由）。
  - 注意事项：
    - Android：可通过 Launcher Shortcuts 或 PWA API 实现。
    - iOS：系统不支持直接添加快捷方式图标到桌面，通常需要通过 Siri Shortcuts 或 App Clip 替代。
- **core.appIcon({styleId})**：切换图标。  
  - 作用：切换应用图标（仅部分平台和系统支持），常用于节日皮肤（春节图标）或联名。
  - 参数：
    - styleId： 图标样式 ID（由原生预置多个图标资源）。
    - url： 点击图标后跳转的地址（支持 H5 页面或 App 内路由）。
### 2. events
- **core.on**：订阅事件（持续监听）。
  - 参数：
    - `event` (string) → 事件名。
    - `handler` (function) → 回调函数。
  - 返回:  一个 off 方法，可以手动取消监听。
- **once**：订阅一次性事件（触发一次后自动移除）。
  - 参数：
    - `event` (string) → 事件名。
    - `handler` (function) → 回调函数。
  - 返回:  一个 off 方法，可以手动取消监听。
- **emit**：主动触发事件（原生或 H5 都可以发）。
  - 参数：
    - `event` (string) → 事件名。
    - `payload` (any) → 事件数据。
### 3. app
- **core.getStatus**：前后台、省电、VPN状态。  
   - 返回:  `Promise<{code:number, 字典, msg?:string}>`   
   - > ```json
     > {
     >   "foreground": true,       // 是否在前台
     >   "powerSave": false,       // 是否开启省电模式
     >   "vpnEnabled": true,       // 是否检测到 VPN/代理
     >   "networkRestricted": false // 是否有后台网络限制
     > }
     > ```
- **core.openSettings(string?)**：跳系统设置。  
  - 参数：`general/应用详情页（默认）`
- **exit/minimize**：退出应用（一般关闭进程或返回桌面）/最小化应用（进入后台）。
- **update.check/apply**：检查是否有新版本更新。执行更新。

### 4. nav

- **nav.open({url, title?, headers?, animated?, modal?, inExternal?})**：
  - 作用：打开一个新的页面。页面可以是 H5的URL，也可以是 App 内部路由（由原生解析）。
  - 参数：
    - `url` 必填，要打开的页面地址（http/https 或内部 scheme）。
    - `title` 可选，设置新页面标题。
    - `headers` 可选，额外的请求头（用于认证或调试）。
    - `animated` 是否需要过渡动画（默认 true）。
    - `modal` 是否以模态方式打开（覆盖而非压栈）。
    - `inExternal`是否强制用系统浏览器打开（如 Safari/Chrome）。
   - 返回:  一个 `handler` (function)，可以手动取消打开的页面。
- **close({steps?})**：关闭当前页面，返回上一级或指定层级。
  - 功能说明
    - 参数：
    	- `steps` 可选，关闭多少层（默认 1, -1关闭所有打开的页面）。
- **replace({url})**：
  - 作用： 设置当前页面的导航栏标题。
  - 参数：
    - `url` 设置当前页面的导航栏标题。
- **setTitle({title, subtitle?})**：
  - 作用： 设置当前页面的导航栏标题。
  - 参数：
    - `title` 主标题文本。
    - `subtitle` 可选，副标题文本。
- **setBars({hidden?, color?, style?})**：
  - 作用： 控制导航栏、状态栏外观。
  - 参数：
    - `hidden` 是否隐藏导航栏。
    - `color` 背景颜色（16进制或 rgba）。
    - `style` 文字和图标样式（dark | light）。
  - 注意事项: 
    - 跨平台一致性：`iOS 与 Android 导航实现差异较大，SDK 需统一参数。` , `modal 模式在 iOS 更常见，Android 可模拟为全屏。`
    - 外部页面：`inExternal=true` 强制调用系统浏览器，避免和 WebView 混用。
    - 替换页面：`replace` 不会保留返回栈，常用于登录成功后跳首页。



### 5. ui

- **ui.toast({text, duration?})**：
  - 作用： 弹出一个轻量的提示消息，短时间后自动消失。
  - 参数：
    - text：提示文本。
    - duration：持续时间（ms，可选，默认 2000ms）。、

- **ui.alert({title?, message, okText?})**：
  - 作用： 显示一个只有「确认」按钮的系统弹窗。
  - 参数：
    - title：标题，可选。
    - message：提示内容。
    - okText：确认按钮文字，默认「确定」。

- **ui.confirm({title?, message, okText?, cancelText?})**：
  - 作用： 显示带「确认」和「取消」按钮的弹窗。
  - 参数：
    - title：标题，可选。
    - message：提示内容。
    - okText：确认按钮文字，默认「确定」。。
    - cancelText：取消按钮文字，默认「取消」。
  - 返回： `data = { ok: true/false }`

- **ui.actionSheet({title?, items:[{id,text,icon?}]})**：
  - 作用：底部弹出的操作菜单，用户选择一项后返回。
  - 参数：
    - title：标题，可选。
    - items：`[{id:id内容,text:文本,icon:图标?}]`
  - 返回： `data = { id: "选中项的id" }`
- **ui.loading({visible, text?})**：
  - 作用：底部弹出的操作菜单，用户选择一项后返回。
  - 参数：
    - visible：true 显示，false 隐藏。
    - text：可选，提示文字。
  - 返回： `data = function() 可取消loading`
- **ui.haptics({style})**：震动反馈。  
  - 作用：触发系统级震动反馈。
  - 参数：
    - enum(light,medium,heavy)
- **safeArea**：刘海屏/底栏信息。  
  - 作用：返回设备屏幕的安全区域（Safe Area Insets），避免 UI 被刘海、底部手势区遮挡。
  - 返回： 
  - > ```json
    > {
    >   "top": 44,     // 状态栏或刘海高度
    >   "bottom": 34,  // 底部高度
    >   "left": 0,     
    >   "right": 0
    > }
    > ```

### 6. storage

- **storage.get({key})**：
  - 作用：获取指定 key 的值。
  - 返回：{ key, value }，不存在时返回 null。
- **storage.set({key, value, ttlSec:? `默认永不过期`  })**：
  - 作用：设置值，可选传入过期时间（秒）。
  - 返回：true/false。
- **storage.remove({key})**：
  - 作用：设置值，可选传入过期时间（秒）。
  - 返回：true/false。
- **storage.remove({key})**：
  - 作用：设置值，可选传入过期时间（秒）。
  - 返回：true/false。
- **storage.clear({scope?})**：
  - 作用：设置值，可选传入过期时间（秒）。
  - 参数：
    - enum(app: 整个应用 , webview: 当前 WebView)
  - 返回：true/false。

### 7. permission  

- **permission.check(name)**：
  - 作用：检查指定权限的当前状态。
  - 参数：name → 权限名，例如 "camera"。
  - 返回：`data = true/false `
- **permission.request(name)**：
  - 作用：请求系统授权。
  - 参数：name → 权限名，例如 "camera"。
  - 返回：`data = true/false `
- **permission.ensure(name, action)**：
  - 作用：推荐封装模式，确保权限后再执行指定逻辑。
  - 流程：调用 check , 如果未授权 → 调用 request ， 成功 → 执行 action 回调
  - 参数：
    - `name`：`enum(camera,photo,mic,bluetooth,notifications,storage,contacts,sms,phone)`
    - `action`：`要执行的 function()`

### 8. device

- **device.getIds**：设备唯一性标识。  
  - 作用：返回可用于唯一标识设备或安装的 ID，用于登录绑定、整个系统微信识别号
- **device.getInfo**：平台、厂家、型号、系统版本等。  
  - 作用：获取设备的基础信息，包括硬件和系统。
  - 返回：
  - > ```json
    > {
    >   "platform": "iOS",               // 平台类型：iOS/Android/HarmonyOS
    >   "systemType": "iOS",             // 系统类型（方便兼容判断）
    >   "osVersion": "iOS 17.2",         // 系统版本
    >   "manufacturer": "Apple",         // 厂商
    >   "brand": "Apple",                // 品牌
    >   "model": "iPhone14,2",           // 型号代号
    >   "appId": "com.xxx.reader",       // 应用内部 ID
    >   "packageName": "com.xxx.reader", // 包名 / Bundle ID
    >   "appVersion": "12.3.1",          // 应用版本
    >   "buildNumber": "12345",          // 构建号
    >   "sdkInt": null,                  // Android API Level（iOS 为 null）
    >   "screenWidth": 390,              // 逻辑宽度（pt/dp）
    >   "screenHeight": 844,             // 逻辑高度
    >   "pixelRatio": 3,                 // devicePixelRatio
    >   "dpi": 460,                      // 屏幕 DPI
    >   "physicalWidth": 1170,           // 物理像素宽度
    >   "physicalHeight": 2532,          // 物理像素高度
    >   "locale": "zh-CN",               // 语言
    >   "region": "CN",                  // 地区
    >   "timezone": "Asia/Shanghai"      // 时区
    > }
    > ```
- **device.getBattery()**
  - 作用：检查指定权限的当前状态。
  - 返回：
  - > ```json
    > { "level": 0.82, "charging": true, "powerSave": false }
    > ```
- **device.getStorageInfo()**
  - 作用：获取存储空间。
  - 返回：
  - > ```json
    > { "total": 128000, "free": 45600, "unit": "MB" }
    > ```
- **device.getMemoryInfo()**
  - 作用：获取内存使用情况。
  - 返回：
  - > ```json
    > { "total": 8192, "free": 2048, "lowMemory": false, "unit": "MB" }
    > ```
- **device.getCpuInfo()**
  - 作用：获取 CPU 信息。
  - 返回：
  - > ```json
    > { "cores": 8, "arch": "arm64", "frequency": "2.9GHz" }
    > ```

### 9. share / clipboard

- **share.open({text, url, image?, platforms?})**：系统分享。  
  - 作用：调用系统原生的「分享面板」，让用户选择分享目标（微信、QQ、邮件、短信、其他应用）。适合用来分享文章、产品、活动页面等。
  - 参数：
    - text：分享的文本内容。
    - url：分享的链接。
    - image：可选，本地路径或 URL 的图片，用于带图分享。
    - platforms：可选，限制分享平台（如只显示微信/QQ）。
  - 返回：
  - > ```json
    > { "cores": 8, "arch": "arm64", "frequency": "2.9GHz" }
    > ```
- **share.copyLink({url})**：复制链接。  
- **clipboard.get/set**：剪贴板读写。  

### 10. notifications

- **notifications.showLocal({title,body,...})**：
  
  - 作用：在本地设备上展示一个系统级通知（无需服务器推送），常用于提醒用户事件（下载完成、闹钟、任务提醒等）。
  - 参数：
  - > ```json
    > notifications.showLocal({
    >   id?: string,           // 通知唯一 ID，便于后续取消或更新
    >   title: string,         // 通知标题
    >   body: string,          // 通知内容
    >   subtitle?: string,     // 副标题 (iOS 支持)
    >   at?: number,           // 未来触发时间（时间戳，ms），不传则立即显示
    >   sound?: boolean,       // 是否播放提示音
    >   badge?: number,        // 应用图标角标数
    >   payload?: object,      // 自定义数据，点击通知时回传
    >   channelId?: string     // (Android) 通知渠道 ID
    > })
    > ```

### 11. auth / payment
- **auth.getToken()**：
  - 作用：获取当前用户的访问 token。
  - 返回：
  - > ```json
    > { "token": "xxxxxx..." }
    > ```
- **auth.refreshToken()**：
  - 作用：调用原生刷新 token 逻辑。。
  - 返回：
  - > ```json
    > { "token": "xxxxxx..." }
    > ```
- **payment.pay({productId, payType})**：
  - 作用：发起APP内的内购流程。调起 App内部的 支付。
  - 参数：
    - productId：参数id
    - payType：支付类型，wxpay, alipay, usdt, agentPay, bank
  - 返回：
  - > ```json
    > { "orderId": "xxxxxx...", "status": "success"  }
    > ```
  - 注意：sdk应为要求app实现APP内的内购流程和逻辑

### 12. download / apk / cache
- **download.start({url, id?, headers?, saveTo?})**：下载任务。 
  - 作用：开始一个文件下载任务。
  - 参数：
    - url: 下载地址。
    - id: 可选，任务 ID（不传则 SDK 自动生成）。
    - headers: 可选，附加请求头。
    - saveTo: 可选，保存路径（不传则使用默认下载目录）。
  - 返回：
  - > ```json
    > {"id": "task_001","path": "/storage/emulated/0/Download/test.pdf"}
    > ```
- **download.pause({id})**：
  - 作用：暂停指定下载任务。
- **download.resume({id})**：
  - 作用：恢复指定下载任务。
- **download.cancel({id})**：
  - 作用：取消下载任务，已下载的文件删除。
- **download.status({id})**：
  - 作用：获取下载状态。
  - 返回：
  - > ```json
    > {
    >   "id": "task_001",
    >   "progress": 65,
    >   "status": "downloading", // waiting / downloading / paused / completed / failed
    >   "speed": "120KB/s",
    >   "path": "/storage/emulated/0/Download/test.pdf"
    > }
    > ```

- **download.list()**：
  - 作用：获取所有下载任务列表。
- **download.cancel({id})**：
  - 作用：取消下载任务，已下载的文件删除。
- **download.m3u8({url, id?, saveToDir?, tsConcurrency?, headers?})**：
  - 作用：下载并合并m3u8。  
  - 参数：
    - url: 下载地址。
    - id: 可选，任务 ID（不传则 SDK 自动生成）。。
    - tsConcurrency: 可选，分片并发数。
    - headers: 可选，附加请求头。
    - saveTo: 可选，保存路径（不传则使用默认下载目录）。
  - 返回：
  - > ```json
    > {"id": "task_001","path": "/storage/emulated/0/Download/test.pdf"}
    > ```
- **download.getDefaultDir() / setDefaultDir()**：获取/设置默认下载路径。  
- **download.getFilePath({id})**：获取任务文件路径。  
- **apk.download({url, id?, saveToDir?, saveTo?})**：
  - 作用：下载 APK 文件。
  - 参数：
    - url: 下载地址。
    - id: 可选，任务 ID（不传则 SDK 自动生成）。。
    - headers: 可选，附加请求头。
    - saveTo: 可选，保存路径（不传则使用默认下载目录）。
  - 返回：
  - > ```json
    > {"id": "task_001","path": "/storage/emulated/0/Download/test.apk"}
    > ```
- **apk.install({path})**：安装APK。  
  - 作用：调用系统安装器安装 APK
- **apk.open({packageName, scheme?, params?})**：打开指定App。  
  - 作用：打开已安装的 App, Android 可直接用包名，iOS 推荐使用 deeplink.open()
  - 参数：
    - packageName: 包名,
    - scheme?: scheme包名,
    - params?: params
- **apk.isInstalled({packageName})**：检查App是否安装。  
- **cache.getSize**：缓存管理。  
  - 作用：获取应用缓存大小。
  - 返回：
  - > ```json
    > { "size": 12345678, "unit": "bytes" }
    > ```
- **cache.clear({type?})**：  
  - 作用：清理缓存
  - 参数
    - type: enum(all ,images, webview, storage)

### 14. appstore / testflight (iOS only)
- **appstore.open({appId})**：
  - 作用：打开 iOS App Store 指定应用详情页、用户会跳转到 App Store，并显示该应用的详情页、如果用户未安装 App，可以选择下载。
  - 参数：appId：App Store 应用的 ID，例如微信的 414478124。
- **appstore.search({keyword})**：
  - 作用：打开 App Store 搜索页面，显示搜索结果。
  - keyword：搜索关键词。
- **testflight.open({inviteUrl})**：
  - 作用：打开 TestFlight 邀请链接、用户可直接在 TestFlight 中安装测试包、如果设备已安装 TestFlight → 直接跳转到该 App 的测试包页面、如果未安装 TestFlight → 打开 Safari 显示邀请链接，用户可选择安装 TestFlight。
  - 参数：
    - inviteUrl：TF的邀请链接，例如：https://testflight.apple.com/join/xxx

### 15. deeplink 
- **deeplink.open({url})**：
  - 解释：深链是一种特殊的 URL，用来直接唤起 本 App 内部页面 或 第三方 App 的指定页面, 和 apk.open 类似
  - 作用：打开目标 App 的页面，解析外部传入的链接
  - url：字符串，目标 App 定义的 URL Scheme 或 Universal Link。
    - 例如： weixin://scanqrcode, taobao://item?id=12345

### 16. liveActivity
- **liveActivity.start({id, title, progress?})**：
  - 作用：开始一个实况活动。
- **liveActivity.update({id, title?, progress?})**：
  - 作用：更新指定实况活动的显示内容。
- **liveActivity.stop({id})**：
  - 作用：停止并移除一个实况活动。


---

## 注意事项

1. **返回值统一**：所有方法返回 `Promise<{code,data,msg}>`，需判断 `code===0` 成功。  
2. **权限策略**：全部采用动态授权，推荐使用 `permission.ensure`。  
3. **平台差异**：  
   - APK 管理（apk.*）仅 Android 支持。  
   - appstore/testflight 仅 iOS 支持。  
   - m3u8 下载仅 Android 原生支持。  
5. **深链 vs apk.open**：  
   - `deeplink.open` → 打开指定页面/功能（前提是对方 App 支持深链）。  
   - `apk.open` → Android 直接通过包名打开 App 主入口。  
   - 两者互补，不冲突。  



#### 常见权限名（标准化）

| 权限名            | 描述     | 备注                                     |
| ----------------- | -------- | ---------------------------------------- |
| `camera`          | 相机     | iOS/Android 均需系统弹窗                 |
| `photo`           | 相册访问 | iOS 仅在保存/读取时提示                  |
| `mic`             | 麦克风   | 录音/通话场景                            |
| `location`        | 定位     | 可细分精确/粗略定位                      |
| `bluetooth`       | 蓝牙     | 扫描/连接设备                            |
| `nfc`             | NFC      | 读写标签                                 |
| `notifications`   | 通知     | iOS/Android 均需显式授权                 |
| `storage`         | 存储     | Android 高版本需 MANAGE_EXTERNAL_STORAGE |
| `contacts`        | 通讯录   | iOS/Android 需授权                       |
| `sms`             | 短信     | Android 需 READ_SMS，iOS 限制很严        |
| `phone`           | 本机号码 | Android 可用，iOS 基本受限               |
| `biometric`       | 生物识别 | FaceID/TouchID                          |



## 事件清单

#### 视频类（Video Player）

- **`player.ready`** → 播放器初始化完成。
- **`player.play`** → 开始播放。
- **`player.pause`** → 暂停播放。
- **`player.stop`** → 停止播放。
- **`player.seek`** → 跳转进度。
- **`player.buffering`** → 缓冲中。
- **`player.buffered`** → 缓冲完成。
- **`player.ended`** → 播放完成。
- **`player.error`** → 播放失败。
- **`player.fav.add` / `player.fav.remove`** → 收藏/取消收藏。
- **`player.fullscreen.enter` / `player.fullscreen.exit`** → 全屏切换。
- **`player.pip.enter` / `player.pip.exit`** → 画中画模式切换。
- **`player.subtitle.change`** → 字幕切换事件。
- **`player.muted` / `player.unmuted`** → 静音切换。
- **`player.rate.change`** → 播放速度切换。
- **`player.quality.change`** → 清晰度切换。
- **`player.subtitle.change`** → 字幕切换。。
- **`player.comment.new`** → 新评论。

------
#### 小说

- **`book.ready`** → 阅读器初始化完成。
- **`book.fav.add` / `book.fav.remove`** → 收藏/取消收藏。
- **`book.page.change`** → 翻页事件（返回章节 ID + 页码）。
- **`book.progress.update`** → 阅读进度更新。
- **`book.font.change`** → 字体/字号切换。
- **`book.theme.change`** → 主题切换（夜间模式/日间模式）。
- **`book.bookmark.add` / `book.bookmark.remove`** → 书签操作事件。
- **`book.tts.start` / `book.tts.stop`** → 听书朗读开始/结束。
- **`book.error`** → 阅读器错误（资源缺失、渲染异常）。

------
#### 小说/漫画类（Reader）

- **`comics.ready`** → 阅读器初始化完成。
- **`comics.fav.add` / `reader.fav.remove`** → 收藏/取消收藏。
- **`comics.page.change`** → 翻页事件（返回章节 ID + 页码）。
- **`comics.theme.change`** → 主题切换（夜间模式/日间模式）。
- **`comics.bookmark.add` / `reader.bookmark.remove`** → 书签操作事件。
- **`comics.error`** → 阅读器错误（资源缺失、渲染异常）。

------
#### 直播类（Live Streaming）

- **`live.ready`** → 直播初始化完成。
- **`live.start` / `live.stop`** → 直播推流开始/结束（主播端）。
- **`live.play` / `live.pause` / `live.error`** → 直播观看端事件。
- **`live.chat.message`** → 新弹幕/评论。
- **`live.chat.moderation`** → 管理员操作（禁言/踢人）。
- **`live.like`** → 点赞事件。
- **`live.gift.send`** → 送礼物事件。
- **`live.audience.join` / `live.audience.leave`** → 观众进入/退出。
- **`live.connection.change`** → 网络状态变化（弱网、重连）。
- **`live.chat.message`** → 新弹幕消息。
- **`live.like`** → 点赞。
- **`live.gift.send`** → 礼物发送。
- **`live.gift.receive`** → 收到礼物（主播端）。
- **`live.anchor.mute` / `live.anchor.unmute`** → 主播麦克风状态。
- **`live.connection.change`** → 网络状态变更（弱网、重连）。


------
#### 通用事件（跨业务）

- **`app.pause` / `app.resume`** → App 前后台切换。
- **`app.ready`** → App 初始化完成，H5 可以安全调用能力。
- **`app.exit` / `app.minimize`** → 用户退出/最小化。
- **`network.change`** → 网络变化（wifi / 4g / offline）。
- **`theme.change`** → 主题切换（明/暗模式）。
- **`keyboard.show` / `keyboard.hide`** → 输入法弹出/收起。
- **`push.receive` / `push.click`** → 推送相关。
- **`screen.orientation.change`** → 屏幕横竖屏切换。
- **`locale.change`** → 系统语言切换。

------

#### 推送与通知
- **`notifications.click`** → 点击本地通知。

------

#### 下载与文件

- **`download.progress`** → 下载进度更新（返回 taskId、百分比、速度）。
- **`download.completed`** → 下载完成。
- **`download.failed`** → 下载失败。

------

#### 聚合支付

- **`payment.success` / `payment.fail` / `payment.cancel`** → 聚合支付状态。
------



