# KLSessionNetwork

初学Swift 对URLSession进行封装的网络请求。

使用方法：

let op = operationNSURLSession.init(delegate: self)

*  parmsDict 请求参数
*  httpTag 请求标志位 在回调中可根据标志位来对多个请求进行处理

op.createGETHttp(apiStr: "https://httpbin.org/get", parmsDict: nil,httpTag: 1000)

最后只需实现相对应的请求回调即可。
