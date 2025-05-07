# DoKit-iOS

> 2025/04/30    Created.

基于 [DoKit](https://github.com/didi/DoKit) 的最新 [commit](https://github.com/didi/DoKit/commit/166a1a92c6fd509f6b0ae3e8dd9993f631b05709) Fork 并自行维护，PR 仅用作指示。



## Intro

DoKit 前身为 DoraemonKit，原为偏重于 iOS 的移动端位本地调试工具，后来往各平台开始扩展，并接入所谓滴滴平台功能。截至 2025 年，注意到

* 仓库废弃：
  * pod 最新版本到 3.1.3，但 iOS 部分实际上只有 3.0.4 版本才能相对正常使用；
  * 大量的 issue 和 PR 无人处理，iOS 的最新提交停留在 2023 年。
* 大厂病：
  * 强推平台功能，Core 中直接放入平台相关代码；
  * 滴滴内部自行维护分支，又将内外网账户管理混为一谈，交叉代码肆无忌惮地向主分支提交。

直到 Xcode16.3 + iOS18，不对入口 UI 修改的话已彻底无法使用，决定自行维护。



## Usage

```ruby
# Podfile
pod 'DoKit/Core', '3.0.4', :configurations => ['Debug']
```

注意，根据 [官方文档](https://guides.cocoapods.org/syntax/podfile.html#pod) 中 ``Build configurations`` 这一小节，pod 的 configurations 不会对依赖项生效，需要手动一一指明。



## Feature



#### Demo 工程修复

* [x] 通过 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 的 yml 配合 Podfile 控制

  > 主要功能的开发和示例主要依赖于 ``DoKit-iOS/iOS/DoraemonKitDemo``，由于 ``.xcodeproj`` 和 ``.xcworkspace`` 会出现大量无意义变更，实践上会将它们从 git 控制中移除，并通过某些配置文件和工具来生成。

* [x] [FBRetainCycleDetector: issue-115](https://github.com/facebook/FBRetainCycleDetector/issues/115)

  > 由于 FBRetainCycleDetector 已失去维护，使用这个临时方案，在 Podfile 内利用 ruby 直接替换某行源码。



#### 平台削除

* [x] 删除 git 历史

* [x] 删除非 iOS 端位相关内容

* [ ] 分离滴滴平台相关代码，单独作为一个 subspec

  > 平台相关代码会引用 GCDWebServer 和 FMDB 依赖用来构建本地服务，一般仓库不仅没必要引入，还容易因为 Podfile 写得不完备导致被带到线上去。



#### 适配：Xcode16.3, iOS18

* [x] 首页崩溃，参考 [PR-1176](https://github.com/didi/DoKit/pull/1176) 



## Fixed

* [x] 功能：UI 结构失效，参考 [issue-1065](https://github.com/didi/DoKit/issues/1065) 的 [评论](https://github.com/didi/DoKit/issues/1065#issuecomment-1765564254)



## TODO

