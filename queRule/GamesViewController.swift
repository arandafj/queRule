//
//  GamesViewController.swift
//  queRule
//
//  Created by CLAG on 18/11/16.
//  Copyright © 2016 Clag. All rights reserved.
//

import UIKit
import CoreData

class GamesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var filterControl: UISegmentedControl!
    
    var managedObjectContext: NSManagedObjectContext? = nil
    var lstGames: [Game] = [Game]()
    
    @IBAction func filterChanged(_ sender: UISegmentedControl) {
        performGamesQuery()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.alwaysBounceVertical = true
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performGamesQuery()
        
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if lstGames.count == 0 {
            
            let imageView = UIImageView(image: UIImage(named: "img_empty_screen"))
            imageView.contentMode = .center
            collectionView.backgroundView = imageView
        } else {
            collectionView.backgroundView = UIView()
        }
        
        return lstGames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "editGameSegue", sender: self)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        if (offsetY < -120) {
            performSegue(withIdentifier: "addGameSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addGameSegue" {
            let addNavVC = segue.destination as! UINavigationController
            let addVC = addNavVC.topViewController as! AddGamesViewController
            addVC.managedObjectContext = self.managedObjectContext
            addVC.delegate = self
        }
        
        if segue.identifier == "editGameSegue" {
            let addGameVC = segue.destination as! AddGamesViewController
            addGameVC.managedObjectContext = self.managedObjectContext
            
            let selectedIndex = collectionView.indexPathsForSelectedItems?.first?.row
            let game = lstGames[selectedIndex!]
            addGameVC.game = game
            
            addGameVC.delegate = self
            
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GameCell", for: indexPath) as! GameCell
        
        let game = lstGames[indexPath.row]
        
        // Obtenemos datos del modelo
        cell.lblTitel.text = game.title
        
        
        var highlightColor = #colorLiteral(red: 0.9058823529, green: 0.2980392157, blue: 0.2352941176, alpha: 1)
        if !game.borrowed {
            highlightColor = #colorLiteral(red: 0.2039215686, green: 0.5960784314, blue: 0.8588235294, alpha: 1)
        }
        
        cell.lblBorrowed.attributedText = self.formatColours(string: "Prestado: \(game.borrowed ? "Si" : "No")"
            , color: highlightColor)
        
        if let borrowedTo = game.borrowedTo {
            cell.lblBorrowedTo.attributedText = self.formatColours(string: "A: \(borrowedTo)"
                , color: highlightColor)
        } else {
            cell.lblBorrowedTo.attributedText = self.formatColours(string: "A: --", color: highlightColor)
        }
        
        if let borrowedDate = game.borrowedDate as? Date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            
            cell.lblBorrowedDate.attributedText = self.formatColours(string: "Fecha: \(dateFormatter.string(from: borrowedDate))"
                , color: highlightColor)
        } else {
            cell.lblBorrowedDate.attributedText = self.formatColours(string: "Fecha: --", color: highlightColor)
        }
        
        if let image = game.image as? Data {
            cell.imageView.image = UIImage(data: image)
        }
        
        cell.layer.masksToBounds = false
        cell.layer.shadowOffset = CGSize(width: 1, height: 1)
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.2
        
        return cell
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width: self.view.frame.size.width - 20, height: 120.0)
    }

    func formatColours(string: String, color: UIColor) -> NSMutableAttributedString {
        
        let lenght = string.characters.count
        let colonPosition = string.indexOf(target: ":")!
        
        let myMutableString = NSMutableAttributedString.init(string: string, attributes: nil)
        
        myMutableString.addAttribute(
            NSForegroundColorAttributeName,
            value: color,
            range: NSRange(
                location: 0,
                length: lenght))
        
        myMutableString.addAttribute(
            NSForegroundColorAttributeName,
            value: UIColor.black,
            range: NSRange(
                location: 0,
                length: colonPosition + 1))

        return myMutableString
        
    }
    
    func performGamesQuery() {
        
        let request: NSFetchRequest<Game> = Game.fetchRequest()
        let sortByDate = NSSortDescriptor(key: "dateCreated", ascending: false)
        
        request.sortDescriptors = [sortByDate]
        
        if filterControl.selectedSegmentIndex == 0 {
            // Prestados
            let predicate = NSPredicate(format: "borrowed = true")
            request.predicate = predicate
        }
        
        do {
            let fetchedGames = try managedObjectContext?.fetch(request)
            if let fetchedGames = fetchedGames{
                lstGames = fetchedGames
                collectionView.reloadData()
            }
            
        } catch {
            print("Error recuperando datos de Core Data")
        }
    }
    
}


extension GamesViewController : AddGameViewControllerDelegate {
    func didAddGame() {
        self.collectionView.reloadData()
    }
}

extension String {
    
    func indexOf(target: String) -> Int? {
        if let range = self.range(of: target){
            return distance(from: self.startIndex, to: range.lowerBound)
        }
        
        return nil
        
    }
    
    
}
