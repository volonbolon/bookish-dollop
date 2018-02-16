//
//  FilmsTableTableViewController.swift
//  BookishDollop
//
//  Created by Ariel Rodriguez on 16/02/2018.
//  Copyright © 2018 Ariel Rodriguez. All rights reserved.
//

import UIKit
import CoreData

class FilmsTableViewController: UITableViewController {
    enum SortBy: Int {
        case title
        case director
        case yearOfProduction
    }

    // MARK: - IBOutlets
    @IBOutlet var sortBySegmentedController: UISegmentedControl!

    // MARK: - IBActions
    @IBAction func sortedByValueChanged(_ sender: UISegmentedControl) {
        if let sortBy = SortBy(rawValue: sender.selectedSegmentIndex) {
            self.configureFetchedResultsController(sortBy: sortBy)
        }
    }

    // MARK: - Privates
    fileprivate let networkManager = NetworkManager()
    fileprivate var fetchedResultsController: NSFetchedResultsController<Film>!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension FilmsTableViewController { // Helpers
    fileprivate func configureFetchedResultsController(sortBy: SortBy) {
        var fetchRequest: NSFetchRequest<Film>
        var cacheName: String
        switch sortBy {
        case .director:
            cacheName = "director"
            fetchRequest = Film.sortedByDirectorFetchRequest
        case .title:
            cacheName = "title"
            fetchRequest = Film.sortedByTitleFetchRequest
        case .yearOfProduction:
            cacheName = "year"
            fetchRequest = Film.sortedByProductionYearFetchRequest
        }

        // We need to clean the cache, otherwise, fetchedResultsController
        // will fail to retrieve the correct object
        NSFetchedResultsController<Film>.deleteCache(withName: cacheName)

        // If the AppDelegate is not `appDelegate` then, we have a real problem.
        // Let's crash inmediatly
        // swiftlint:disable:next force_cast
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let persistentContainer = appDelegate.persistentContainer
        let context = persistentContainer.viewContext
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: cacheName)
        fetchedResultsController.delegate = self

        self.fetchedResultsController = fetchedResultsController
        do {
            try fetchedResultsController.performFetch()
            self.tableView.reloadData()
        } catch {
            print(error)
        }
    }
}

extension FilmsTableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
}
