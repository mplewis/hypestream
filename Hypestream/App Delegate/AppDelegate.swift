//
//  AppDelegate.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/17/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import UIKit
import CoreData

// MARK: - BackgroundDownloadProgress Protocol

@objc protocol DownloadProgressDelegate {
    optional func didMoveTrackToInbox(track: Track)
}

// MARK: - AppDelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, NSURLSessionDownloadDelegate {

    var window: UIWindow?
    
    lazy var bkgSession: NSURLSession = {
        let bkgConfig = NSURLSessionConfiguration.backgroundSessionConfiguration("com.kesdev.Hypestream")
        return NSURLSession(configuration: bkgConfig, delegate: self, delegateQueue: nil)
    }()
    
    var downloadProgressDelegate: DownloadProgressDelegate?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        println("Documents path: \(documentsPath)")
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        SVProgressHUD.setForegroundColor(UIColor.whiteColor())
        SVProgressHUD.setBackgroundColor(UIColor(red: 0, green: 0, blue: 0, alpha: 0.8))
        return true
    }
    
    // MARK: - Background Fetch

    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        println("Fetching in background...")
        Scraper.addNewTracksToDB({ (added, skipped, errors) -> Void in
            for track in added {
                println("Added track: \(track.artist) - \(track.title)")
            }
            for track in skipped {
                println("Skipped existing track: \(track.artist) - \(track.title)")
            }
            for error in errors {
                println("Error: \(error.userInfo)")
            }
            println("Done! Added \(added.count) tracks with \(errors.count) errors.")

            if (added.count > 0) {
                completionHandler(.NewData)
            } else {
                completionHandler(.NoData)
            }
        }, onError: { (error) -> Void in
            completionHandler(.Failed)
        })
    }
    
    func downloadTrack(track: Track) {
        track.downloadProgress = 0
        track.downloadInProgress = true
        if let url = NSURL(string: track.source_url) {
            let task = bkgSession.downloadTaskWithURL(url)
            task.taskDescription = track.hypem_id
            task.resume()
        } else {
            println("Couldn't create NSURL from \(track.source_url)")
        }
    }
    
    // MARK: - NSURLSessionDownloadDelegate
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let taskId = downloadTask.taskDescription
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        println("\(taskId): \(progress)")
        let results = Helper.getTracksWithId(taskId)
        if let error = results.error {
            println(error.localizedDescription)
        } else {
            let track = results.tracks![0]
            track.downloadInProgress = true
            track.downloadProgress = progress
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        println("\(downloadTask): \(fileOffset): \(expectedTotalBytes)")
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL source: NSURL) {
        let taskId = downloadTask.taskDescription
        println("\(taskId): done -> \(source)")
        let fileManager = NSFileManager.defaultManager()
        let results = Helper.getTracksWithId(taskId)
        if let error = results.error {
            // Error getting track with ID = task ID.
            println(error.localizedDescription)
            // Try to delete downloaded tmp file. We don't care if the deletion of a temp file fails.
            fileManager.removeItemAtURL(source, error: nil)
        } else {
            let track = results.tracks![0]
            track.downloadInProgress = false
            track.downloadProgress = 1
            let destString = documentsPath.stringByAppendingPathComponent("\(track.hypem_id).mp3")
            if let dest = NSURL(fileURLWithPath: destString) {
                println("\(taskId): moving -> \(dest)")
                var fileError: NSError?
                fileManager.copyItemAtURL(source, toURL: dest, error: &fileError)
                if let error = fileError {
                    // Error moving file to Documents folder.
                    println(error.localizedDescription)
                    // Try to delete downloaded tmp file. We don't care if the deletion of a temp file fails.
                    fileManager.removeItemAtURL(source, error: nil)
                } else {
                    track.local_file_url = destString
                    track.state = .Inbox
                    println("\(taskId): moved -> \(dest)")
                    var dbError: NSError?
                    managedObjectContext!.save(&dbError)
                    if (dbError != nil) {
                        println(dbError!.localizedDescription)
                    }
                    downloadProgressDelegate?.didMoveTrackToInbox?(track)
                }
            } else {
                println("Couldn't convert dest to URL: \(destString)")
            }
        }
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.kesdev.Hypestream" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as NSURL
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Hypestream", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Hypestream.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }


}

