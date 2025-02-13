enum ImageItem {
    case card(WikiImageCard)
}

class SimpleImageDatasource: ImageDataSource {
    
    private(set) var imageItems: [ImageItem]
    
    init(imageItems: [ImageItem]) {
        self.imageItems = imageItems
    }
    
    func count() -> Int {
        imageItems.count
    }
    
    func imageItem(at index: Int) -> ImageItem {
        imageItems[index]
    }
}
