

import Foundation

protocol OrderPresentationLogic {
    func presentOrder(response: OrderPresentableResponse)
    func presentCreateOrder()
    func presentWarning(type: OrderDataFlow.WarningType)
    func presentValidateError(types: [OrderDataFlow.ValidateErrorType])
}

final class OrderPresenter: StatePresentationLogic {

    var router: OrderRoutingLogic?
    weak var viewController: (OrderDisplayLogic & StateViewPresentable)?
    
    // MARK: - StatePresentationLogic
    var stateViewPresenter: StateViewPresentable? {
        viewController
    }
}

// MARK: - OrderPresentationLogic

extension OrderPresenter: OrderPresentationLogic {
    
    func presentOrder(response: OrderPresentableResponse) {
        removeState()
        
        var viewModel = OrderViewModel()
        viewModel.dileviryType = response.order.deliveryType
        
        viewModel.deliveryPrice = response.order.price.deliveryPrice?.asRub ?? ""
        viewModel.productsPrice = response.order.price.productsPrice.asRub
        viewModel.totalPrice = response.order.price.totalPrice.asRub
        
        viewModel.warnings = createWarnings(response: response)
        
        viewModel.isEnableOrdeButton = !viewModel.warnings.contains {
            $0.isBloked
        }
        
        let viewModels = createViewModels(response: response)
        
        viewController?.displayOrder(viewModel: viewModel,
                                     viewModels: viewModels,
                                     needToReload: response.needToReload)
    }
    
    func presentCreateOrder() {
        removeState()
        
        viewController?.displayCreateOrder()
    }
    
    func presentWarning(type: OrderDataFlow.WarningType) {
        viewController?.displayWarning(message: type.message)
    }

    func presentValidateError(types: [OrderDataFlow.ValidateErrorType]) {
        let message: String = types.compactMap({ $0.message }).joined(separator: "\n")
        viewController?.displayWarning(message: message)
    }
}

// MARK: - Private Methods

private extension OrderPresenter {
    func createViewModels(response: OrderPresentableResponse) -> [[AnyItemViewModel]] {
        OrderItemType.allCases.compactMap { type in
            switch type {
            case .orderType:
                return [DeliveryTypeOrderItem(dileviryType: response.order.deliveryType,
                                              isEnableDelivery: Configurations.shared.deliveryIsEnable).asAnyItem]
            case .restaurant:
                guard
                    response.order.deliveryType == .pickup,
                    let restaurant = response.restaurant
                else {
                    return nil
                }
                return [RestaurantOrderItem(restaurant: restaurant).asAnyItem]
            case .address:
                guard response.order.deliveryType == .delivery else {
                    return nil
                }
                let action: (() -> ()) = { [weak self] in
                    self?.router?.routeToDistricts()
                }
                return [AddressOrderItem(address: response.order.address ?? Address(),
                                         disrtictRouteAction: action).asAnyItem]
            case .phone:
                return [PhoneOrderItem(name: response.order.name,
                                       phone: response.order.phone,
                                       isEditable: true).asAnyItem]
            case .date:
                let dateHandler = handleDate(response: response)
                return [DateOrderItem(selectedDate: dateHandler.selectedDate,
                                      minimumDate: dateHandler.minimumDate).asAnyItem]
            case .notice:
                return [NoticeOrderItem(comment: response.order.notice ?? "").asAnyItem]
            case .titleProducts:
                return [TitleProductsOrderItem().asAnyItem]
            case .product:
                return CartService.shared.products.compactMap { product in
                    ProductOrderItem(cartProduct: product).asAnyItem
                }
            }
        }
    }
    
    func createAddressTitle(_ address: Address?) -> String? {
        guard
            let street = address?.street,
            let house = address?.house else {
            return nil
        }
        let title = "\(street), \(house)"
        return title
    }
    
    func createWarnings(response: OrderPresentableResponse) -> [OrderViewModel.Warning] {
        
        var warnings: [OrderViewModel.Warning] = []
        
        if
            let restaurant = response.restaurant
        {
            let startOrderTime = restaurant.startOrderTime
            let endOrderTime = restaurant.endOrderTime
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date()).localTime()
            let minutesToDate = startOfToday.minutesToDate(Date().localTime())
            
            if minutesToDate < startOrderTime || minutesToDate > endOrderTime {
                let warning = OrderViewModel.Warning(title: "Заказы принимаются с \(startOrderTime.minutesAsTime) до \(endOrderTime.minutesAsTime)",
                                                     isBloked: true)
                warnings.append(warning)
            }
        }
        
        switch response.order.deliveryType {
        case .delivery:
            
            if
                let district = response.district,
                district.minOrderPrice > response.order.price.productsPrice
            {
                if let _ = district.extraDeliveryPrice {
                    let deliveryPrice = district.deliveryPrice == 0 ? "бесплатная" : district.deliveryPrice.asRub
                    let warning = OrderViewModel.Warning(title: "\(district.title). При заказе от \(district.minOrderPrice.asRub) доставка \(deliveryPrice)",
                                                         isBloked: false)
                    warnings.append(warning)
                } else {
                    let warning = OrderViewModel.Warning(title: "\(district.title). Вы можете оформить доставку при заказе от \(district.minOrderPrice.asRub)",
                                                         isBloked: true)
                    warnings.append(warning)
                }
            }
            
        case .pickup:
            break
        }
        
        return warnings
    }

    func handleDate(response: OrderPresentableResponse) -> (minimumDate: Date, selectedDate: String) {
        let deliveryType = response.order.deliveryType
        let preorderTime = response.restaurant?.preorderTime ?? 30
        let deliveryTime = response.restaurant?.deliveryTime ?? 60

        var selectedDate: String
        let minimumDate: Date
        
        switch deliveryType {
        case .delivery:
            minimumDate = Date().addingTimeInterval(TimeInterval((deliveryTime * 60) + 60))
            selectedDate = "Через \(deliveryTime) мин"
        case .pickup:
            minimumDate = Date().addingTimeInterval(TimeInterval((preorderTime * 60) + 60))
            selectedDate = "Через \(preorderTime) мин"
        }
        
        if let selectedTime = response.order.orderDate?.dateValue() {
            let formatter = DateFormatter()
            formatter.dateFormat = DateFormatType.ddMMMHHmm.rawValue
            selectedDate = formatter.string(from: selectedTime)
        }
        
        return (minimumDate, selectedDate)
    }
}
