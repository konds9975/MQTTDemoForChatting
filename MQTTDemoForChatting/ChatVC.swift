//
//  ChatVC.swift
//  MQTTDemoForChatting
//
//  Created by Hitendra Bhoir on 19/06/18.
//  Copyright © 2018 Fortune4 Technologies. All rights reserved.
//

import UIKit
import Moscapsule
import UserNotifications
class ChatVC: UIViewController,UITextFieldDelegate,UITextViewDelegate
{
    
    var messageList : [MessageInfo] = []
    
    let udidDevice = UIDevice.current.identifierForVendor!.uuidString

    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var chatTable : UITableView!
    @IBOutlet weak var addButton : UIButton!
    @IBOutlet weak var sendButton : UIButton!
    @IBOutlet weak var sendTextViewBackView : UIView!
    
    @IBOutlet weak var sendTextView : UITextView!
    
    var mqttClient : MQTTClient!
   
    func sendNotification(message:String) {
        let content = UNMutableNotificationContent()
        content.title = "Coach"
        //content.subtitle = "messageSubtitle"
        content.body = message
        content.badge = 1
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,
                                                        repeats: false)
        let requestIdentifier = "demoNotification"
        let request = UNNotificationRequest(identifier: requestIdentifier,
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request,
                                               withCompletionHandler: { (error) in
                                                // Handle error
        })
    }
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        //self.sendButton.contentEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        //self.addButton.contentEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        
        
        self.chatTable.delegate = self
        self.chatTable.dataSource = self
        
        self.sendTextViewBackView.layer.cornerRadius = 0
        self.sendTextViewBackView.layer.borderWidth = 1
        self.sendTextViewBackView.layer.borderColor = UIColor.groupTableViewBackground.cgColor
        
        self.sendTextView.layer.cornerRadius = 15
        self.sendTextView.layer.borderWidth = 1
        self.sendTextView.layer.borderColor = UIColor.groupTableViewBackground.cgColor
        self.sendTextView.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        self.mqttSetUp()
        
        self.navigationItem.title = "Coach"
        
        messageList = DBManager.shared.getAllMessages()
        self.chatTable.reloadData()
        if messageList.count != 0
        {
            self.chatTable.scrollToRow(at: IndexPath(row: messageList.count-1, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
        }
        
    }
    
    func mqttSetUp()
    {
        let mqttConfig = MQTTConfig(clientId: "ios", host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        mqttConfig.onPublishCallback = { messageId in
            NSLog("published (mid=\(messageId))")
        }
        mqttConfig.onMessageCallback = { meaage in
            
            if meaage.topic == "fabit/user/1" {
                print("MQTT Message received: payload=\(String(describing: meaage.payloadString))")
                
                //"{\"type\":\"delivery_acknowledgement\",\"message_id\":\"5dfddc52-4731-47b0-9230-9bc8ab16f922\",\"timestamp\":1529471923886}
                
                if let recived = self.convertToDictionary(text:  meaage.payloadString!)
                {
                    if let type = recived["type"] as? String
                    {
                        if type == "delivery_acknowledgement"
                        {
                             DispatchQueue.main.sync {
                                DBManager.shared.updateIsDelivery(messageId: recived["message_id"] as? String, isDelivery: "1",isRead : "0")
                                self.messageList = [MessageInfo]()
                                self.messageList = DBManager.shared.getAllMessages()
                                self.chatTable.reloadData()
                                if self.messageList.count != 0
                                {
                                    self.chatTable.scrollToRow(at: IndexPath(row: self.messageList.count-1, section: 0), at: UITableViewScrollPosition.bottom, animated: false)
                                }
                                
                            }
                            print("Message delivered to couch : delivery_acknowledgement")
                        }
                        else if type == "read_receipt"
                        {
                             DispatchQueue.main.sync {
                             DBManager.shared.updateIsDelivery(messageId: recived["message_id"] as? String, isDelivery: "1",isRead : "1")
                                self.messageList = [MessageInfo]()
                                self.messageList = DBManager.shared.getAllMessages()
                                self.chatTable.reloadData()
                                if self.messageList.count != 0
                                {
                                    self.chatTable.scrollToRow(at: IndexPath(row: self.messageList.count-1, section: 0), at: UITableViewScrollPosition.bottom, animated: false)
                                }
                            }
                            print("Message read by couch : read_receipt")
                        }
                        else if type == "text"
                        {
                            
                            if let message_id = recived["message_id"] as? String
                            {
                                DispatchQueue.main.sync {
                                self.messageDeliverd(message_id: message_id)
                                self.messageRead(message_id: message_id)
                                self.sendNotification(message:recived["value"] as? String ?? "")
                                let temp = MessageInfo()
                               temp.initData(type: recived["type"] as? String, value: recived["value"] as? String, user_id: recived["user_id"] as? String, coach_id: recived["coach_id"] as? String, sent_by: String(recived["sent_by"] as? Int ?? 0), message_id: recived["message_id"] as? String, is_delivered: recived["is_delivered"] as? String, delivered_on:recived["delivered_on"] as? String , is_read: recived["is_read"] as? String, read_on: recived["read_on"] as? String, date: Date())
                                DBManager.shared.insertModelInDataBase(messageInfo: [temp])
                                    
                                self.messageList = [MessageInfo]()
                                self.messageList = DBManager.shared.getAllMessages()
                                self.chatTable.reloadData()
                                    if self.messageList.count != 0
                                    {
                                        self.chatTable.scrollToRow(at: IndexPath(row: self.messageList.count-1, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
                                    }
                                }
                            }
                            
                            
                            print("Message send by couch : text")
                            
                            
                        }
                        else if type == "image"
                        {
                            
                            if let message_id = recived["message_id"] as? String
                            {
                                DispatchQueue.main.sync {
                                    self.messageDeliverd(message_id: message_id)
                                    self.messageRead(message_id: message_id)
                                    self.sendNotification(message:recived["value"] as? String ?? "")
                                    let temp = MessageInfo()
                                    temp.initData(type: recived["type"] as? String, value: recived["value"] as? String, user_id: recived["user_id"] as? String, coach_id: recived["coach_id"] as? String, sent_by: String(recived["sent_by"] as? Int ?? 0), message_id: recived["message_id"] as? String, is_delivered: recived["is_delivered"] as? String, delivered_on:recived["delivered_on"] as? String , is_read: recived["is_read"] as? String, read_on: recived["read_on"] as? String, date: Date())
                                    DBManager.shared.insertModelInDataBase(messageInfo: [temp])
                                    
                                    self.messageList = [MessageInfo]()
                                    self.messageList = DBManager.shared.getAllMessages()
                                    self.chatTable.reloadData()
                                    if self.messageList.count != 0
                                    {
                                        self.chatTable.scrollToRow(at: IndexPath(row: self.messageList.count-1, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
                                    }
                                }
                            }
                            
                            
                            print("Message send by couch : text")
                            
                        }
                        else if type == "typing_start"
                        {
                            print("Message typing_end : typing_start")
                            DispatchQueue.main.sync {
                                self.navigationItem.title = "Coach is typing..."
                                
                            }
                            
                        }
                        else if type == "typing_end"
                        {
                            print("Message typing_end : typing_end")
                            DispatchQueue.main.sync {
                                 self.navigationItem.title = "Coach"
                                
                            }
                        }
                        
                    }
                   
                }
                
                
                DispatchQueue.main.sync {
                 
                    
                }
            }
            else
            {
                print("MQTT Message received: payload=\(String(describing: meaage.payloadString))")
            }
            
        }
        mqttConfig.onConnectCallback = { returnCode in
            if returnCode == ReturnCode.success {
                print("Sucesss Connect")
                
            }
            else {
                print("fail to Connect")
            }
        }
        mqttConfig.onDisconnectCallback = { reasonCode in
            if reasonCode == ReasonCode.disconnect_requested {
                print("Sucesss disConnect")
            } else  {
                print("fail to disConnect")
                
            }
        }
        mqttClient = MQTT.newConnection(mqttConfig)
        //mqttClient.publish(string:"Hello CloudAMQP MQTT" , topic: "fabit/coach/1", qos:0, retain: false)
        // publish and subscribe
        mqttClient.subscribe("fabit/user/1", qos: 0)
        mqttConfig.onSubscribeCallback = { (messageId, grantedQos) in
            print("subscribed (mid=\(messageId),grantedQos=\(grantedQos))")
        }

    }
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    @IBAction func sendBtnAction(_ sender: Any) {
        if sendTextView.text != ""
        {
            
            //{"type":"text","value":"The God of IOS RAm","user_id":"1","coach_id":"1","sent_by":1,"message_id":"5dfddc52-4731-47b0-9230-9bc8ab16f922","is_delivered":0,"delivered_on":"","is_read":0,"read_on":""}
         
            let payload = ["type":"text","value":sendTextView.text!,"user_id":"1","coach_id":"1","sent_by":"2","message_id":udidDevice+"\(Date())","is_delivered":"0","delivered_on":"","is_read":"0","read_on":""]
            
            let temp = MessageInfo()
            

            temp.initData(type: payload["type"], value: payload["value"], user_id: payload["user_id"], coach_id: payload["coach_id"], sent_by: payload["sent_by"], message_id: payload["message_id"], is_delivered: payload["is_delivered"], delivered_on:payload["delivered_on"], is_read: payload["is_read"], read_on: payload["read_on"], date: Date())
            DBManager.shared.insertModelInDataBase(messageInfo: [temp])
            self.sendMessage(messageInfo: payload)
            
            self.sendTextView.text = ""
            let size = sendTextView.contentSize.height
            self.textViewHeight.constant = size
           // self.sendTextView.resignFirstResponder()
            
            messageList = [MessageInfo]()
            messageList = DBManager.shared.getAllMessages()
            self.chatTable.reloadData()
            if messageList.count != 0
            {
                self.chatTable.scrollToRow(at: IndexPath(row: messageList.count-1, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
            }
            
        }
        
    }
    
    @IBAction func sendImageBtnAction(_ sender: Any) {
        
            
            let payload = ["type":"image","value":"","user_id":"1","coach_id":"1","sent_by":"2","message_id":udidDevice+"\(Date())","is_delivered":"0","delivered_on":"","is_read":"0","read_on":""]
            
            let temp = MessageInfo()
            
            
            temp.initData(type: payload["type"], value: payload["value"], user_id: payload["user_id"], coach_id: payload["coach_id"], sent_by: payload["sent_by"], message_id: payload["message_id"], is_delivered: payload["is_delivered"], delivered_on:payload["delivered_on"], is_read: payload["is_read"], read_on: payload["read_on"], date: Date())
            DBManager.shared.insertModelInDataBase(messageInfo: [temp])
            self.sendMessage(messageInfo: payload)
            
            messageList = [MessageInfo]()
            messageList = DBManager.shared.getAllMessages()
            self.chatTable.reloadData()
            if messageList.count != 0
            {
                self.chatTable.scrollToRow(at: IndexPath(row: messageList.count-1, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
            }
       
    }
    
    func messageTypingStart()
    {
       
        let typingStartPayload = ["type":"typing_start"] as [String : Any]
        self.sendMessage(messageInfo: typingStartPayload)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: {
            self.messageTypingEnd()
        })
        
        
    }
    func messageTypingEnd()
    {
        
        let typingEndPayload = ["type":"typing_end"] as [String : Any]
        self.sendMessage(messageInfo: typingEndPayload)
        
    }
    
    func messageDeliverd(message_id:String!)
    {
        let timestamp = NSDate().timeIntervalSince1970
        let deliveredPayload = ["type":"delivery_acknowledgement","message_id":message_id,"timestamp":timestamp] as [String : Any]
        self.sendMessage(messageInfo: deliveredPayload)
       
    }
    func messageRead(message_id:String!)
    {
        let timestamp = NSDate().timeIntervalSince1970
        let readPayload = ["type":"read_receipt","message_id":message_id,"timestamp":timestamp] as [String : Any]
        self.sendMessage(messageInfo: readPayload)
        
    }
    func sendMessage(messageInfo : Dictionary<String, Any>)  {
        
        
        if let theJSONData = try?  JSONSerialization.data(
            withJSONObject: messageInfo,
            options: .prettyPrinted
            ),
            let theJSONText = String(data: theJSONData,
                                     encoding: String.Encoding.ascii) {
            print("JSON string = \n\(theJSONText)")
            mqttClient.publish(string:theJSONText , topic: "fabit/coach/1", qos:0, retain: false)
            
            
            
            
        }
    }
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        sendTextView.resignFirstResponder()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        moveTextField(textView, moveDistance: -256, up: true)
        self.messageTypingStart()
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        moveTextField(textView, moveDistance: -256, up: false)
        self.messageTypingEnd()
    }
    func textViewDidChange(_ textView: UITextView) {
        
        self.messageTypingStart()
        let size = textView.contentSize.height
        if size < 120
        {
            self.textViewHeight.constant = size
        }
        
    }
    func moveTextField(_ textView: UITextView, moveDistance: Int, up: Bool) {
        let moveDuration = 0.2
        let movement: CGFloat = CGFloat(up ? moveDistance : -moveDistance)
        UIView.beginAnimations("animateTextView", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(moveDuration)
        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
        UIView.commitAnimations()
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
      
        
    }
    
}

extension ChatVC : UITableViewDelegate,UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        
        let temp = messageList[indexPath.row]
        if temp.type == "image"
        {
            if temp.sent_by == "2"
            {
                
                let cell = self.chatTable.dequeueReusableCell(withIdentifier: "ChatVCCellImageS") as! ChatVCCellImageS
                cell.backView.layer.cornerRadius = 10
                let url = URL(string:
                    temp.value)
                if url != nil
                {
                    let task = URLSession.shared.dataTask(with: url!) { data, response, error in
                        guard let data = data, error == nil else { return }
                        
                        DispatchQueue.main.async() {    // execute on main thread
                            cell.imageView1.image = UIImage(data: data)
                            if let image = UIImage(data: data) {
                                let ratio = image.size.width / image.size.height
                                if cell.backView.frame.width > cell.backView.frame.height {
                                    let newHeight = cell.backView.frame.width / ratio
                                    //cell.imageView1.frame.size = CGSize(width: cell.backView.frame.width, height: newHeight)
                                    cell.height.constant = newHeight
                                    cell.width.constant = cell.backView.frame.width
                                }
                                else{
                                    let newWidth = cell.backView.frame.height * ratio
                                    //cell.imageView1.frame.size = CGSize(width: newWidth, height: cell.backView.frame.height)
                                    cell.height.constant = newWidth
                                    cell.width.constant = cell.backView.frame.width
                                }
                            }
                        }
                    }
                    task.resume()
                }
                let dateVar = temp.date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm a"
                print(dateFormatter.string(from: dateVar!))
                cell.timeLbl.text = dateFormatter.string(from: dateVar!)

                if temp.is_delivered == "0"
                {
                    cell.tickImage.image = #imageLiteral(resourceName: "clock")
                }
                else if temp.is_delivered == "1"
                {
                    cell.tickImage.image = #imageLiteral(resourceName: "check_1")
                }

                if temp.is_read == "1"
                {
                    cell.tickImage.image = #imageLiteral(resourceName: "check_2")
                }
                cell.bubbleView.layer.cornerRadius = 10
                cell.layoutIfNeeded()
                return cell
                
            }
            else if temp.sent_by == "1"
            {
                let cell = self.chatTable.dequeueReusableCell(withIdentifier: "ChatVCCellImageR") as! ChatVCCellImageR
                cell.backView.layer.cornerRadius = 10
                let url = URL(string:
                    temp.value)
                if url != nil
                {
                    let task = URLSession.shared.dataTask(with: url!) { data, response, error in
                        guard let data = data, error == nil else { return }
                        
                        DispatchQueue.main.async() {    // execute on main thread
                            cell.imageView1.image = UIImage(data: data)
                            if let image = UIImage(data: data) {
                                let ratio = image.size.width / image.size.height
                                if cell.backView.frame.width > cell.backView.frame.height {
                                    let newHeight = cell.backView.frame.width / ratio
                                    //cell.imageView1.frame.size = CGSize(width: cell.backView.frame.width, height: newHeight)
                                    
                                    if newHeight<300
                                    {
                                        cell.height.constant = newHeight
                                        cell.width.constant = cell.backView.frame.width
                                    }
                                    else
                                    {
                                        cell.height.constant = newHeight/2
                                        cell.width.constant = cell.backView.frame.width/2
                                    }
                                    
                                }
                                else{
                                    let newWidth = cell.backView.frame.height * ratio
                                    //cell.imageView1.frame.size = CGSize(width: newWidth, height: cell.backView.frame.height)
                                    if newWidth<300
                                    {
                                        cell.width.constant = newWidth
                                        cell.height.constant = cell.backView.frame.height
                                    }
                                    else
                                    {
                                        cell.width.constant = newWidth/2
                                        cell.height.constant = cell.backView.frame.height/2
                                    }
                                }
                            }
                        }
                    }
                    task.resume()
                }
                let dateVar = temp.date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm a"
                print(dateFormatter.string(from: dateVar!))
                cell.timeLbl.text = dateFormatter.string(from: dateVar!)
                cell.bubbleView.layer.cornerRadius = 10
                cell.layoutIfNeeded()
                return cell
            }
            else
            {
                let cell = self.chatTable.dequeueReusableCell(withIdentifier: "ChatVCCellR") as! ChatVCCellR
                cell.backView.layer.cornerRadius = 10
                cell.messageLbl.text = "Message not send"
                cell.bubbleView.layer.cornerRadius = 10
                cell.layoutIfNeeded()
                return cell
            }
        }
        else
        {
        
            if temp.sent_by == "2"
            {
           
               let cell = self.chatTable.dequeueReusableCell(withIdentifier: "ChatVCCellS") as! ChatVCCellS
                    cell.backView.layer.cornerRadius = 10
                cell.messageLbl.text = temp.value
                let dateVar = temp.date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm a"
                print(dateFormatter.string(from: dateVar!))
                cell.timeLbl.text = dateFormatter.string(from: dateVar!)
                
                if temp.is_delivered == "0"
                {
                     cell.tickImage.image = #imageLiteral(resourceName: "clock")
                }
                else if temp.is_delivered == "1"
                {
                    cell.tickImage.image = #imageLiteral(resourceName: "check_1")
                }
                
                if temp.is_read == "1"
                {
                    cell.tickImage.image = #imageLiteral(resourceName: "check_2")
                }
                cell.bubbleView.layer.cornerRadius = 10
                cell.layoutIfNeeded()
                return cell
                
            }
            else if temp.sent_by == "1"
            {
                let cell = self.chatTable.dequeueReusableCell(withIdentifier: "ChatVCCellR") as! ChatVCCellR
                cell.backView.layer.cornerRadius = 10
                cell.messageLbl.text = temp.value
                let dateVar = temp.date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm a"
                print(dateFormatter.string(from: dateVar!))
                cell.timeLbl.text = dateFormatter.string(from: dateVar!)
                cell.bubbleView.layer.cornerRadius = 10
                cell.layoutIfNeeded()
                return cell
            }
            else
            {
                let cell = self.chatTable.dequeueReusableCell(withIdentifier: "ChatVCCellR") as! ChatVCCellR
                cell.backView.layer.cornerRadius = 10
                cell.messageLbl.text = "Message not send"
                cell.bubbleView.layer.cornerRadius = 10
                cell.layoutIfNeeded()
                return cell
            }
        
        }
        
       
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
   
}

class ChatVCCellImageR: UITableViewCell
{
    @IBOutlet var backView : UIView!
    @IBOutlet var timeLbl : UILabel!
    @IBOutlet var bubbleView : UIView!
    
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var width: NSLayoutConstraint!
    @IBOutlet weak var height: NSLayoutConstraint!
}

class ChatVCCellImageS: UITableViewCell
{
    @IBOutlet weak var width: NSLayoutConstraint!
    @IBOutlet weak var height: NSLayoutConstraint!
    @IBOutlet weak var tickImage: UIImageView!
    @IBOutlet var backView : UIView!
    
    @IBOutlet weak var imageView1: UIImageView!
    
    @IBOutlet var timeLbl : UILabel!
    @IBOutlet var bubbleView : UIView!
    
}




class ChatVCCellR: UITableViewCell
{
    @IBOutlet var backView : UIView!
    @IBOutlet var messageLbl : UILabel!
    @IBOutlet var timeLbl : UILabel!
    @IBOutlet var bubbleView : UIView!

}


class ChatVCCellS: UITableViewCell
{
    @IBOutlet var backView : UIView!
    @IBOutlet var messageLbl : UILabel!
    @IBOutlet var timeLbl : UILabel!
    @IBOutlet var tickImage : UIImageView!
    @IBOutlet var bubbleView : UIView!
    
}


extension UIButton {
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let relativeFrame = self.bounds
        let hitTestEdgeInsets = UIEdgeInsetsMake(-44, -44, -44, -44)
        let hitFrame = UIEdgeInsetsInsetRect(relativeFrame, hitTestEdgeInsets)
        return hitFrame.contains(point)
    }
}


