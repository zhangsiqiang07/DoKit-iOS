# DoKit-iOS

> 2025/04/30    Created.

基于 [DoKit](https://github.com/didi/DoKit) 的最新 [commit](https://github.com/didi/DoKit/commit/166a1a92c6fd509f6b0ae3e8dd9993f631b05709) Fork 并自行维护，并无 PR 计划。



## WHY?

DoKit 前身为 DoraemonKit，原为偏重于 iOS 的移动端位本地调试工具，后来往各平台开始扩展，并接入所谓滴滴平台功能。截至 2025 年，注意到

* 仓库废弃：
  * pod 最新版本到 3.1.3，但 iOS 部分实际上只有 3.0.4 版本才能相对正常使用；
  * 大量的 issue 和 PR 无人处理，iOS 的最新提交停留在 2023 年。
* 大厂漏阴癖：
  * 强推平台功能，Core 中直接放入平台相关代码；
  * 滴滴内部自行维护分支，又将内外网账户管理混为一谈，交叉代码肆无忌惮地向主分支提交。

直到 Xcode16.3 + iOS18，不对入口 UI 修改的话已彻底无法使用，决定自行维护。



## HOW?

* 删除 iOS 外其他平台代码
* 基于 Xcode16.3, iOS18 进行适配
* 



## TODO

