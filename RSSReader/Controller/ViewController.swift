//
//  ViewController.swift
//  RSSReader
//
//  Created by nikolay on 17.04.2020.
//  Copyright © 2020 nikolay. All rights reserved.
//

import UIKit
import CoreData
import GoogleMobileAds

class ViewController: UIViewController,
    UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addBarButton: UIBarButtonItem!
    
    var data:[NSManagedObject] = []
    var bannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showBarButtons()
        
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        bannerView.adUnitID = "ca-app-pub-6248241929645142/4968400544"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        tableView.isHidden = true
    }
    
    func showBarButtons() {
        let btnAdd = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addFeed))
        let btnBookmark = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.bookmarks, target: self, action: #selector(showSavedPosts))
        navigationItem.rightBarButtonItems = [btnBookmark, btnAdd]
    }
    
    @IBAction func showSavedPosts(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let savePostListController = storyboard.instantiateViewController(identifier: "SavePostListController") as? SavePostListController else { return }
        show(savePostListController, sender: nil)
    }
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                           attribute: .bottom,
                           relatedBy: .equal,
                           toItem: view.safeAreaLayoutGuide,
                           attribute: .bottom,
                           multiplier: 1,
                           constant: 0),
             NSLayoutConstraint(item: bannerView,
                           attribute: .centerX,
                           relatedBy: .equal,
                           toItem: view,
                           attribute: .centerX,
                           multiplier: 1,
                           constant: 0)
       ])
    }
    
    @IBAction func editTable(_ sender: Any) {
        tableView.isEditing = !tableView.isEditing
    }
    
    //MARK: load Feeds from CoreData
    
    override func viewWillAppear(_ animated: Bool) {
        data = CoreDataManager.read_sort(entityName: "FeedItem", sortKey: "sort", ascending: false)
    }

    //MARK: BarButton
    
    @IBAction func addFeed(_ sender: Any) {
        
        let alert = UIAlertController(title: NSLocalizedString("Add RSS feed", comment: ""), message: NSLocalizedString("Type name and URL of feed", comment: ""), preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("Name (not required)", comment: "")
        }
        alert.addTextField { (textField) in
            textField.placeholder = "https://website.com/rss.xml"
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Add", comment: ""), style: .default, handler: { _ in
            let nameField = alert.textFields![0]
            var name = nameField.text ?? ""
            
            let urlField = alert.textFields![1]
            let url = (urlField.text ?? "")
            
            if(!url.isEmpty) {
                if(name.isEmpty) {
                    name = url
                }
                self.addNewFeedItem(feed_url: url, feed_name: name)
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in
        }))
        self.present(alert, animated: true, completion: nil)
    }
   
    //MARK: add new feed
    
    func addNewFeedItem(feed_url: String, feed_name: String) {
        
        let managedContext = CoreDataManager.getContext()
        let entity = NSEntityDescription.entity(forEntityName: "FeedItem", in: managedContext)
        
        let obj = NSManagedObject(entity: entity!, insertInto:managedContext)
        obj.setValue(feed_name, forKey: "feed_name")
        obj.setValue(feed_url, forKey: "feed_url")
        obj.setValue((data.count + 1), forKey: "sort")
        
        do {
          try managedContext.save()
        } catch let error as NSError {
          print("Could not save. \(error), \(error.userInfo)")
        }
        
        data.insert(obj, at: 0)
        
        tableView.reloadData()
    }

    //MARK: count of cells
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(data.count > 0) {
            tableView.isHidden = false
        } else {
            tableView.isHidden = true
        }
        return data.count
    }
    
    //MARK: Cell for Row
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellFeed", for: indexPath)
        let feed = data[indexPath.row]
        cell.textLabel?.text = feed.value(forKey: "feed_name") as? String
        return cell
    }
    
    //MARK: tap on cell
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let postListController = storyboard.instantiateViewController(identifier: "PostListController") as? PostListController else { return }
        postListController.feed = data[indexPath.row]
        show(postListController, sender: nil)
    }
    
    //MARK: delete feed handler
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let deleteFeed = data[indexPath.row]
            
            let managedContext = CoreDataManager.getContext()
            managedContext.delete(deleteFeed)
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
            
            //tableView.deleteRows(at: [indexPath], with: .fade)
            data.remove(at: indexPath.row)
            tableView.reloadData()
            
            saveSortFeeds()
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true;
    }
    
    //MARK: move of cell
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let feed = data[sourceIndexPath.row]
        data.remove(at: sourceIndexPath.row)
        data.insert(feed, at: destinationIndexPath.row)
        
        saveSortFeeds()
    }
    
    func saveSortFeeds() {
        
        let managedContext = CoreDataManager.getContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"FeedItem")
        
        var i = data.count
        
        for feed in data {
            
            let found_url = feed.value(forKey: "feed_url") as! String
            fetchRequest.predicate = NSPredicate(format: "feed_url = %@", found_url)
            
            do {
                let results = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
                if results.count != 0 {
                    let managedObject = results[0]
                    managedObject.setValue(i, forKey: "sort")
                    
                    i-=1
                    
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
    }
}
