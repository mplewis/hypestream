//
//  ViewController.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/17/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!

    var tracks: [JSON] = [JSON]() {
        didSet {
            self.tableView.reloadData()
        }
    }
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl.addTarget(self, action: Selector("refreshFeed"), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        self.refreshFeed()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("SongCell") as UITableViewCell
        let track = tracks[indexPath.row]
        let artist = track["artist"].asString
        let title = track["song"].asString
        cell.textLabel.text = title
        cell.detailTextLabel!.text = artist
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let track = tracks[indexPath.row]
        let idOp = track["id"].asString
        let keyOp = track["key"].asString
        let artistOp = track["artist"].asString
        let titleOp = track["song"].asString
        
        if (idOp == nil || keyOp == nil) {
            println("Missing ID or key for \(track)")
            return
        }

        if (artistOp == nil || titleOp == nil) {
            println("Missing artist or title for \(track)")
            return
        }
        
        let id = idOp!
        let key = keyOp!
        let artist = artistOp!
        let title = titleOp!

        Scraper.getSourceURLForTrack(id, key: key, onURL: { sourceUrl in
            let targetURL = NSURL.fileURLWithPathComponents([documentsPath, "\(artist) - \(title).mp3"])!
            Alamofire.download(.GET, sourceUrl, { (_, _) in targetURL })
                .progress( { rawBytesSinceLast, rawBytesReceived, rawBytesTotal in
                    let percent = Float(rawBytesReceived) / Float(rawBytesTotal) * 100
                    println("\(percent)")
                }).response( { request, response, _, errorOp in
                    if let error = errorOp {
                        println("Error while downloading track: \(error.localizedDescription)")
                    } else {
                        println("Track saved to \(targetURL)")
                    }
                })
            Alamofire.request(.GET, sourceUrl).validate(statusCode: [200])
        }, onError: { error in
            println("Error while getting source URL for \(id): \(error.localizedDescription)")
        })

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    func refreshFeed() {
        Scraper.getPopularTracks( { tracks in
            self.refreshControl.endRefreshing()
            self.tracks = tracks
        }, onError: { error in
            println("Error while refreshing feed: \(error.localizedDescription)")
        })
    }
}
