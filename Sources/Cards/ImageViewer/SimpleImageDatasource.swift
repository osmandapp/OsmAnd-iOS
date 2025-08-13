enum ImageItem {
    case card(WikiImageCard)
}

final class SimpleImageDatasource: ImageDataSource {
    
    private(set) var imageItems: [ImageItem]
    
    var placeholderImage: UIImage?
    
    init(imageItems: [ImageItem], placeholderImage: UIImage?) {
        self.imageItems = imageItems
        self.placeholderImage = placeholderImage
    }
    
    func count() -> Int {
        imageItems.count
    }
    
    func imageItem(at index: Int) -> ImageItem {
        imageItems[index]
    }
}
