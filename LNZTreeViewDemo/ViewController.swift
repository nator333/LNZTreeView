//
//  ViewController.swift
//  LNZTreeViewDemo
//
//  Created by Giuseppe Lanza on 07/11/2017.
//  Copyright © 2017 Giuseppe Lanza. All rights reserved.
//

import UIKit
import LNZTreeView
import Social
import MobileCoreServices

class CustomUITableViewCell: UITableViewCell
{
    override func layoutSubviews() {
        super.layoutSubviews();
        
        guard var imageFrame = imageView?.frame else { return }
        
        let offset = CGFloat(indentationLevel) * indentationWidth
        imageFrame.origin.x += offset
        imageView?.frame = imageFrame
    }
}


class Node: NSObject, TreeNodeProtocol {
    var identifier: String
    var isExpandable: Bool {
        return children != nil
    }
    
    var children: [Node]?
    
    init(withIdentifier identifier: String, andChildren children: [Node]? = nil) {
        self.identifier = identifier
        self.children = children
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var treeView: LNZTreeView!
    var root = [Node]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        treeView.register(CustomUITableViewCell.self, forCellReuseIdentifier: "cell")

        treeView.tableViewRowAnimation = .right
                
        generateRandomNodes()
        treeView.resetTree()
    }
    
    func generateRandomNodes() {
        let depth = 3
        let rootSize = 30
        
        var root: [Node]!
        
        var lastLevelNodes: [Node]?
        for i in 0..<depth {
            guard let lastNodes = lastLevelNodes else {
                root = generateNodes(rootSize, depthLevel: i)
                lastLevelNodes = root
                continue
            }
            
            var thisDepthLevelNodes = [Node]()
            for node in lastNodes {
                guard arc4random()%2 == 1 else { continue }
                let childrenNumber = Int(arc4random()%20 + 1)
                let children = generateNodes(childrenNumber, depthLevel: i)
                node.children = children
                thisDepthLevelNodes += children
            }
            
            lastLevelNodes = thisDepthLevelNodes
        }
        
        self.root = root
    }
    
    func generateNodes(_ numberOfNodes: Int, depthLevel: Int) -> [Node] {
        let nodes = Array(0..<numberOfNodes).map { i -> Node in
            return Node(withIdentifier: "\(arc4random()%UInt32.max)")
        }
        
        return nodes
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: LNZTreeViewDataSource {
    func sectionIndexTitles(for treeView: LNZTreeView) -> [String]? {
        return nil
    }
    
    func numberOfSections(in treeView: LNZTreeView) -> Int {
        return 1
    }
    
    func treeView(_ treeView: LNZTreeView, numberOfRowsInSection section: Int, forParentNode parentNode: TreeNodeProtocol?) -> Int {
        guard let parent = parentNode as? Node else {
            return root.count
        }
        
        return parent.children?.count ?? 0
    }
    
    func treeView(_ treeView: LNZTreeView, nodeForRowAt indexPath: IndexPath, forParentNode parentNode: TreeNodeProtocol?) -> TreeNodeProtocol {
        guard let parent = parentNode as? Node else {
            return root[indexPath.row]
        }

        return parent.children![indexPath.row]
    }
    
    func treeView(_ treeView: LNZTreeView, cellForRowAt indexPath: IndexPath, forParentNode parentNode: TreeNodeProtocol?, isExpanded: Bool) -> UITableViewCell {
        
        let node: Node
        if let parent = parentNode as? Node {
            node = parent.children![indexPath.row]
        } else {
            node = root[indexPath.row]
        }
        
        let cell = treeView.dequeueReusableCell(withIdentifier: "cell", for: node, inSection: indexPath.section)

        if node.isExpandable {
            if isExpanded {
                cell.imageView?.image = #imageLiteral(resourceName: "index_folder_indicator_open")
            } else {
                cell.imageView?.image = #imageLiteral(resourceName: "index_folder_indicator")
            }
        } else {
            cell.imageView?.image = nil
        }
        
        cell.textLabel?.text = node.identifier
        
        return cell
    }
}

extension ViewController: LNZTreeViewDelegate {
    func treeView(_ treeView: LNZTreeView, heightForNodeAt indexPath: IndexPath, forParentNode parentNode: TreeNodeProtocol?) -> CGFloat {
        return 60
    }
}

extension ViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return self.dragItems(for: indexPath)
    }
    
    private func dragItems(for indexPath: IndexPath) -> [UIDragItem] {
        
        let placeName = self.root[indexPath.row]
        //let data = placeName.data(using: .utf8)
        let itemProvider = NSItemProvider(object: placeName.identifier as NSString)
        return [
            UIDragItem(itemProvider: itemProvider)
        ]
    }
}

extension ViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return self.canHandle(session)
    }
    
    private func canHandle(_ session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        // The .move operation is available only for dragging within a single app.
        if tableView.hasActiveDrag {
            if session.items.count > 1 {
                return UITableViewDropProposal(operation: .cancel)
            } else {
                return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            }
        } else {
            return UITableViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            // Get last index path of table view.
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        coordinator.session.loadObjects(ofClass: NSString.self) { items in
            // Consume drag items.
            let stringItems = items as! [String]
            
            var indexPaths = [IndexPath]()
            for (index, _) in stringItems.enumerated() {
                let indexPath = IndexPath(row: destinationIndexPath.row + index, section: destinationIndexPath.section)
                //self.model.addItem(item, at: indexPath.row)
                indexPaths.append(indexPath)
            }
            
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }
}
