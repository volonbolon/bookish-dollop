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
        case location
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

        let sortBy = SortBy(rawValue: self.sortBySegmentedController.selectedSegmentIndex)!
        self.configureFetchedResultsController(sortBy: sortBy)

        self.networkManager.fetchFilms { (result: Either<NetworkControllerError, NetworkManager.RawFilms>) in
            switch result {
            case .left(let error):
                print(error)
            case .right(let rawFilms):
                DispatchQueue.main.async {
                    self.refreshDatabase(rawFilms: rawFilms)
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueIdentifier = segue.identifier
        if segueIdentifier == "ShowLocationsSegue" {
            if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
                let film = self.fetchedResultsController.object(at: selectedIndexPath)
                let location = film.location
                if let destinationViewController = segue.destination as? MapViewViewController {
                    destinationViewController.location = location
                    destinationViewController.title = film.title
                }
            }
        }
    }
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
        case .location:
            cacheName = "location"
            fetchRequest = Film.sortedByLocationFetchRequest
        }

        // We need to clean the cache, otherwise, fetchedResultsController
        // will fail to retrieve the correct object
        NSFetchedResultsController<Film>.deleteCache(withName: nil)

        NSFetchedResultsController<Film>.deleteCache(withName: "director")
        NSFetchedResultsController<Film>.deleteCache(withName: "title")
        NSFetchedResultsController<Film>.deleteCache(withName: "year")

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

    func refreshDatabase(rawFilms: NetworkManager.RawFilms) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let container = appDelegate.persistentContainer
            DispatchQueue.global().async {
                Film.insertInBulk(rawObjects: rawFilms, container: container, completionBlock: { (success: Bool) in
                    DispatchQueue.main.async {
                        if success {
                            do {
                                try self.fetchedResultsController.performFetch()
                                self.tableView.reloadData()
                            } catch {
                                let fetchError = error as NSError
                                print("Unable to Perform Fetch Request")
                                print("\(fetchError), \(fetchError.localizedDescription)")
                            }
                        }
                    }
                })
            }
        }
    }
}

extension FilmsTableViewController { // MARK: - UITableViewDatasource
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let numberOfSections = self.fetchedResultsController.sections?.count else {
            return 0
        }
        return numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let films = self.fetchedResultsController.fetchedObjects else {
            return 0
        }
        let numberOfRowsInSection = films.count
        return numberOfRowsInSection
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "filmCellIdentifier", for: indexPath) as! FilmTableViewCell

        let film = self.fetchedResultsController.object(at: indexPath)

        cell.titleLabel.text = film.title
        cell.additionalInformationLabel.text = film.location
        cell.productionYearLabel.text = film.year

        return cell
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
