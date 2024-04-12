//
//  ViewController.swift
//  KinopoiskListApp
//
//  Created by Флоранс on 13.03.2024.
//

import UIKit
import AlamofireImage
import SkeletonView

final class SearchViewController: UIViewController {
    
    // MARK: - Properties
    private var collectionView: UICollectionView!
    private let sectionHeaderView = SectionHeaderView()
    
    private var searchController: UISearchController!
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    private var kpCollections: [KPList] = []
    private var persons: [Person] = []
    private var categoryList: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupSearchController()
        setupCollectionView()
        addSkeletonAnimation()
        fetchData()
    }
    
    // MARK: - Setup the Collection View
    private func setupCollectionView() {
        collectionView = UICollectionView(
            frame: view.bounds,
            collectionViewLayout: createCompositionalLayout()
        )
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        collectionView.backgroundColor = #colorLiteral(red: 0.968627451, green: 0.9725490196, blue: 0.9921568627, alpha: 1)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(
            KPListCell.self,
            forCellWithReuseIdentifier: KPListCell.reuseId
        )
        collectionView.register(
            KPItemCell.self,
            forCellWithReuseIdentifier: KPItemCell.reuseId
        )
        collectionView.register(
            CategoryCell.self,
            forCellWithReuseIdentifier: CategoryCell.reuseId
        )
        collectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseId
        )
        
        view.addSubview(collectionView)
    }
    
    // MARK: - Setup the Search Controller and Scope Bar
    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.definesPresentationContext = true
        searchController.searchBar.placeholder = "Фильмы, персоны, сериалы"
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        searchController.searchBar.scopeButtonTitles = ["Все результаты", "Онлайн-кинотеатр"]
        searchController.searchBar.delegate = self
    }
    
    // MARK: - Setup the Navigation Bar
    private func setupNavigationBar() {
        navigationController?.navigationBar.tintColor = .black
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    // MARK: - Setup the SkeletonView
    private func addSkeletonAnimation() {
        SkeletonAppearance.default.skeletonCornerRadius = 4
        collectionView.isSkeletonable = true
        collectionView.showAnimatedGradientSkeleton()
    }
}

