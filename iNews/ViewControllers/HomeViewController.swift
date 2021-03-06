//
//  HomeViewController.swift
//  iNews
//
//  Created by Allan on 04/10/18.
//  Copyright © 2018 Allan Pacheco. All rights reserved.
//

import UIKit

final class HomeViewController: BaseViewController {

    @IBOutlet weak private var tableView: UITableView!
    
    private var news = [News]()
    private var selectedNews: News?
    private var refreshControl = UIRefreshControl()
    private var hasData: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getNews()
    }
    
    override func setupInterface() {
        super.setupInterface()
        currentTitle = "HOME"
        tableView.registerCells(forFieldTypes: [.featuredNews, .newsList])
        tableView.tableFooterView = UIView(frame: .zero)
        refreshControl.addTarget(self, action: #selector(self.getNews), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        //3D Touch
        if traitCollection.forceTouchCapability == .available{
            registerForPreviewing(with: self, sourceView: tableView)
        }
    }
    
    @objc private func getNews(){
        
        guard reachability.connection != .none else{
            tableView.setEmpty(for: .offline, hasData: false)
            self.hasData = false
            return
        }
        
        refreshControl.beginRefreshing()
        ServiceNews.getNewsForCover { [unowned self](data, error) in
            self.refreshControl.endRefreshing()
            if let error = error{
                self.showMessage("Ops... Algo deu errado", mensagem: error.localizedDescription, completion: nil)
            }
            else{
                self.news = data
                self.hasData = !self.news.isEmpty
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func showNews(news: News){
        guard let newsVC = storyboard?.instantiateViewController(withIdentifier: "newsVC") as? NewsViewController else { return }
        newsVC.news = news
        self.navigationController?.pushViewController(newsVC, animated: true)
    }
}

//MARK: - TableView DataSource/Delegate

extension HomeViewController: UITableViewDataSource, UITableViewDelegate{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let type: UITableView.EmptyListType = reachability.connection == .none ? .offline : .news
        tableView.setEmpty(for: type, hasData: self.hasData)
        return news.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = indexPath.row == 0 ? "FeaturedNewsTableViewCell" : "NewsListTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? NewsListTableViewCell else { return UITableViewCell()}
        cell.setup(with: news[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.row == 0{
            if news[indexPath.row].hasImage{
                if UIScreen.main.bounds.size.width < 321.0{
                    return 193.0
                }
                else if UIScreen.main.bounds.size.width < 376{
                    return 226.0
                }
                else if UIScreen.main.bounds.size.width < 415.0{
                    return 250
                }
                else if UIScreen.main.bounds.size.width < 769.0{
                    return 462
                }
                else if UIScreen.main.bounds.size.width < 1025.0{
                    return 617
                }
            }
        }
        else{
            return 81.0
        }
        
        return 81.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.showNews(news: news[indexPath.row])
    }
}

//MARK: - PreviewingDelegate
extension HomeViewController: UIViewControllerPreviewingDelegate{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRow(at: location), let newsVC = storyboard?.instantiateViewController(withIdentifier: "previewNewsVC") as? PreviewNewsViewController else{
            return nil
        }
        
        selectedNews = self.news[indexPath.row]
        newsVC.currentNews = selectedNews
        newsVC.preferredContentSize = CGSize(width: 0.0, height: 400.0)
        previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
        return newsVC
        
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let news = selectedNews else { return }
        self.showNews(news: news)
    }
}
