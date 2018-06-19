//
//  ViewController.swift
//  MQTTDemoForChatting
//
//  Created by Inkswipe on 6/7/18.
//  Copyright © 2018 Fortune4 Technologies. All rights reserved.
//

import UIKit
import Moscapsule
import UserNotifications
class ViewController: UIViewController {


    var mqttClient : MQTTClient!
    
    
    
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Meeting Reminder"
        content.subtitle = "messageSubtitle"
        content.body = "Don't forget to bring coffee."
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
    
    func didReceiveMessage(_ message: MQTTMessage)
    {
         self.sendNotification()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
     //self.sendNotification()
        // set MQTT Client Configuration
        let mqttConfig = MQTTConfig(clientId: "ios", host: "test.mosquitto.org", port: 1883, keepAlive: 60)
        //mqttConfig.mqttAuthOpts = MQTTAuthOpts(username: "username", password: "password")
        
        // create new MQTT Connection
       
        
        
        mqttConfig.onPublishCallback = { messageId in
            NSLog("published (mid=\(messageId))")
        }
        mqttConfig.onMessageCallback = { meaage in
            
            if meaage.topic == "fabit/user/1" {
                print("MQTT Message received: payload=\(String(describing: meaage.payloadString))")
                DispatchQueue.main.sync {
                self.sendNotification()
                self.logTextView.text = meaage.payloadString
                    
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
        mqttClient.publish(string:"Hello CloudAMQP MQTT" , topic: "fabit/coach/1", qos:0, retain: false)
        // publish and subscribe
        mqttClient.subscribe("fabit/user/1", qos: 0)
        
        
       mqttConfig.onSubscribeCallback = { (messageId, grantedQos) in
            print("subscribed (mid=\(messageId),grantedQos=\(grantedQos))")
        }

        
        //mqttClient.disconnect()
        
    }

    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var messageText: UITextField!
    @IBAction func sendBtnAction(_ sender: Any) {
        if messageText.text != ""
        {
            mqttClient.publish(string:messageText.text! , topic: "fabit/coach/1", qos:0, retain: false)
        }
        
    }
    
  


}

