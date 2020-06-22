//
//  ViewController.swift
//  RSSReader
//
//  Created by nikolay on 17.04.2020.
//  Copyright © 2020 nikolay. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireRSSParser
import CoreData

class PostListController: UIViewController,
    UITableViewDelegate, UITableViewDataSource {
    
    var posts: [PostItem] = []
    var feed = NSManagedObject()
    var refreshControl = UIRefreshControl()
    var dateFormatter = DateFormatter()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        showBarButtons()
        
        refreshControl.attributedTitle = NSAttributedString(string: NSLocalizedString("Refreshing", comment: ""))
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        tableView.addSubview(refreshControl)
        
        self.title = feed.value(forKey: "feed_name") as? String
        
        posts = []
        tableView.reloadData()
        
        getPosts();
    }
    
    func showBarButtons() {
        let btnSetPostsAsRead = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.bookmarks, target: self, action: #selector(markPostsAsRead))
        navigationItem.rightBarButtonItems = [btnSetPostsAsRead]
    }
    
    //MARK: action all posts set as read
    
    @IBAction func markPostsAsRead(_ sender: Any) {

        let managedContext = CoreDataManager.getContext()
        for post in posts {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"ReadPost")
            fetchRequest.predicate = NSPredicate(format: "post_url = %@", post.link)
            do {
                let results = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
                if results.count == 0 {
                    let entity = NSEntityDescription.entity(forEntityName: "ReadPost", in: managedContext)
                    let obj = NSManagedObject(entity: entity!, insertInto:managedContext)
                    obj.setValue(post.link, forKey: "post_url")
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
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    @objc func refresh(sender:AnyObject) {
        getPosts();
    }
    
    func getPosts() {

        self.refreshControl.beginRefreshing()
        
        let url = feed.value(forKey: "feed_url") as? String
        
        RSSParser.getRSSFeedResponse(url: url ?? "") { (new_posts: [PostItem]) in
            self.posts = new_posts
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
    
    //MARK: table view datasource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
      
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath)
        
        cell.textLabel?.numberOfLines = 0;
        cell.textLabel?.lineBreakMode = .byWordWrapping
        
        cell.textLabel?.text = posts[indexPath.row].title
        
        let date = posts[indexPath.row].date
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        cell.detailTextLabel?.text = dateFormatter.string(from: date)
        
        //read or not read
        
        let managedContext = CoreDataManager.getContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"ReadPost")
        fetchRequest.predicate = NSPredicate(format: "post_url = %@", posts[indexPath.row].link)
        do {
            let results = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
            if (results.count != 0) {
                cell.textLabel?.textColor = UIColor.gray
                cell.detailTextLabel?.textColor = UIColor.gray
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        return cell
    }
    
    //MARK: table delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let postDetailController = storyboard.instantiateViewController(identifier: "PostDetailController") as? PostDetailController else { return }
        postDetailController.post = posts[indexPath.row]
        show(postDetailController, sender: nil)
    }
}
