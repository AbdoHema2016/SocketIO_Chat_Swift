//
//  ChatViewController.swift
//  SocketChat
//
//  Created by Gabriel Theodoropoulos on 1/31/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "idCellChat", for: indexPath) as! ChatCell
        
        let currentChatMessage = chatMessages[indexPath.row]
        let senderNickname = currentChatMessage["nickname"] as! String
        let message = currentChatMessage["message"] as! String
        let messageDate = currentChatMessage["date"] as! String
        
        if senderNickname == nickname {
            cell.lblChatMessage.textAlignment = NSTextAlignment.right
            cell.lblMessageDetails.textAlignment = NSTextAlignment.right
            
            cell.lblChatMessage.textColor = lblNewsBanner.backgroundColor
        }
        
        cell.lblChatMessage.text = message
        cell.lblMessageDetails.text = "by \(senderNickname.uppercased) @ \(messageDate)"
        
        cell.lblChatMessage.textColor = UIColor.darkGray
        
        return cell
    }
    

    @IBOutlet weak var tblChat: UITableView!
    
    @IBOutlet weak var lblOtherUserActivityStatus: UILabel!
    
    @IBOutlet weak var tvMessageEditor: UITextView!
    
    @IBOutlet weak var conBottomEditor: NSLayoutConstraint!
    
    @IBOutlet weak var lblNewsBanner: UILabel!
    
    
    
    var nickname: String!
    
    var chatMessages = [[String: AnyObject]]()
    
    var bannerLabelTimer: Timer!
    @objc func handleCallStatusUpdateNotification(_ notification: Notification) {
       
    }
   
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.handleCallStatusUpdateNotification(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        
       
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.handleKeyboardDidHideNotification(_:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        swipeGestureRecognizer.direction = UISwipeGestureRecognizer.Direction.down
        swipeGestureRecognizer.delegate = self
        view.addGestureRecognizer(swipeGestureRecognizer)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.handleConnectedUserUpdateNotification(_:)), name: NSNotification.Name(rawValue: "userWasConnectedNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.handleDisconnectedUserUpdateNotification(_:)), name: NSNotification.Name(rawValue: "userWasDisconnectedNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.handleUserTypingNotification(_:)), name: NSNotification.Name(rawValue: "userTypingNotification"), object: nil)

        
        
        
    }
    
  
    @objc func handleConnectedUserUpdateNotification(_ notification: Notification) {
        let connectedUserInfo = notification.object as! [String: AnyObject]
        let connectedUserNickname = connectedUserInfo["nickname"] as? String
        lblNewsBanner.text = "User \(connectedUserNickname!.uppercased) was just connected."
        showBannerLabelAnimated()
    }
    
    @objc func handleDisconnectedUserUpdateNotification(_ notification: Notification) {
        let disconnectedUserNickname = notification.object as! String
        lblNewsBanner.text = "User \(disconnectedUserNickname.uppercased) has left."
        showBannerLabelAnimated()
    }

     @objc func handleUserTypingNotification(_ notification: Notification) {
    
        if let typingUsersDictionary = notification.object as? [String: AnyObject] {
            var names = ""
            var totalTypingUsers = 0
            for (typingUser, _) in typingUsersDictionary {
                if typingUser != nickname {
                    names = (names == "") ? typingUser : "\(names), \(typingUser)"
                    totalTypingUsers += 1
                }
            }
            
            if totalTypingUsers > 0 {
                let verb = (totalTypingUsers == 1) ? "is" : "are"
                
                lblOtherUserActivityStatus.text = "\(names) \(verb) now typing a message..."
                lblOtherUserActivityStatus.isHidden = false
            }
            else {
                lblOtherUserActivityStatus.isHidden = true
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureTableView()
        configureNewsBannerLabel()
        configureOtherUserActivityLabel()
        
        tvMessageEditor.delegate = self
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        SocketIOManager.sharedInstance.getChatMessage { (messageInfo) -> Void in
               DispatchQueue.global(qos: .userInitiated).async {
                self.chatMessages.append(messageInfo)
                self.tblChat.reloadData()
            }
           
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    // MARK: IBAction Methods
    
    @IBAction func sendMessage(_ sender: Any) {
        
        if tvMessageEditor.text.characters.count > 0 {
            SocketIOManager.sharedInstance.sendMessage(message: tvMessageEditor.text!, withNickname: nickname)
            tvMessageEditor.text = ""
            tvMessageEditor.resignFirstResponder()
        }
    }
    

    
    // MARK: Custom Methods
    
    func configureTableView() {
        tblChat.delegate = self
        tblChat.dataSource = self
        tblChat.register(UINib(nibName: "ChatCell", bundle: nil), forCellReuseIdentifier: "idCellChat")
        tblChat.estimatedRowHeight = 90.0
       tblChat.rowHeight = UITableViewAutomaticDimension
        tblChat.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    
    func configureNewsBannerLabel() {
        lblNewsBanner.layer.cornerRadius = 15.0
        lblNewsBanner.clipsToBounds = true
        lblNewsBanner.alpha = 0.0
    }
    
    
    func configureOtherUserActivityLabel() {
        lblOtherUserActivityStatus.isHidden = true
        lblOtherUserActivityStatus.text = ""
    }
    
    func handleKeyboardDidShowNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            if let keyboardFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                conBottomEditor.constant = keyboardFrame.size.height
                view.layoutIfNeeded()
            }
        }
    }
   
    
    
    @objc func handleKeyboardDidHideNotification(_ notification: Notification) {
        conBottomEditor.constant = 0
        view.layoutIfNeeded()
    }
    
    
    func scrollToBottom() {
        _ = 0.1 * Double(NSEC_PER_SEC)
        /*
        dispatch_after(dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), Int64(delay)), dispatch_get_main_queue()) { () -> Void in
            if self.chatMessages.count > 0 {
                let lastRowIndexPath = NSIndexPath(forRow: self.chatMessages.count - 1, inSection: 0)
                self.tblChat.scrollToRowAtIndexPath(lastRowIndexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            }
        }
 */
    }
    
    
    func showBannerLabelAnimated() {
        UIView.animate(withDuration: 0.75, animations: { () -> Void in
            self.lblNewsBanner.alpha = 1.0
            
            }) { (finished) -> Void in
                self.bannerLabelTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(ChatViewController.hideBannerLabel), userInfo: nil, repeats: false)
        }
    }
    
    
    func hideBannerLabel() {
        if bannerLabelTimer != nil {
            bannerLabelTimer.invalidate()
            bannerLabelTimer = nil
        }
        
        UIView.animate(withDuration: 0.75, animations: { () -> Void in
            self.lblNewsBanner.alpha = 0.0
            
            }) { (finished) -> Void in
        }
    }

   
    
    func dismissKeyboard() {
        
        //if tvMessageEditor.isFirstResponder() {
            tvMessageEditor.resignFirstResponder()
            
            SocketIOManager.sharedInstance.sendStopTypingMessage(nickname: nickname)
       // }
     
    }
    
    
    
    // MARK: UITableView Delegate and Datasource Methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages.count
    }
    
 
    
    
    // MARK: UITextViewDelegate Methods
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        SocketIOManager.sharedInstance.sendStartTypingMessage(nickname: nickname)

        return true
    }

    
    // MARK: UIGestureRecognizerDelegate Methods
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
