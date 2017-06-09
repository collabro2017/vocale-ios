//
//  EmailManager.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 8/1/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import Foundation

class EmailManager  {
    static let sharedInstance = EmailManager()
    
    func sendMail(from: String, to: String, subject: String, message: String) {
        let body = "to=\(to)&from=\(from)&subject=\(subject)&message=\(message)"
        
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfiguration)
        let url = NSURL(string: "http://yanev.co/send.php")
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)
        request.HTTPMethod = "POST";
        let postDataTask = session .dataTaskWithRequest(request) { (data, response, error) in
            print("error: \(error)")
        }
        
        postDataTask.resume()
    }
}


