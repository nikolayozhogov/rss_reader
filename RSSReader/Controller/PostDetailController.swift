//
//  ViewController.swift
//  RSSReader
//
//  Created by nikolay on 17.04.2020.
//  Copyright © 2020 nikolay. All rights reserved.
//

import UIKit
import WebKit
import CoreData

class PostDetailController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    
    var post = PostItem(title: "", link: "", date: Date())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        
        webViewOpenURL()
        
        setPostAsReaded()
    }
    
    func setPostAsReaded() {
        
        let managedContext = CoreDataManager.getContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"ReadPost")
        
        fetchRequest.predicate = NSPredicate(format: "post_url = %@", post.link)
        
        do {
            let results = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
            if (results.count == 0) {

                let entity = NSEntityDescription.entity(forEntityName: "ReadPost", in: managedContext)
                let obj = NSManagedObject(entity: entity!, insertInto:managedContext)
                
                obj.setValue(post.link, forKey: "post_url")
                
                do {
                    try managedContext.save()
                } catch let error2 as NSError {
                    print("Could not save. \(error2), \(error2.userInfo)")
                }
            }
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func webViewOpenURL() {
        let url = URL(string: post.link)!
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true
    }
    
    func showBarButtons() {
        let btnRefresh = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.refresh, target: self, action: #selector(reloadButton))
        let btnShare = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.reply, target: self, action: #selector(shareButton))
        let btnBookmark = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.bookmarks, target: self, action: #selector(bookmarkButton))
        navigationItem.rightBarButtonItems = [btnBookmark, btnShare, btnRefresh]
    }
    
    func hideBarButtons() {
        //navigationItem.rightBarButtonItems = nil
        let btnShare = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.reply, target: self, action: #selector(shareButton))
        let btnBookmark = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.bookmarks, target: self, action: #selector(bookmarkButton))
        navigationItem.rightBarButtonItems = [btnBookmark, btnShare]
    }
    
    //MARK: bookmark action
    
    @objc func bookmarkButton(sender:AnyObject) {
        
        let alert = UIAlertController(title: NSLocalizedString("Saved", comment: ""), message: NSLocalizedString("Article saved to Favorites", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { _ in
        }))
        self.present(alert, animated: true, completion: nil)
        
        // save if not exists
        
        let managedContext = CoreDataManager.getContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"SavedPostItem")
        fetchRequest.predicate = NSPredicate(format: "post_url = %@", post.link)
        do {
            let results = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
            if results.count == 0 {
                
                let entity = NSEntityDescription.entity(forEntityName: "SavedPostItem", in: managedContext)
                let obj = NSManagedObject(entity: entity!, insertInto:managedContext)
                obj.setValue(post.title, forKey: "post_name")
                obj.setValue(post.link, forKey: "post_url")
                obj.setValue(post.date, forKey: "post_date")
                obj.setValue(Date(), forKey: "create_at")
                do {
                    try managedContext.save()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    //MARK: share action
    
    @objc func shareButton(sender:AnyObject) {
        let activityVC = UIActivityViewController(activityItems: [post.link], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        self.present(activityVC, animated: true, completion: nil)
    }
    
    //MARK: reload action
    
    @objc func reloadButton(sender:AnyObject) {
        webViewOpenURL()
    }
    
    //MARK: webview delegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        hideBarButtons()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        showBarButtons()
    }
    
}
