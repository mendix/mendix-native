import UIKit


typealias TapAction = ((_ gestureRecognizer: UITapGestureRecognizer) -> Void)

class TapGestureRecognizerHelper {
    private let window: UIWindow
    private var numberOfTouchesRequired: Int
    private var onTapAction: TapAction? = nil
    
    init(window: UIWindow, numberOfTouchesRequired: Int = 3, onTapAction: TapAction? = nil) {
        self.window = window
        self.numberOfTouchesRequired = numberOfTouchesRequired
        self.onTapAction = onTapAction
    }
    
    private var tapGestureRecognizer: UITapGestureRecognizer?
    
    @objc private func handleTapAction(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended && ReactAppProvider.isReactAppActive() == true , let onTapAction {
            onTapAction(gestureRecognizer)
        }
    }
    
    func attach() {
        if tapGestureRecognizer == nil {
            tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapAction(_:)))
            tapGestureRecognizer?.numberOfTouchesRequired = numberOfTouchesRequired
        }
        if let tapGestureRecognizer {
            window.addGestureRecognizer(tapGestureRecognizer)
        }
    }
    
    func remove() {
        if let tapGestureRecognizer {
            window.removeGestureRecognizer(tapGestureRecognizer)
        }
    }
}
