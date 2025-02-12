import UIKit

class ViewControllerV1: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    // Инициализируем UICollectionView
    var collectionView: UICollectionView!
    
    // Данные для коллекции (например 5 элементов)
    let data = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Создаем UICollectionViewFlowLayout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: view.bounds.width, height: view.bounds.height)  // Ячейки на весь экран
        layout.minimumLineSpacing = 0  // Убираем промежутки между ячейками
        layout.sectionInset = .zero
        
        // Инициализация UICollectionView с layout
        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        
        // Регистрация ячейки
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        
        // Добавление в иерархию
        self.view.addSubview(collectionView)
        
        // Прокручиваем к начальной ячейке (или какой-то конкретной)
        let initialIndexPath = IndexPath(item: 0, section: 0)
        collectionView.scrollToItem(at: initialIndexPath, at: .centeredHorizontally, animated: false)
    }
    
    // MARK: - UICollectionView DataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        
        // Настроим внешний вид ячейки
        cell.contentView.backgroundColor = .systemBlue
        let label = UILabel(frame: cell.contentView.bounds)
        label.text = data[indexPath.item]
        label.textAlignment = .center
        label.textColor = .white
        cell.contentView.addSubview(label)
        
        return cell
    }
    
    // MARK: - UICollectionView Delegate
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleItems = collectionView.indexPathsForVisibleItems
        guard let firstVisibleItem = visibleItems.first else { return }
        
        // Если прокрутка достигла конца, то переходим в начало
        if firstVisibleItem.item == data.count - 1 {
            let newIndexPath = IndexPath(item: 0, section: 0)
            collectionView.scrollToItem(at: newIndexPath, at: .centeredHorizontally, animated: false)
        }
        // Если прокрутка достигла начала, то переходим в конец
        else if firstVisibleItem.item == 0 {
            let newIndexPath = IndexPath(item: data.count - 1, section: 0)
            collectionView.scrollToItem(at: newIndexPath, at: .centeredHorizontally, animated: false)
        }
    }
    
    // Можно использовать этот метод для того, чтобы начать прокрутку с какой-то конкретной ячейки
    func scrollToSpecificItem(at index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}
