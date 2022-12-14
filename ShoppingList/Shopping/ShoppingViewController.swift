//
//  ShoppingViewController.swift
//  ShoppingList
//
//  Created by SeungYeon Yoo on 2022/08/22.
//
import UIKit
import SnapKit
import RealmSwift //Realm 1.


class ShoppingViewController: BaseViewController {
        
    var mainView = ShoppingView()
    
    let repository = UserShoplistRepository()
    
    var tasks: Results<UserShopList>! {
        //여러군데에서 테이블뷰 갱신코드 쓰지 않아도 되게끔 하는 코드
        didSet {
            mainView.listTableView.reloadData()
        }
    }
    
    //viewDidLoad보다 먼저 호출된다
    override func loadView() { //super.loadView 호출 금지
        self.view = mainView
        
        repository.resetLocalRealm()

        fetchRealm()
        print(tasks.count)
        mainView.listTableView.reloadData()
        //3. Realm 데이터를 정렬해 tasks에 담기
        tasks = repository.fetch()
    
        mainView.listTableView.delegate = self
        mainView.listTableView.dataSource = self
        mainView.listTableView.register(CustomTableViewCell.self, forCellReuseIdentifier: "CustomTableViewCell")
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        print("Realm is located at:", localRealm.configuration.fileURL!)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "정렬/필터링", style: .plain, target: self, action: #selector(seeMenu))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "백업/복원", style: .plain, target: self, action: #selector(goBackupButtonClicked))
    }
    @objc func goBackupButtonClicked() {
        let vc = BackupViewController()
        let navi = UINavigationController(rootViewController: vc)
        navi.modalPresentationStyle = .fullScreen
        self.present(navi, animated: true)
    }
    
    @objc func seeMenu() {
        let alert = UIAlertController(title: title, message: "선택하세요", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        let filter = UIAlertAction(title: "필터링", style: .default,  handler: { [self] alertAction in
            self.tasks = repository.fetchFilter()
        })
        let sortbyFav = UIAlertAction(title: "즐겨찾기순 정렬", style: .default, handler: { [self] alertAction in
            self.tasks = repository.fetchSort("favrorite")
        })
        let sortbyCheck = UIAlertAction(title: "할 일 기준 정렬", style: .default, handler: { [self] alertAction in
            self.tasks = repository.fetchSort("check")
        })
        alert.addAction(cancel)
        alert.addAction(filter)
        alert.addAction(sortbyFav)
        alert.addAction(sortbyCheck)
        self.present(alert, animated: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        print("appeared")
        repository.resetLocalRealm()

        fetchRealm()
        print(tasks.count)
        mainView.listTableView.reloadData()
    }
    
    func fetchRealm() {
        //3. Realm 데이터를 정렬해 tasks에 담기
        
        tasks = repository.fetch()
    }
    
    override func configure() {
        mainView.addButton.addTarget(self, action: #selector(addButtonClicked), for: .touchUpInside)
    }
    
    //realm create sample
    @objc func addButtonClicked() {
        repository.addItem()
        
        mainView.listTableView.reloadData()
    }
}

extension ShoppingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let task = tasks[indexPath.row]
        
        let cell = mainView.listTableView.dequeueReusableCell(withIdentifier: "CustomTableViewCell", for: indexPath) as! CustomTableViewCell
        cell.checkImage.image = task.check ? UIImage(systemName: "checkmark.square.fill") : UIImage(systemName: "checkmark.square")
        cell.shoppingImg.image = loadImageFromDocument(fileName: "\(tasks[indexPath.row].objectId).jpg")
        cell.listLabel.text = task.shoppingThing
        cell.favoriteButton.setImage(task.favorite ? UIImage(systemName: "star.fill") : UIImage(systemName: "star"), for: .normal)
        cell.checkBtnAction = { [unowned self] in
            repository.updateCheck(item: task)
                tableView.reloadData()
        }
        
        cell.favoriteBtnAction = { [unowned self] in
            print("favorite clicked")
            print(indexPath.row)
            repository.updateFavorite(item: task)
            self.fetchRealm()
            self.mainView.listTableView.reloadData()
        }
                       
        return cell
    }
    

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(#function)
        let vc = DetailViewController()
        let navi =  UINavigationController(rootViewController: vc)
        //2) 값 전달
        vc.data = tasks[indexPath.row]
        vc.titlelabel = tasks[indexPath.row].shoppingThing
        navi.modalPresentationStyle = .fullScreen
        self.present(navi, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .normal, title: "삭제")  { [self] action, view, completionHandler in
            print("favorite Button Clicked")
            repository.delete(item: self.tasks[indexPath.row])
            self.fetchRealm()
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    
    // MARK: - delete (swipe 시 delete)
    //    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    //
    //        if (editingStyle == .delete) {
    //
    //            try! localRealm.write {
    //                localRealm.delete(tasks[indexPath.row])
    //            }
    //
    //            tableView.reloadData()
    //        }
    //    }
}

