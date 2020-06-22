//
//  SavePostListController.swift
//  RSSReader
//
//  Created by nikolay on 24.04.2020.
//  Copyright © 2020 nikolay. All rights reserved.
//

import UIKit
import CoreData

class SavePostListController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var posts: [NSManagedObject] = []
    var dateFormatter = DateFormatter()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Saved articles", comment: "")
        
        showBarButtons()
    }
    
    func showBarButtons() {
        let btnEdit = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.edit, target: self, action: #selector(editTable))
        navigationItem.rightBarButtonItems = [btnEdit]
    }
    
    @IBAction func editTable(_ sender: Any) {
        tableView.isEditing = !tableView.isEditing
    }
    
    //MARK: Load posts from coredata
    
    override func viewWillAppear(_ animated: Bool) {
        posts = CoreDataManager.read_sort(entityName: "SavedPostItem", sortKey: "create_at", ascending: false)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavePostCell", for: indexPath)
        
        cell.textLabel?.numberOfLines = 0;
        cell.textLabel?.lineBreakMode = .byWordWrapping
        
        cell.textLabel?.text = posts[indexPath.row].value(forKey: "post_name") as? String
        
        let date = posts[indexPath.row].value(forKey: "post_date") as! Date
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        cell.detailTextLabel?.text = dateFormatter.string(from: date)

        return cell
    }
    
    //MARK: tap of cell
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let postDetailController = storyboard.instantiateViewController(identifier: "PostDetailController") as? PostDetailController else { return }
        
        let post_name = posts[indexPath.row].value(forKey: "post_name") as? String
        let post_url = posts[indexPath.row].value(forKey: "post_url") as? String
        let post_date = posts[indexPath.row].value(forKey: "post_date") as? Date
        
        postDetailController.post = PostItem(
            title: post_name ?? "",
            link: post_url ?? "",
            date: post_date ?? Date()
        )
        show(postDetailController, sender: nil)
    }
    
    
    //MARK: delete feed handler
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let deletePost = posts[indexPath.row]
            
            let managedContext = CoreDataManager.getContext()
            managedContext.delete(deletePost)
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
            
            //tableView.deleteRows(at: [indexPath], with: .fade)
            posts.remove(at: indexPath.row)
            tableView.reloadData()
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
}