// MARK: - Setup UICVCompositionalLayout
extension SearchViewController {
    private func createCompositionalLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment)
            -> NSCollectionLayoutSection? in
            switch sectionIndex {
            case 0:
                return self.createSectionForKPCollectionsOrPersons()
            case 1:
                return self.createSectionForCategories()
            default:
                return self.createSectionForKPCollectionsOrPersons()
            }
        }
        //layout.collectionView?.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0)
    
        return layout
    }
    
    func createSectionForKPCollectionsOrPersons() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(190))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(135), heightDimension: .estimated(190))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 10, bottom: 10, trailing: 10)
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(20))
        let headerElement = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, 
                                                                        elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [headerElement]
        
        return section
    }
    
    func createSectionForCategories() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(80), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let innerGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(35))
        let innerGroup = NSCollectionLayoutGroup.horizontal(layoutSize: innerGroupSize, subitems: [item])
        innerGroup.interItemSpacing = .fixed(10)
       
        let nestedGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(90))
        let nestedGroup = NSCollectionLayoutGroup.vertical(layoutSize: nestedGroupSize, subitems: [innerGroup])
        nestedGroup.interItemSpacing = .fixed(10)
        
        let section = NSCollectionLayoutSection(group: nestedGroup)
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 10, bottom: 10, trailing: 10)
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(20))
        let headerElement = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [headerElement]
        
        return section
    }
    
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension SearchViewController: SkeletonCollectionViewDataSource, SkeletonCollectionViewDelegate {
    func numSections(in collectionSkeletonView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, prepareCellForSkeleton cell: UICollectionViewCell, at indexPath: IndexPath) {
        cell.isSkeletonable = true
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView,
        cellIdentifierForItemAt indexPath: IndexPath) -> SkeletonView.ReusableCellIdentifier {
        switch indexPath.section {
        case 0:
            return KPListCell.reuseId
        case 1:
            return CategoryCell.reuseId
        default:
            return KPItemCell.reuseId
        }
    }
    
    func collectionSkeletonView(
        _ skeletonView: UICollectionView,
        supplementaryViewIdentifierOfKind: String,
        at indexPath: IndexPath
    ) -> ReusableCellIdentifier? {
        
        return SectionHeaderView.reuseId
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return kpCollections.count
        case 1:
            return categoryList.count
        default:
            return persons.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: KPListCell.reuseId,
              for: indexPath
            ) as? KPListCell
            else {
                return UICollectionViewCell()
            }
            //cell.sectionKind = SectionKind.collections
            cell.hideSkeleton()
            cell.configure(with: kpCollections[indexPath.item])
            return cell
        case 1:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CategoryCell.reuseId,
                for: indexPath
            ) as? CategoryCell else {
                return UICollectionViewCell()
            }
            cell.hideSkeleton()
            cell.configure(with: categoryList[indexPath.item])
            return cell
        default:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: KPItemCell.reuseId,
              for: indexPath) as? KPItemCell
            else {
                return UICollectionViewCell()
            }
            //cell.sectionKind = SectionKind.persons
            cell.hideSkeleton()
            cell.configure(with: persons[indexPath.item])
            return cell
        }
    }
        
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard let sectionHeaderView = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseId,
            for: indexPath
        ) as? SectionHeaderView else {
            return UICollectionReusableView()
        }
        
        switch indexPath.section {
        case 0:
            sectionHeaderView.title.text = "Советуем посмотреть"
        case 1:
            sectionHeaderView.title.text = "Категории"
        default:
            sectionHeaderView.title.text = "Родились сегодня"
        }
        
        return sectionHeaderView
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            //let vc = TestSkeletonViewController()
            let vc = MoviesByKPListViewController()
            //let vc = MoviesTableViewController()
            vc.fetchMovies(from: kpCollections[indexPath.item])
            navigationController?.pushViewController(vc, animated: false)
        case 2:
            let vc = PersonDetailViewController()
            vc.setupPersonInfo(with: persons[indexPath.item])
            navigationController?.pushViewController(vc, animated: false)
        default:
            break
        }
    }
}


// MARK: - UISearchResultsUpdating
extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        print("search started")
    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print("scope selection started")
    }
}

// MARK: - Networking
extension SearchViewController {
    private func getBirthdayPersons(of persons: [Person]) -> [Person] {
        let personBirthdayList = persons.filter({ person in
            person.birthdayInFormat == Date().formatString() && person.death == nil
        })
        return personBirthdayList //Array(personBirthdayList.prefix(10))
    }
    
    private func fetchData() {
        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        print("GetCollections starting...")
        NetworkingManager.shared.fetchData(type: KPList.self, url: Links.getCollectionsUrl.rawValue) { [unowned self] result in
            switch result {
            case .success(let value):
                self.kpCollections = value
                print("Collections fetched")
            case .failure(let error):
                print(error)
            }
            dispatchGroup.leave()
            print("GetCollections finishing...")
        }
        
        dispatchGroup.enter()
        print("GetPersons starting...")
        NetworkingManager.shared.fetchData(type: Person.self, url: Links.getPersonsURL.rawValue) { [unowned self] result in
            switch result {
            case .success(let value):
                persons = getBirthdayPersons(of: value)
                print("Persons fetched")
            case .failure(let error):
                print(error)
            }
            dispatchGroup.leave()
            print("GetPersons finishing...")
        }
        
        print("Notify starting...")
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.categoryList = DataManager.shared.getCategories()
            self?.collectionView.stopSkeletonAnimation()
            self?.collectionView.hideSkeleton(reloadDataAfter: true, transition: .crossDissolve(0.25))
            print("Notify finishing...")
        }
        
    }
}
    
