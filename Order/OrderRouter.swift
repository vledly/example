
import UIKit

protocol OrderRoutingLogic {
    func routeToRestaurants()
    func routeToAddress()
    func routeToSuccessOrder()
    func routeToDistricts()
}

final class  OrderRouter {
    
    weak var viewController: OrderViewController?
    
}

// MARK: - OrderRoutingLogic

extension  OrderRouter: OrderRoutingLogic {
    func routeToRestaurants() {
        guard
            let vc = R.storyboard.restaurants.restaurantsOrderPanViewController() else {
            return
        }
        vc.delegate = viewController
        viewController?.presentPanModal(vc)
    }
    
    func routeToAddress() {
        guard
            let vc = R.storyboard.address.addressViewController(),
            let addressDestinationInteractor = vc.interactor as? AddressObserver,
            let selfAddressInteractor = viewController?.interactor as? AddressObserver,
            var districtsDestinationInteractor = vc.interactor as? DistrictsDataStore,
            let selfDistrictsInteractor = viewController?.interactor as? DistrictsDataStore
        else {
            return
        }
        addressDestinationInteractor.addressObserver = selfAddressInteractor.addressObserver
        districtsDestinationInteractor.districts = selfDistrictsInteractor.districts
        
        vc.modalPresentationStyle = .overFullScreen
        
        viewController?.present(vc, animated: true, completion: nil)
    }
    
    func routeToSuccessOrder() {
        guard
            let vc = R.storyboard.successOrder.successOrderViewController() else {
            return
        }
        viewController?.navigationController?.pushViewController(vc, animated: true)
    }
    
    func routeToDistricts() {
        guard
            let vc = R.storyboard.listPicker.listPickerViewController(),
            let destinationInteractor = vc.interactor as? ListPickerObserver,
            let selfInteractor = viewController?.interactor as? ListPickerObserver
        else {
            return
        }
        destinationInteractor.listPickerObserver = selfInteractor.listPickerObserver
        viewController?.presentPanModal(vc)
    }
}
