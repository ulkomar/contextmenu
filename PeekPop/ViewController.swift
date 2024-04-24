//
//  ViewController.swift
//  PeekPop
//
//  Created by Chu Hung on 12/04/2023.
//

import UIKit


class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var messages = [String]()
    let count = 20
    
    private let targetedPreview = ContextMenuView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier: "MessageCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        initData()
    }
    
    func initData() {
        for _ in 0..<count {
            messages.append(randomString(length: Int.random(in: Range<Int>.init(uncheckedBounds: (lower: 10, upper: 100)))))
        }
        tableView.reloadData()
    }
    func randomString(length: Int) -> String {
        let letters = "ab56789 "
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell") as? MessageCell else {
            return UITableViewCell()
        }
        cell.messageLB.text = messages[indexPath.row]
        return cell
    }



    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let identifier = NSString(string: "\(indexPath.row)")
        return targetedPreview.getContectMenuConfiguration(for: identifier)
    }
    
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        
        let previewView = targetedPreview.updateTargetedPreview(for: self, frame: .zero,tableView: tableView, for: configuration)
        targetedPreview.hide()
        return previewView
    }


    func tableView(_ tableView: UITableView, willDisplayContextMenu configuration: UIContextMenuConfiguration, animator: (any UIContextMenuInteractionAnimating)?) {
        self.targetedPreview.show()
    }

    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        targetedPreview.makeTargetedDismissPreview(tableView: tableView, for: configuration)
    }
    
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.preferredCommitStyle = .pop
    }
}

final class ContextMenuView: UIView {
    
    // MARK: - Constants
    
    private let reactionHeight: CGFloat = 40.0
    private let spaceReactionHeight: CGFloat = 5.0
    private let menuHeight: CGFloat = 200
    
    // MARK: - Preview
    
    private var targetedView: UITargetedPreview?
    private var contextMenu: UIMenu?
    
    // MARK: - Control functions

    func show() {
        targetedView?.view.isHidden = false
    }
    
    func hide() {
        targetedView?.view.isHidden = true
    }
    
    // MARK: - Initialization
    
    init() {
        super.init(frame: .zero)
        contextMenu = makeSystemContextMenu()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Functions
    
    func getContectMenuConfiguration(for identifier: NSString) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { [weak self] _ in
            return self?.contextMenu
        }
    }
    
    private func makeSystemContextMenu() -> UIMenu {
        let share = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) {_ in }
        let rename = UIAction(title: "Mark as read", image: UIImage(systemName: "square.and.pencil")) { _ in }
        let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) {_ in }
        return UIMenu(title: "", children: [share, rename, delete])
    }
    
    func updateTargetedPreview(
        for controller: UIViewController,
        frame: CGRect,
        tableView: UITableView,
        for configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String else { return nil }
        guard let row = Int(identifier) else { return nil }
        guard let cell = tableView.cellForRow(at: .init(row: row, section: 0)) as? MessageCell else { return nil }
        guard let snapshot = cell.resizableSnapshotView(from: CGRect(origin: .zero,
                                                                     size: CGSize(width: cell.bounds.width, height: min(cell.bounds.height, UIScreen.main.bounds.height - reactionHeight - spaceReactionHeight - menuHeight))),
                                                        afterScreenUpdates: false,
                                                        withCapInsets: UIEdgeInsets.zero) else { return nil }
        
        let reactionView = ReactionView()
        reactionView.onReaction = { [weak self] reactionType in
            guard let self = self else { return }
            print(reactionType)
            controller.dismiss(animated: true)
        }
        reactionView.layer.cornerRadius = 10
        reactionView.layer.masksToBounds = true
        reactionView.translatesAutoresizingMaskIntoConstraints = false
        
        snapshot.layer.cornerRadius = 10
        snapshot.layer.masksToBounds = true
        snapshot.translatesAutoresizingMaskIntoConstraints = false
        
        let container = UIView(frame: CGRect(origin: .zero,
                                             size: CGSize(width: cell.bounds.width,
                                                          height: snapshot.bounds.height + reactionHeight + spaceReactionHeight)))
        container.backgroundColor = .clear
        container.addSubview(reactionView)
        container.addSubview(snapshot)

        snapshot.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        snapshot.topAnchor.constraint(equalTo: reactionView.bottomAnchor, constant: spaceReactionHeight).isActive = true
        snapshot.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        snapshot.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true

        reactionView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10).isActive = true
        reactionView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        reactionView.widthAnchor.constraint(equalToConstant: 50*4).isActive = true
        reactionView.heightAnchor.constraint(equalToConstant: reactionHeight).isActive = true
        
        let centerPoint = getCenterPointForTargetedView(cell, additionalHeight: container.frame.height)
        let previewTarget = UIPreviewTarget(container: tableView, center: centerPoint)
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        if #available(iOS 14.0, *) {
            parameters.shadowPath = UIBezierPath()
        }
        let targetedPreview = UITargetedPreview(view: container, parameters: parameters, target: previewTarget)
        self.targetedView = targetedPreview
        return targetedPreview
    }
    
    private func getCenterPointForTargetedView(_ cell: MessageCell, additionalHeight: CGFloat) -> CGPoint {
        let locationOnScreen = cell.convert(cell.bounds, to: UIApplication.shared.keyWindow)
        let fullHeight = cell.frame.height + additionalHeight + spaceReactionHeight + reactionHeight + menuHeight
        
        if locationOnScreen.origin.y + fullHeight > (UIApplication.shared.keyWindow?.frame.height)! {
            let leftHeight = (locationOnScreen.origin.y + fullHeight) - (UIApplication.shared.keyWindow?.frame.height)!
            return .init(x: cell.center.x, y: cell.center.y - leftHeight)
        } else {
            return .init(x: cell.center.x, y: cell.center.y)
        }
    }
    
    func makeTargetedDismissPreview(tableView: UITableView,for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String else { return nil }
        guard let row = Int(identifier) else { return nil }
        guard let cell = tableView.cellForRow(at: .init(row: row, section: 0)) as? MessageCell else { return nil }
        guard let snapshot = cell.resizableSnapshotView(from: CGRect(origin: .zero,
                                                                     size: CGSize(width: cell.bounds.width, height: min(cell.bounds.height, UIScreen.main.bounds.height - reactionHeight - spaceReactionHeight - menuHeight))),
                                                        afterScreenUpdates: false,
                                                        withCapInsets: UIEdgeInsets.zero) else { return nil }
        
        let centerPoint = CGPoint(
            x: cell.center.x,
            y: cell.center.y
        )
        let previewTarget = UIPreviewTarget(container: tableView, center: centerPoint)
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        if #available(iOS 14.0, *) {
            parameters.shadowPath = UIBezierPath()
        }
        return UITargetedPreview(view: snapshot, parameters: parameters, target: previewTarget)
    }
}
