//
//  ChatVC.swift
//  MQTTDemoForChatting
//
//  Created by Hitendra Bhoir on 19/06/18.
//  Copyright © 2018 Fortune4 Technologies. All rights reserved.
//

import UIKit

class ChatVC: UIViewController,UITextFieldDelegate,UITextViewDelegate
{

    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var chatTable : UITableView!
    
    @IBOutlet weak var sendTextViewBackView : UIView!
    
    @IBOutlet weak var sendTextView : UITextView!
    
    // @IBOutlet weak var sendText : UITextField!
   
    override func viewDidLoad()
    {
        super.viewDidLoad()
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
        
    }
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        sendTextView.resignFirstResponder()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        moveTextField(textView, moveDistance: -256, up: true)
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        moveTextField(textView, moveDistance: -256, up: false)
    }
    func textViewDidChange(_ textView: UITextView) {
        
        let size = textView.contentSize.height
        
        if size < 120
        {
            self.textViewHeight.constant = size
        }
        
    }
    func moveTextField(_ textView: UITextView, moveDistance: Int, up: Bool) {
        let moveDuration = 0.4
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
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row % 2 == 0
        {
            let cell = self.chatTable.dequeueReusableCell(withIdentifier: "ChatVCCellR") as! ChatVCCellR
            cell.backView.layer.cornerRadius = 10
            return cell
        }
        else
        {
            let cell = self.chatTable.dequeueReusableCell(withIdentifier: "ChatVCCellS") as! ChatVCCellS
            cell.backView.layer.cornerRadius = 10
            return cell
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
   
}





class ChatVCCellR: UITableViewCell
{
    @IBOutlet var backView : UIView!

}


class ChatVCCellS: UITableViewCell
{
    @IBOutlet var backView : UIView!
    
}




