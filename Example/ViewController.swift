//
//  ViewController.swift
//  ScrollPagingController
//
//  Created by Alexander Goremykin on 08.04.2018.
//  Copyright © 2018 Alexander Goremykin. All rights reserved.
//

import UIKit
import ScrollPagingController

class ViewController: UIViewController {

    // MARK: - Public Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

        expanded = true
        tableView.drive(by: driver)

        view.addSubview(button)
        button.setTitle("ACTION", for: .normal)
        button.addTarget(self, action: #selector(onButton(_:)), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.topAnchor.constraint(equalTo: view.topAnchor, constant: 30.0).isActive = true
        button.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30.0).isActive = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        pagingController.canAnchorMostBottomControlPointViaGesture = false

        self.pagingController.setControlPoints(
            [
                ScrollPagingController.RelativeControlPoint(anchor: .bottom, value: 0.0, bouncingDirection: .none),
                ScrollPagingController.RelativeControlPoint(anchor: .bottom, value: 200.0, bouncingDirection: .any),
                ScrollPagingController.RelativeControlPoint(anchor: .top, value: 104.0, bouncingDirection: .any)
            ],
            anchoringToPointWithIndex: 1,
            animated: false
        )
    }

    // MARK: - Private Properties

    private var expanded = false

    private let tableView = UITableView()
    private lazy var driver: TableViewDriver = {
        let driver = SimpleTableViewDriver(cellType: CommonTableCell<UILabel>.self, numberOfRows: 300) { index, cell in
            let text = (self.expanded && index == 2) ? "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat." : "\(index)"
            (cell as? CommonTableCell<UILabel>)?.content.text = text
            (cell as? CommonTableCell<UILabel>)?.content.numberOfLines = 0
        }

        driver.scrollViewDelegate = self
        
        return driver
    }()

    private lazy var pagingController: ScrollPagingController = {
        return ScrollPagingController(scrollView: self.tableView)
    }()

    private let button = UIButton(type: .system)

}

extension ViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > -UIScreen.main.bounds.height / 2.0 {
            guard expanded else { return }
            tableView.beginUpdates()
            expanded = !expanded
            tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
            tableView.endUpdates()
        } else {
            guard !expanded else { return }
            tableView.beginUpdates()
            expanded = !expanded
            tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
            tableView.endUpdates()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pagingController.scrollViewWillBeginDragging(scrollView)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        pagingController.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return pagingController.scrollViewShouldScrollToTop(scrollView)
    }

}

fileprivate extension ViewController {

    @objc private func onButton(_ sender: UIButton) {
        expanded = !expanded
        tableView.reloadData()
    }

}
