//
//  SocketIOManager.swift
//  SocketChat
//
//  Created by Abdelrahman-Arw on 9/19/19.
//  Copyright © 2019 AppCoda. All rights reserved.
//

import Foundation
import SocketIO

class SocketIOManager: NSObject {
    static let sharedInstance = SocketIOManager()

    
    
   // let socket = SocketManager(socketURL: URL(string: "http://10.2.70.38:3000")!, config: [.log(true), .compress, .reconnects(true)]).defaultSocket
    
    var socket = SocketIOClient(socketURL: URL(string: "http://10.191.0.68:3000")!, config: [.log(true), .forcePolling(true)])
    //let socket = manager.defaultSocket

    
  //  let s = SocketIOClient(manager: <#T##SocketManagerSpec#>, nsp: <#T##String#>)
    override init() {
        super.init()
        establishConnection()
        socket.on("test") { dataArray, ack in
            print(dataArray[0])
            
            
            
        }
        print(socket.status.rawValue)
    }
    
    
    
    
    func sendMessage(message: String, withNickname nickname: String) {
        socket.emit("chatMessage", nickname, message)
    }
    
    
    func getChatMessage(completionHandler: @escaping (_ messageInfo: [String: AnyObject]) -> Void) {
        socket.on("newChatMessage") { (dataArray, socketAck) -> Void in
            var messageDictionary = [String: AnyObject]()
            messageDictionary["nickname"] = dataArray[0] as! String as AnyObject
            messageDictionary["message"] = dataArray[1] as! String as AnyObject
            messageDictionary["date"] = dataArray[2] as! String as AnyObject
            
            completionHandler(messageDictionary)
        }
    }
   
    func exitChatWithNickname(nickname: String, completionHandler: () -> Void) {
        socket.emit("exitUser", nickname)
        completionHandler()
    }
    
    
    func establishConnection() {
        socket.connect()
    }
    
    func closeConnection() {
        socket.disconnect()
    }
    
    
    
 
    func connectToServerWithNickname(nickname: String, completionHandler: @escaping (_ userList: [[String: AnyObject]]?) -> Void) {
        socket.emit("connectUser", nickname)
        
        socket.on("userList") { ( dataArray, ack) -> Void in
            completionHandler(dataArray[0] as? [[String: AnyObject]])
        }
        listenForOtherMessages()

        
    }
    
   
    private func listenForOtherMessages() {
        socket.on("userConnectUpdate") { (dataArray, socketAck) -> Void in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userWasConnectedNotification"), object: dataArray[0] as! [String: AnyObject])
        }
        
       /* socket.on("userExitUpdate") { (dataArray, socketAck) -> Void in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userWasDisconnectedNotification"), object: dataArray[0] as! String)
        }*/
        
        socket.on("userTypingUpdate") { (dataArray, socketAck) -> Void in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userTypingNotification"), object: dataArray[0] as? [String: AnyObject])
        }
        
    }
    
    func sendStartTypingMessage(nickname: String) {
        socket.emit("startType", nickname)
    }
    
    func sendStopTypingMessage(nickname: String) {
        socket.emit("stopType", nickname)
    }
    
}
