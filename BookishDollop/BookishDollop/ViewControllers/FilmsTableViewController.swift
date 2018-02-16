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

    func refreshDatabase(rawFilms: NetworkManager.RawFilms) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let container = appDelegate.persistentContainer
            Film.insertInBulk(rawObjects: rawFilms, container: container, completionBlock: { (success: Bool) in
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
            })
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
        cell.additionalInformationLabel.text = film.director
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
