
import Foundation

protocol OrderBusinessLogic {
    func prepareOrder()
    func createOrder()
    func editOrder(type: EditOrderType)
}

final class OrderInteractor: RestaurantsDataStore, DistrictsDataStore {
    
    private let network: NetworkService = NetworkService()
    
    var presenter: (OrderPresentationLogic & StatePresentationLogic)?

    // MARK: - AddressObserver
    var addressObserver: Variable<Address>?
    
    // MARK: - RestaurantsDataStore
    var selectedRestaurant: Restaurant?
    
    // MARK: - DistrictsDataStore
    var districts: [DistrictModel] = []
    var selectedDistrict: DistrictModel?

    private var order: Order?
    
    private let service: SCFBService
    private let userDefaults: UserDefaults
    
    init() {
        service = SCFBService()
        userDefaults = .standard
            
        addressObserver = Variable<Address>()
        addressObserver?.addObserver(observer: self)
    }
    
    deinit {
        addressObserver?.removeObserver(observer: self)
        addressObserver = nil
    }
}

// MARK: - AddressObserver

extension OrderInteractor: AddressObserver {
    func update<Value>(with newValue: Value) {
        if let address = newValue as? Address {
            editOrder(type: .address(address))
            return
        }
    }
}

// MARK: - OrderBusinessLogic

extension OrderInteractor: OrderBusinessLogic {
    
    func prepareOrder() {
        presenter?.presentLoadingState()

        
        let price = Order.Price(productsPrice: CartService.shared.getTotalPrice())
        let products = CartService.shared.products.compactMap(Order.Product.init)

        let order = Order(price: price,
                          products: products,
                          deliveryType: .pickup,
                          status: .new)
        self.order = order
        self.order?.address = userDefaults.lastAddress

        DispatchQueue.global().async { [weak self] in

            var hasError = false
            let group = DispatchGroup()

            group.enter()
            self?.service.fetchRequest(.info) { (result: Result<Info, SCError>) in
                switch result {
                case .success(let response):
                    self?.handleInfo(response)
                    break
                case .failure:
                    hasError = true
                }
                group.leave()
            }
            
            group.enter()
            self?.service.fetchRequest(.resturants) { (result: Result<[Restaurant], SCError>) in
                switch result {
                case .success(let response):
                    self?.handleRestaurants(response)
                    break
                case .failure:
                    hasError = true
                }
                group.leave()
            }
            
            group.notify(queue: .main) {
                guard !hasError else {
                    return
                }
                
                self?.order?.phone = self.userDefaults.userPhone
                self?.order?.name = self.userDefaults.userName
                
                self?.addressObserver?.updateValueWithoutNotify(self.order?.address)

                self?.presentOrder()
            }
        }
    }
    
