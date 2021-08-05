
import UIKit

protocol OrderDisplayLogic: AnyObject {
    func displayOrder(viewModel: OrderViewModel, viewModels: [[AnyItemViewModel]], needToReload: Bool)
    func displayCreateOrder()
    func displayWarning(message: String)
}

final class OrderViewController: UIViewController {
    
    @IBOutlet private weak var summaryView: SummaryOrderView!
    @IBOutlet private weak var tableView: UITableView!
    
    private var heightSummaryConstraint: NSLayoutConstraint?
    
    private var dataSource = TableModelDataSource<AnyItemViewModel>([])
    private var viewModel = OrderViewModel()
    
    var interactor: (OrderBusinessLogic & RestaurantsDataStore)?
    var router: OrderRoutingLogic?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        OrderConfigurator.configure(self)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        OrderConfigurator.configure(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSubviews()
        interactor?.prepareOrder()
    }
}

// MARK: - OrderDisplayLogic

extension OrderViewController: OrderDisplayLogic {
    
    func displayOrder(viewModel: OrderViewModel, viewModels: [[AnyItemViewModel]], needToReload: Bool) {
        self.viewModel = viewModel
        dataSource.update(rowsAndSections: viewModels)
        needToReload ? tableView.reloadData() : nil
        
        summaryView.update(viewModel: viewModel)
    }
    
    func displayCreateOrder() {
        router?.routeToSuccessOrder()
    }
    
    func displayWarning(message: String) {
        UIAlertController.showOkWarning(message: message, on: self)
    }
}

// MARK: - Private Methods

private extension OrderViewController {
    func setupSubviews() {
        title = RStrings.orderInfo()
        
        setupTableView()
        
        summaryView.delegate = self
        heightSummaryConstraint = summaryView.heightAnchor.constraint(equalToConstant: 100)
        heightSummaryConstraint?.isActive = true
    }
    
    func setupTableView() {
        tableView.setupTableView(self,
                                 cells: [ProductOrderTableViewCell.self,
                                         RestaurantsOrderTableViewCell.self,
                                         NoticeOrderTableViewCell.self,
                                         DeliveryTypeOrderTableViewCell.self,
                                         DateOrderTableViewCell.self,
                                         AddressOrderTableViewCell.self,
                                         ItemsOrderTableViewCell.self,
                                         PhoneNameTableViewCell.self,
                                         AddressPreviewTableViewCell.self])
        tableView.contentInset.bottom = 20
        tableView.backgroundColor = .clear
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension OrderViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        dataSource.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.numberOfItems(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = dataSource[indexPath].model
        let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.reuseIdentifier,
                                                 for: indexPath)
        (cell as? CellViewModelConfigurable)?.configure(with: viewModel)
        (cell as? CellButtonActionTriggerable)?.actionHandler = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewModel = dataSource[indexPath].model
        if viewModel is AddressOrderItem {
            router?.routeToAddress()
        }
    }
}

// MARK: - CartButtonViewDelegate

extension OrderViewController: CartButtonViewDelegate {
    func cartButtonDidTouch() {
        interactor?.createOrder()
    }
}

// MARK: - RestaurantsOrderPanViewControllerDelegate

extension OrderViewController: RestaurantsOrderPanViewControllerDelegate {
    func didSelectRestaurant(_ restaurant: Restaurant) {
        interactor?.selectedRestaurant = restaurant
    }
}

// MARK: - SummaryOrderViewDelegate

extension OrderViewController: SummaryOrderViewDelegate {
    func heightDidUpdate(height: CGFloat) {
        heightSummaryConstraint?.constant = height
        self.view.layoutIfNeeded()
    }
    
    func createOrderDidTouch() {
        interactor?.createOrder()
    }
}

// MARK: - CellButtonActionHandler

extension OrderViewController: CellButtonActionHandler {
    func triggerAction(_ action: CellActionable) {
        guard let action = action as? EditOrderType else {
            return
        }
        interactor?.editOrder(type: action)
    }
}
