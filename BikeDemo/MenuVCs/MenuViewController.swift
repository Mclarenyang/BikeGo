//
//  MenuViewController.swift
//  BikeDemo
//
//  Created by 杨键 on 2018/4/3.
//  Copyright © 2018年 mclarenYang. All rights reserved.
//

import UIKit
import RealmSwift

class MenuViewController: UIViewController {
    
    static let APIURLHead = "http://120.77.87.78:8080/cycle/api/"
    var isComeToPersonal = false
    
    //storyboard
    @IBOutlet weak var HeadPortraitIamgeView: UIImageView!
    @IBOutlet weak var HelloLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hero.isEnabled = true
        
        HeadPortraitIamgeView.layer.masksToBounds = true
        HeadPortraitIamgeView.layer.cornerRadius = 45
        HeadPortraitIamgeView.isUserInteractionEnabled = true
        let headImageGesture = UITapGestureRecognizer(target: self, action: #selector(selectHeadImageOrHelloLabel))
        HeadPortraitIamgeView.addGestureRecognizer(headImageGesture)
        HelloLabel.isUserInteractionEnabled = true
        HelloLabel.addGestureRecognizer(headImageGesture)
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        //判断用户是否登陆 -> 调整UI
        let defaults = UserDefaults.standard
        let LogInStatus = String(describing: defaults.value(forKey: "LogInStatus")!)
        if LogInStatus == "yes" {
            //如果用户登录过 -> 彩色UI / 从Realm获取用户的头像 ／获取用户的昵称
            let UserID = String(describing: defaults.value(forKey: "UserID")!)
            let realm = try! Realm()
            let user = realm.objects(User.self).filter("userID = \(UserID)")[0]
            
            HeadPortraitIamgeView.image = UIImage(data: user.userImg as Data)
            HelloLabel.text = "Hi,\(user.userName)"
            print("数据库地址：\(realm.configuration.fileURL!)")
            
            guard isComeToPersonal == true else {
                let time: TimeInterval = 0.25
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
                    self.selectHeadImageOrHelloLabel()
                }
                return
            }
            
        } else {
            //如果用户还没有登录 -> 按钮失效
            HeadPortraitIamgeView.image = #imageLiteral(resourceName: "HeadPortraitIamge")
            HelloLabel.text = "sign in / sign up"
        }
        
    }
 
    //点击事件
    @objc func selectHeadImageOrHelloLabel(){
        if HelloLabel.text == "sign in / sign up" {
            // 跳转到登录页面
            let signInVC = (UIStoryboard(name: "LogIn", bundle: nil).instantiateViewController(withIdentifier: "SignIn") as? SignInViewController)!
            self.show(signInVC, sender: nil)
        } else {
            // 跳转到个人主页
            let personalVC = (UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Personal") as? PersonalViewController)!
            self.isComeToPersonal = true
            self.show(personalVC, sender: nil)
        }
    }

}