    func createOrder() {
        guard var order = order else {
            return
        }
        let errors = validateOrder(order)
        
        guard errors.isEmpty else {
            presenter?.presentValidateError(types: errors)
            return
        }
        
        presenter?.presentLoadingState()
        
        switch order.deliveryType {
        case .delivery:
            order.restaurant = nil
        case .pickup:
            order.address = nil
        }
        
        if order.orderDate == nil {
            order.orderDate = createAsapDate()?.converToTimestamp()
        }
        order.createdDate = Date().converToTimestamp()
        
        service.sendRequest(.orders, request: order) { [weak self] response in
            switch response {
            case .success(_):
                self?.successOrder(order: order)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func editOrder(type: EditOrderType) {
        guard var order = order else {
            return
        }

        var needToReload = true
        
        switch type {
        case .deliveryType(let value):
            if case .delivery = value, !Configurations.shared.deliveryIsEnable {
                presenter?.presentWarning(type: .delivery)
                return
            }
            order.deliveryType = value
        case .date(let value):
            order.orderDate = value.converToTimestamp()
        case .address(let value):
            selectedDistrict = districts.first { $0.title == value?.district }
            order.address = value
            needToReload = true
        case .restaurant(let value):
            order.restaurant = value
        case .notice(let value):
            order.notice = value
        case .phone(let value):
            order.phone = value
        case .name(let value):
            order.name = value
        }
        var price = Order.Price(productsPrice: CartService.shared.getTotalPrice())
        if order.deliveryType == .delivery {
            price.deliveryPrice = selectedDistrict?.deliveryPrice ?? 0
            if
                let extraDeliveryPrice = selectedDistrict?.extraDeliveryPrice,
                let minOrderPrice = selectedDistrict?.minOrderPrice,
                minOrderPrice > CartService.shared.getTotalPrice()
            {
                price.deliveryPrice = extraDeliveryPrice
            }
        }
        order.price = price
        
        self.order = order
        presentOrder(needToReload: needToReload)
    }
}

// MARK: - Private Methods

private extension OrderInteractor {
    func presentOrder(needToReload: Bool = true) {
        guard let order = order else {
            return
        }
        let response = OrderPresentableResponse(order: order,
                                                restaurant: selectedRestaurant,
                                                district: selectedDistrict,
                                                needToReload: needToReload)
        presenter?.presentOrder(response: response)
    }
    
    func successOrder(order: Order) {
        userDefaults.userPhone = order.phone
        userDefaults.userName = order.name
        if let address = order.address {
            userDefaults.lastAddress = address
        }
        
        let request = OrderMessage(order: order)
        network.request(.sendMessage(request)) { [ weak self ] (result: Result<EmptyResponse, Error>) in
            switch result {
            case .success(_):
                CartService.shared.emptyCart()
                self?.presenter?.presentCreateOrder()
            case .failure(_):
                break
            }
        }
    }
    
    func handleInfo(_ response: Info) {
        districts = response.delivery.districts.filter {
            $0.isAvailable
        }.compactMap(DistrictModel.init)
        selectedDistrict = districts.first { $0.title == order?.address?.district }
    }
    
    func handleRestaurants(_ response: [Restaurant]) {
        guard let restaurant = response.first else {
            return
        }
        selectedRestaurant = restaurant
    }
    
    func validateOrder(_ order: Order) -> [OrderDataFlow.ValidateErrorType] {
        var errors: [OrderDataFlow.ValidateErrorType] = []
        
        if !validatePhone() {
            errors.append(.phone)
        }
        
        if order.name == nil || order.name?.isEmpty == true {
            errors.append(.name)
        }

        if
            order.deliveryType == .delivery &&
            (order.address == nil ||
            order.address?.validate() == false)
        {
            errors.append(.address)
        }
        
        if !validateTime() {
            errors.append(.time)
        }
        
        return errors
    }
    
    func validatePhone() -> Bool {
        PhoneWorker.isValidate(order?.phone)
    }
    
    func validateTime() -> Bool {
        guard
            let deliveryType = order?.deliveryType,
            let selectedTime = order?.orderDate?.dateValue(),
            let startTimeMin = selectedRestaurant?.startTime,
            let endTimeMin   = selectedRestaurant?.endTime,
            let preorderTime = selectedRestaurant?.preorderTime,
            let deliveryTime = selectedRestaurant?.deliveryTime
        else {
            return true
        }
        let calendar = Calendar.current
        
        let startOfSelectedDay = calendar.startOfDay(for: selectedTime).localTime()
        let selectedTimeMin = startOfSelectedDay.minutesToDate(selectedTime.localTime())

        let cookingTime: Int
        switch deliveryType {
        case .delivery:
            cookingTime = deliveryTime
        case .pickup:
            cookingTime = preorderTime
        }
        if
            startTimeMin < selectedTimeMin - cookingTime,
            endTimeMin > selectedTimeMin + cookingTime
        {
            return true
        } else {
            return false
        }
    }

    func createAsapDate() -> Date? {
        guard
            let preorderTime = selectedRestaurant?.preorderTime,
            let deliveryTime = selectedRestaurant?.deliveryTime,
            let type = order?.deliveryType
        else {
            return nil
        }
        let minimumDate: Date
        switch type {
        case .delivery:
            minimumDate = Date().addingTimeInterval(TimeInterval(deliveryTime * 60))
        case .pickup:
            minimumDate = Date().addingTimeInterval(TimeInterval(preorderTime * 60))
        }
        return minimumDate
    }

}
