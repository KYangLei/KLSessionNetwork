//
//  operationNSURLSession.swift
//  PanArt
//
//  Created by zsly on 16/3/14.
//  Copyright © 2016年 zsly. All rights reserved.
//

import UIKit

let SCREEN_SCALE = UIScreen.main.scale

@objc protocol HttpMethodPro
{
  @objc optional  func receivedGetData(data:NSData,httpTag:Int,error:String?)
  @objc optional  func receivedGetData(data:NSData,httpTag:Int,callBackInfo:AnyObject!,error:String?)

  @objc optional  func receivedPostData(data:NSData,httpTag:Int,error:String?)
  @objc optional  func receivedPostData(data:NSData,httpTag:Int,callBackInfo:AnyObject!,error:String?)
    
  @objc optional  func receivedPutData(data:NSData,httpTag:Int,error:String?)
  @objc optional  func receivedDeleteData(data:NSData,httpTag:Int,error:String?)
  @objc optional  func receivedError(error:NSError!,httpTag:Int)
  @objc optional func receivedDownloadData(data:NSData,httpTag:Int,error:String?)
}

@objc protocol StatusCodePro {
    func logout(_ isClearPwd:Bool)
}

enum HttpClientType
{
   case k_unknown
   case k_httpDELETE
   case k_httpPut
   case k_httpPost
   case k_httpGet
}

var LocalCookie_KEY = "user_cookie"
var appStore=""
var CookieKey:UnsafeRawPointer?
@available(iOS 10.0, *)
class operationNSURLSession: NSObject {
    
    weak var http_delegate:HttpMethodPro!
    var http_type:HttpClientType!
    var callBackInfo:AnyObject!
    
    init(delegate:HttpMethodPro) {
        super.init()
        http_delegate=delegate
        http_type = .k_unknown
    }
    
    init(delegate:HttpMethodPro,callBackInfo:AnyObject!) {
        super.init()
        http_delegate=delegate
        http_type = .k_unknown
        self.callBackInfo = callBackInfo
    }
    
    func alertMsg(title:String,message:String)
    {
        let block = { () -> Void in
            let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let block={
                (action:UIAlertAction) -> Void in
                controller.dismiss(animated: true, completion: nil)
            }
            let action = UIAlertAction(title: "确定", style: .default, handler: block)
            controller.addAction(action)
            //Operation.getWindowRootViewController()!.presentViewController(controller, animated: true, completion: nil)
        }
        //DispatchQueue.main.asynchronously(execute: block)
        DispatchQueue.main.async(execute: block)
    }
    
    func alertDelegate(actions:UIAlertAction...,title:String,message:String)
    {
        let block = { () -> Void in
            let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
            switch actions.count
            {
            case 1:
                controller.addAction(actions[0])
            case 2:
                controller.addAction(actions[1])
            default:break;
            }
            //Operation.getWindowRootViewController()!.presentViewController(controller, animated: true, completion: nil)
        }
        //dispatch_get_main_queue().asynchronously(execute: block)
        DispatchQueue.main.async(execute: block)
    }
    
    class func getLocalCookie()->String?
    {
        let userCookie = UserDefaults.standard.object(forKey: LocalCookie_KEY) as? String
        return userCookie
    }
    
    func setLocalCookie(cookie:String!)
    {
        UserDefaults.standard.set(cookie, forKey: LocalCookie_KEY)
        UserDefaults.standard.synchronize()
    }
    class func clearLocalCookie()
    {
        UserDefaults.standard.removeObject(forKey: LocalCookie_KEY)
    }
    func setHTTPBody(request:NSMutableURLRequest!,dict:Dictionary<String,String>?)
    {
        if(dict != nil)
        {
         var body="";
         var i=0
         for (key, value) in dict! {
            if(i==0)
            {
                body.append(String(format: "%@=%@", key,self.URLEncodedString(value as NSString)))
            }
            else
            {
                body.append(String(format: "&%@=%@", key,self.URLEncodedString(value as NSString)))

            }
            i += 1
          }
         let data=body.data(using: String.Encoding.utf8)
         request.httpBody=data
        }
    }
    
