
import Foundation

struct OrderViewModel {
    
    struct Warning {
        let title: String
        let isBloked: Bool
    }
    
    static let commentLabel = "Комментарий"
    static let restaurantLabel = "Рестаран"
    static let dateLabel = "Время заказа"
    static let addressLabel = "Адрес"
    static let itemsOrderLabel = "Состав заказа:"
    static let deliveryLabel = "Доставка"
    static let productsPriceLabel = "Сумма товаров"
    static let createOrderLabel = "Заказать"
    static let phoneWarningLabel = "После подтверждения заказа наш оператор свяжется с вами для уточнения деталей"
    
    var dileviryType: DeliveryType = .pickup
    
    var isEnableDelivery = false
    
    var deliveryPrice: String = ""
    var productsPrice: String = ""
    var totalPrice  : String = ""
    
    var warnings: [Warning] = []
    
    var isEnableOrdeButton = false

}

enum EditOrderType: CellActionable {
    case deliveryType(DeliveryType)
    case date(Date)
    case address(Address?)
    case restaurant(String)
    case notice(String)
    case phone(String)
    case name(String)
}
