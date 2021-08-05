
import Foundation

final class OrderConfigurator {

    static func configure(_ viewController: OrderViewController) {
        let interactor = OrderInteractor()
        let presenter = OrderPresenter()
        let router = OrderRouter()

        viewController.interactor = interactor
        viewController.router = router

        interactor.presenter = presenter

        presenter.viewController = viewController
        presenter.router = router
        
        router.viewController = viewController
    }
}