    func URLEncodedString(_ value:NSString) -> NSString {
//        NSString *self_str=(NSString*)self;
//        NSMutableString *m_str=[NSMutableString string];
//        NSMutableCharacterSet* URLQueryPartAllowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
        let m_str = NSMutableString()
        var URLQueryPartAllowedCharacterSet = CharacterSet.urlQueryAllowed
        URLQueryPartAllowedCharacterSet.remove(charactersIn: "?&=@+/'")
        let maxCount = 100
        let stringLength = value.length
        for i in stride(from: 0, to: stringLength, by: maxCount) {
            let rangeLength = i + maxCount > stringLength ? stringLength - i : maxCount
            let slicedString = value.substring(with: NSMakeRange(i, rangeLength)) as NSString
            m_str.append(slicedString.addingPercentEncoding(withAllowedCharacters: URLQueryPartAllowedCharacterSet)!)
        }
        return m_str
//        [URLQueryPartAllowedCharacterSet removeCharactersInString:@"?&=@+/'"];
//        NSInteger max_count=100;
//        NSInteger stringLength=self_str.length;
//        NSInteger i;
//        for (i=0;i<stringLength;i+=max_count) {
//            NSInteger rangeLength = i + max_count > stringLength ? stringLength - i : max_count;
//            NSString *slicedString=[self_str substringWithRange:NSMakeRange(i, rangeLength)];
//            [m_str appendString:[slicedString stringByAddingPercentEncodingWithAllowedCharacters:URLQueryPartAllowedCharacterSet]];
//        }
//        return m_str;
    }
    
    
    func addHttpHeader(request:NSMutableURLRequest!,http_type:HttpClientType)
    {
        let app_delegate = UIApplication.shared.delegate as! AppDelegate
        var userCookie = objc_getAssociatedObject(app_delegate,&CookieKey) as? String
        if userCookie == nil
        {
            userCookie = operationNSURLSession.getLocalCookie()//内存中没有值,从本地获取
            if userCookie != nil
            {
              objc_setAssociatedObject(app_delegate,&CookieKey,userCookie, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            }
        }
        if (userCookie != nil)
        {
            request.addValue(userCookie!, forHTTPHeaderField:"epdToken")//epdToken Cookie
        }
        let version=Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        request.addValue("iOS", forHTTPHeaderField:"epdDevice")
        request.addValue(version, forHTTPHeaderField:"epdVersion")
        request.addValue("gzip, deflate", forHTTPHeaderField:"Accept-Encoding")
        switch http_type{
        case .k_httpPut:
            fallthrough
        case .k_httpPost:
            fallthrough
        case .k_httpDELETE:
             request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        default: break
            
        }
        
    }
    
    /// 创建PUT请求
    /// - parameter apiStr     :api字符串
    /// - parameter parmsDict  :参数字典
    /// - parameter httpTag    :传入标志位,回调函数返回相应标志位,默认值为0
    func createPUTHttp(apiStr:String,parmsDict:Dictionary<String,String>?,httpTag:Int=0)
    {
       createRequest(http_type: .k_httpPut, url_str: apiStr, parmsDict: parmsDict, httpTag: httpTag)
    }
    
    /// 创建DELETE请求
    /// - parameter apiStr     :api字符串
    /// - parameter parmsDict  :参数字典
    /// - parameter httpTag    :传入标志位,回调函数返回相应标志位,默认值为0
    func createDELETEHttp(apiStr:String,parmsDict:Dictionary<String,String>?,httpTag:Int=0)
    {
         createRequest(http_type: .k_httpDELETE, url_str: apiStr, parmsDict: parmsDict, httpTag: httpTag)
    }
    
    /// 创建POST请求
    /// - parameter apiStr     :api字符串
    /// - parameter parmsDict  :参数字典
    /// - parameter httpTag    :传入标志位,回调函数返回相应标志位,默认值为0
    func createPOSTHttp(apiStr:String,parmsDict:Dictionary<String,String>?,httpTag:Int=0)
    {
         createRequest(http_type: .k_httpPost , url_str: apiStr, parmsDict: parmsDict, httpTag: httpTag)
    }
    
    /// 创建GET请求
    /// - parameter apiStr     :api字符串
    /// - parameter userCookie :用户Cookie值可以为空
    /// - parameter httpTag    :传入标志位,回调函数返回相应标志位,默认值为0
    func createGETHttp(apiStr:String,parmsDict:Dictionary<String,String>?,httpTag:Int=0)
    {
         createRequest(http_type: .k_httpGet, url_str: apiStr, parmsDict: parmsDict, httpTag: httpTag)
    }
    
    private func createRequest(http_type:HttpClientType,url_str:String,parmsDict:Dictionary<String,String>?,httpTag:Int)
    {
        self.http_type = http_type
        let session=URLSession.shared
        var url:NSURL!
        var request:NSMutableURLRequest!
        var HTTPMethod:String?
        var rs_apiStr = url_str
        switch http_type {
           case .k_httpGet:
               HTTPMethod="GET"
               if(parmsDict != nil)
               {
                 var i=0
                 for (key, value) in parmsDict! {
                    if(i==0)
                    {
                       rs_apiStr.append(String(format:"%@=%@",key,self.URLEncodedString(value as NSString)))
                    }
                    else
                    {
                       rs_apiStr.append(String(format:"&%@=%@",self.URLEncodedString(value as NSString)))
                    }
                    i += 1
                 }
               }
               //url=NSURL.init(string: url_str.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!)
               
               url=NSURL.init(string: rs_apiStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
               
               request=NSMutableURLRequest.init(url: url as URL, cachePolicy:.useProtocolCachePolicy, timeoutInterval: 30)
           case .k_httpPost:
               HTTPMethod="POST"
               url=NSURL.init(string: url_str)
               request=NSMutableURLRequest.init(url: url as URL, cachePolicy:.useProtocolCachePolicy, timeoutInterval: 30)
               setHTTPBody(request: request,dict: parmsDict)
           case .k_httpPut:
               HTTPMethod="PUT"
               url=NSURL.init(string: url_str)
               request=NSMutableURLRequest.init(url: url as URL, cachePolicy:.useProtocolCachePolicy, timeoutInterval: 30)
               setHTTPBody(request: request,dict: parmsDict)
           case .k_httpDELETE:
               HTTPMethod="DELETE"
               url=NSURL.init(string: url_str)
               request=NSMutableURLRequest.init(url: url as URL, cachePolicy:.useProtocolCachePolicy, timeoutInterval: 30)
               setHTTPBody(request: request,dict: parmsDict)
           default:
               assert(HTTPMethod != nil, "HTTPMethod cannot be nil")
        }
        request.httpMethod=HTTPMethod!
        addHttpHeader(request: request, http_type: http_type)
        let block={
            (data:Data?,response:URLResponse?,error:Error?) -> () in
             if error != nil
             {
                if self.http_delegate == nil{
                   return
                }
                let obj:AnyObject = self.http_delegate
                if obj.responds(to: #selector(HttpMethodPro.receivedError(error:httpTag:))) {
                    var new_error:NSError!
                    if error!._code == -1001 || error!._code == -1003{
                        let userInfo = [NSLocalizedDescriptionKey:"请检查当前网络是否异常!"]
                        new_error = NSError.init(domain: "NSURLErrorDomain", code: -1001, userInfo: userInfo)
                    }
                    else{
                        new_error = error as NSError!
                    }
                    self.http_delegate.receivedError!(error: new_error, httpTag: httpTag)

                }
             }
             else
             {
                let httpResponse = response as? HTTPURLResponse
                let dict = httpResponse?.allHeaderFields
                let new_cookie = dict!["epdToken"] as? String //Set-Cookie epdToken
                DispatchQueue.main.async {
                    let app_delegate = UIApplication.shared.delegate as! AppDelegate
                    let userCookie = objc_getAssociatedObject(app_delegate,&CookieKey) as? String
                    if  new_cookie != nil && (userCookie == nil || (userCookie != nil && userCookie != new_cookie) )
                    {
                        self.setLocalCookie(cookie: new_cookie!)
                        objc_setAssociatedObject(app_delegate,&CookieKey,new_cookie, .OBJC_ASSOCIATION_COPY_NONATOMIC)
                    }
                    self.handleData(data: data as NSData!, code: (httpResponse?.statusCode)!,httpTag: httpTag)
                }
             }
        }
        let task = session.dataTask(with: request as URLRequest, completionHandler: block)
        task.resume()
    }
    
    func handleData(data:NSData!,code:Int,httpTag:Int)
    {
        var error_str:String?
        switch code{
        
        case 500://"Server_Exception"="服务器异常"
            fallthrough
        case 400:
            fallthrough
        case 404://"Server_Exception"="服务器异常"
            error_str=String(format:"服务器异常(状态码:%d)",code)
        
        case 401:
            error_str="会话超时,请重新登录"
            let appDelegate = UIApplication.shared.delegate!

            if appDelegate.responds(to: #selector(StatusCodePro.logout(_:)))
            {
                let pro = appDelegate as! StatusCodePro
                pro.logout(false)
            }
            else
            {
                alertMsg(title: "错误提示", message: "AppDelegate没有实现logout:方法")
            }
            return
            
//        case 902://new_version "新版本已上线"; // //            break;
            
        case 503:
             error_str = "系统维护中...请稍后再试!"
             alertMsg(title: "提示", message: "系统维护中...请稍后再试!")
        case 903://force_update_version "强制更新";
           let block = {
                (action:UIAlertAction) -> Void in
              //let url=NSURL(string: appStore)
              //UIApplication.shared.openURL(url! as URL)
              //UIApplication.shared.open(url as! URL, options: nil, completionHandler: nil)
           }
           let action = UIAlertAction(title: "现在就去", style: .default, handler: block)
           alertDelegate(actions: action, title: "系统提示", message: "我们进行了很大的修改！去AppStore下载最新版看看吧~")
           error_str = String(format:"来自状态码%d的响应,数据解析错误",code)
           default:break
        }
        responds(data: data,httpTag:httpTag,error_str: error_str)
    }
    
    func responds(data:NSData,httpTag:Int,error_str:String?)
    {
        let type : HttpClientType = http_type;
        if http_delegate != nil
        {
            let obj:AnyObject = http_delegate
            switch type
            {
            case .k_httpGet:
                if self.callBackInfo != nil && obj.responds(to: #selector(HttpMethodPro.receivedGetData(data:httpTag:callBackInfo:error:))) {
                    http_delegate.receivedGetData!(data: data, httpTag: httpTag, callBackInfo:self.callBackInfo, error: error_str)

                }
                else if obj.responds(to: #selector(HttpMethodPro.receivedGetData(data:httpTag:error:))){
                    http_delegate.receivedGetData!(data: data, httpTag: httpTag, error: error_str)
                }
            case .k_httpPost:
                if self.callBackInfo != nil && obj.responds(to: #selector(HttpMethodPro.receivedPostData(data:httpTag:callBackInfo:error:))){
                    http_delegate.receivedPostData!(data: data, httpTag: httpTag, callBackInfo:self.callBackInfo, error: error_str)
                }
                else if obj.responds(to: #selector(HttpMethodPro.receivedPostData(data:httpTag:error:))){
                    http_delegate.receivedPostData!(data: data, httpTag: httpTag, error: error_str)
                }
            case .k_httpPut:
                if obj.responds(to: #selector(HttpMethodPro.receivedPutData(data:httpTag:error:)))
                {
                    http_delegate.receivedPutData!(data: data, httpTag: httpTag, error: error_str)
                }
            case .k_httpDELETE:
                if obj.responds(to: #selector(HttpMethodPro.receivedDeleteData(data:httpTag:error:)))
                {
                    http_delegate.receivedDeleteData!(data: data, httpTag: httpTag, error: error_str)
                }
            case .k_unknown:
                alertMsg(title: "错误提示", message:"未知类型请求,unknown")
            }
        }
    }
    
    class func clearAllCookies()
    {
       operationNSURLSession.clearLocalCookie()
       let cookieStorage = HTTPCookieStorage.shared
       for cookie in cookieStorage.cookies!{
           cookieStorage.deleteCookie(cookie)
       }
       let credentialsStorage = URLCredentialStorage.shared
       let allCredentials=credentialsStorage.allCredentials
       for (key, value) in allCredentials{
           for (_, value2) in value{
              credentialsStorage.remove(value2 as URLCredential, for: key as URLProtectionSpace)
           }
       }
    }
}


