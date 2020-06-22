//
//  RSSParser.swift
//  RSSReader
//
//  Created by nikolay on 18.04.2020.
//  Copyright © 2020 nikolay. All rights reserved.
//

import Alamofire
import AlamofireRSSParser

public class RSSParser {
    
    public static func getRSSFeedResponse(url: String, complete: @escaping (_ postItem: [PostItem]) -> Void) {
        
        AF.request(url).responseRSS() { (response) -> Void in
            if let feed: RSSFeed = response.value {
                
                var posts:[PostItem] = []

                for item in feed.items {
                    
                    let title = item.title ?? ""
                    let link = item.guid ?? ""
                    let date = item.pubDate ?? Date()
                    
                    posts.append(PostItem(title: title, link: link, date: date))
                }
                
                complete(posts)
            }
        }
        
    }
}
