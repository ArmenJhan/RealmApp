//
//  TaskListsViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import UIKit
import RealmSwift

class TaskListViewController: UITableViewController {

    private var taskLists: Results<TaskList>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        
        navigationItem.rightBarButtonItem = addButton
        navigationItem.leftBarButtonItem = editButtonItem
        createTempData()
        taskLists = StorageManager.shared.realm.objects(TaskList.self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskLists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let taskList = taskLists[indexPath.row]
        let currentTask = taskList.tasks.filter("isComplete = false")
        let completeTask = taskList.tasks.filter("isComplete = true")
        content.text = taskList.name
        
        if currentTask.isEmpty && !completeTask.isEmpty {
            cell.accessoryType = .checkmark
        }else {
            cell.accessoryType = .none
            content.secondaryText = "\(currentTask.count)"
        }
        cell.contentConfiguration = content
        return cell
    }
    
    // MARK: - Table View Data Source
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let taskList = taskLists[indexPath.row]
        let currentTask = taskList.tasks.filter("isComplete = false")

        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.delete(taskList)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [unowned self] _, _, isDone in
            showAlert(with: taskList) {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        
        if !currentTask.isEmpty{
            let doneAction = UIContextualAction(style: .normal, title: "Done") { _, _, isDone in
                StorageManager.shared.done(taskList, isComplete: true)
                tableView.reloadRows(at: [indexPath], with: .automatic)
                isDone(true)
            }
            editAction.backgroundColor = .orange
            doneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
            return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
        } else {
            let undoneAction = UIContextualAction(style: .normal, title: "Undone") { _, _, isDone in
                StorageManager.shared.done(taskList, isComplete: false)
                tableView.reloadRows(at: [indexPath], with: .automatic)
                isDone(true)
            }
            editAction.backgroundColor = .orange
            undoneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
            return UISwipeActionsConfiguration(actions: [undoneAction, editAction, deleteAction])

        }
        
        
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        guard let tasksVC = segue.destination as? TasksViewController else { return }
        let taskList = taskLists[indexPath.row]
        tasksVC.taskList = taskList
    }

    @IBAction func sortingList(_ sender: UISegmentedControl) {
        
        if sender.selectedSegmentIndex == 0 {
            self.taskLists = self.taskLists.sorted(byKeyPath: "date", ascending: false)
        } else if sender.selectedSegmentIndex == 1 {
            self.taskLists = self.taskLists.sorted(byKeyPath: "name")
        }
        tableView.reloadData()
    }
    
    @objc private func addButtonPressed() {
        showAlert()
    }
    
    private func createTempData() {
        if !UserDefaults.standard.bool(forKey: "done") {
            DataManager.shared.createTempData { [unowned self] in
                UserDefaults.standard.set(true, forKey: "done")
                tableView.reloadData()
            }
        }
    }
}

extension TaskListViewController {
    
    private func showAlert(with taskList: TaskList? = nil, completion: (() -> Void)? = nil) {
        let title = taskList != nil ? "Edit List" : "New List"
        let alert = UIAlertController.createAlert(withTitle: title, andMessage: "Please set title for new task list")
        
        alert.action(with: taskList) { [weak self] newValue in
            if let taskList = taskList, let completion = completion {
                StorageManager.shared.edit(taskList, newValue: newValue)
                completion()
            } else {
                self?.save(taskList: newValue)
            }
        }
        
        present(alert, animated: true)
    }
    
    private func save(taskList: String) {
        StorageManager.shared.save(taskList) { taskList in
            let rowIndex = IndexPath(row: taskLists.index(of: taskList) ?? 0, section: 0)
            tableView.insertRows(at: [rowIndex], with: .automatic)
        }
    }
}
