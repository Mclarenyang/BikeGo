//
//  ArticleDetailViewController.swift
//  BikeDemo
//
//  Created by 杨键 on 2018/4/9.
//  Copyright © 2018年 mclarenYang. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ArticleDetailViewController: UIViewController {
    
    var article: Article!{
        didSet{
            netGetComment()
        }
    }
    
    var commentes: [Comment] = [Comment]()
    
    var cellHeight: CGFloat = 0.0
    var commentCellHeigt: CGFloat = 0.0
    var textFieldHeight: CGFloat = 0.0
    
    @IBOutlet weak var TableView: UITableView!
   // @IBOutlet weak var CommentTF: UITextField!
    
    var CommentTF = UITextField()
    
    
    @IBAction func BackBtnClick(_ sender: Any) {
        hero.dismissViewController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hero.isEnabled = true
        
        TableView.delegate = self
        TableView.dataSource = self
        TableView.allowsSelection = false
        
        CommentTF.textAlignment = .center
        CommentTF.delegate = self

        let frame = CGRect(x:0, y:UIScreen.main.bounds.height - 35 , width: UIScreen.main.bounds.width, height: 35)
        CommentTF.frame = frame
        CommentTF.placeholder = "评论"
        CommentTF.textAlignment = .center
        CommentTF.backgroundColor = UIColor.white
        CommentTF.borderStyle = .roundedRect
        CommentTF.returnKeyType = .done
        self.view.addSubview(CommentTF)
        
        textFieldHeight = CommentTF.frame.origin.y
        //监听
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDisShow(notification:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        self.view.addGestureRecognizer(UITapGestureRecognizer(target:self, action:#selector(handleTap(sender:))))
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func handleKeyboardDisShow(notification: NSNotification) {
        //得到键盘frame
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        let value = userInfo.object(forKey: UIKeyboardFrameEndUserInfoKey)
        let keyboardRec = (value as AnyObject).cgRectValue
        let height = keyboardRec?.size.height
        //让textView bottom位置在键盘顶部
        UITextField.animate(withDuration: 0.1, animations: {
            self.CommentTF.frame.origin.y = UIScreen.main.bounds.height - height! - self.CommentTF.frame.height
            self.CommentTF.textAlignment = .left
        })
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            CommentTF.resignFirstResponder()
            UITextView.animate(withDuration: 0.1, animations: {
                var frame = self.CommentTF.frame
                frame.origin.y = self.textFieldHeight
                self.CommentTF.frame = frame
                self.CommentTF.textAlignment = .center
                self.CommentTF.text = ""
            })
        }
        sender.cancelsTouchesInView = false
    }
    
    func netGetComment() {
        
        let parameters: Parameters = [
            "articleId": article.articleID
        ]
        
        //网络请求
        let url = MenuViewController.APIURLHead + "article/getComments"
        Alamofire.request(url, method: .post, parameters: parameters).responseJSON{
            request in
            if let value = request.result.value{
                let json = JSON(value)
                let code = json[]["code"]
                if code == 200{
                    self.commentes.removeAll()
                    for (_, commentJson): (String, JSON) in json[]["comments"] {
                        let newComment = Comment()
                        newComment.comContent = commentJson[]["content"].string!
                        newComment.comUserName = commentJson[]["user"]["userName"].string!
                        newComment.comUserImage = commentJson[]["user"]["userImg"].string!
                        self.commentes.append(newComment)
                    }
                    self.TableView.reloadData()
                }else{
                    //to do: 错误处理
                }
            }
        }
    }
    
    func netComment(){
        
        guard CommentTF.text != "" else {
            return
        }
        let defaults = UserDefaults.standard
        let UserID = String(describing: defaults.value(forKey: "UserID")!)
        
        let parameters: Parameters = [
            "userId": UserID,
            "articleId": article.articleID,
            "content": CommentTF.text!
        ]
        
        //网络请求
        let url = MenuViewController.APIURLHead + "article/comment"
        Alamofire.request(url, method: .post, parameters: parameters).responseJSON{
            request in
            if let value = request.result.value{
                let json = JSON(value)
                let code = json[]["code"]
                if code == 200{
                    let nowarticle = self.article
                    nowarticle?.commentNum += 1
                    self.article = nowarticle
                }else{
                    // to do 错误处理
            }}
        }
    }
}

extension ArticleDetailViewController: UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, ArticleDetialCellDelegate{
    
    func willComment(sender: Any) {
        CommentTF.becomeFirstResponder()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentes.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var Rcell = UITableViewCell()
        if indexPath.row == 0{
            let cell = (tableView.dequeueReusableCell(withIdentifier: "articleDetialItem", for: indexPath) as! ArticleDetialCell)
            cell.article = self.article
            cell.delegate = self
            cellHeight = cell.cellHeight
            Rcell = cell
        }else{
            let cell = (tableView.dequeueReusableCell(withIdentifier: "CommentItem", for: indexPath) as! CommentCell)
            cell.localComment = commentes[indexPath.row - 1]
            commentCellHeigt = cell.ComContentLabel.frame.height + cell.CommentImgView.frame.height
            Rcell = cell
        }
        return Rcell
    }
    
    //cell高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = 0.0
        if indexPath.row == 0{
            height = cellHeight
        }else{
            height = commentCellHeigt
        }
        return height
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        netComment()
        textField.resignFirstResponder()
        //让textView bottom位置还原
        UITextView.animate(withDuration: 0.1, animations: {
            var frame = self.CommentTF.frame
            frame.origin.y = self.textFieldHeight
            self.CommentTF.frame = frame
            self.CommentTF.textAlignment = .center
            self.CommentTF.text = ""
        })
        return true
    }
}
