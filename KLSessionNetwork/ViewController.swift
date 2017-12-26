//
//  ViewController.swift
//  KLSessionNetwork
//
//  Created by 雷珂阳 on 2017/12/26.
//  Copyright © 2017年 雷珂阳. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
class ViewController: UIViewController,HttpMethodPro {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
       
        let op = operationNSURLSession.init(delegate: self)
        
        /* GET  */
        /*
        *  parmsDict 请求参数
        *  httpTag 请求标志位 在回调中可根据标志位来对多个请求进行处理
         */
        op.createGETHttp(apiStr: "https://httpbin.org/get", parmsDict: nil,httpTag: 1000)
        
        /* POSTT  */
//        op.createPOSTHttp(apiStr: "https://httpbin.org/post", parmsDict: nil,httpTag: 1000)
        
        /* PUT  */
//        op.createPUTHttp(apiStr: "https://httpbin.org/put", parmsDict: nil,httpTag: 1000)
        
        /* DELETE  */
//        op.createDELETEHttp(apiStr: "https://httpbin.org/delete", parmsDict: nil,httpTag: 1000)
    }
    
    func receivedGetData(data: NSData, httpTag: Int, error: String?) {
        if (error != nil) {
            // 请求错误
            print(error!)
        }
        do {
            let json=try JSONSerialization.jsonObject(with: data as Data, options: .mutableLeaves)
            print(json)
        } catch {
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

