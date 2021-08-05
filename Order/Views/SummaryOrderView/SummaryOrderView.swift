

import UIKit

protocol SummaryOrderViewDelegate: AnyObject {
    func createOrderDidTouch()
    func heightDidUpdate(height: CGFloat)
}

final class SummaryOrderView: XibView {
    
    @IBOutlet private weak var warningLabel: UILabel!
    @IBOutlet private weak var warningsStackView: UIStackView!
    @IBOutlet private weak var createOrderView: UIView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var orderLabel: UILabel!
    @IBOutlet private weak var totalPriceLabel: UILabel!
    @IBOutlet private weak var productsLabel: UILabel!
    @IBOutlet private weak var productsPriceLabel: UILabel!
    @IBOutlet private weak var deliveryStackView: UIStackView!
    @IBOutlet private weak var deliveryLabel: UILabel!
    @IBOutlet private weak var deliveryPriceLabel: UILabel!
    @IBOutlet private weak var orderButton: UIButton!
    
    weak var delegate: SummaryOrderViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    @IBAction private func orderDidTouch(_ sender: Any) {
        delegate?.createOrderDidTouch()
    }
    
    func update(viewModel: OrderViewModel) {
        deliveryStackView.isHidden = viewModel.dileviryType != .delivery
        warningsStackView.isHidden = viewModel.warnings.isEmpty

        let warningsAttrText: NSMutableAttributedString = {
            var text = ""
            
            viewModel.warnings.forEach { item in
                text += "\n \(item.title)"
            }
            
            return text.getAttributedString()
        }()

        viewModel.warnings.forEach { warning in
            let color = warning.isBloked ? R.color.ssRed()! : R.color.yellowWarning()!
            warningsAttrText.apply(color: color, subString: warning.title)
        }

        warningLabel.attributedText = warningsAttrText
        
        productsPriceLabel.text = viewModel.productsPrice
        totalPriceLabel.text = viewModel.totalPrice
        deliveryPriceLabel.text = viewModel.deliveryPrice
        
        orderButton.isEnabled = viewModel.isEnableOrdeButton
        createOrderView.backgroundColor = viewModel.isEnableOrdeButton ? R.color.ssGreen() : R.color.ssLightGrey()?.withAlphaComponent(0.7)
        
        containerView.layoutIfNeeded()
        delegate?.heightDidUpdate(height: containerView.frame.height)
    }
}

private extension SummaryOrderView {
    func setup() {
        containerView.setupCornerAndShadow(corner: 4)
        
        createOrderView.backgroundColor = R.color.ssGreen()
        
        orderButton.setTitle("", for: .normal)
        
        totalPriceLabel.font = R.font.latoBold(size: 17)
        totalPriceLabel.textColor = UIColor.white
        
        deliveryPriceLabel.font = R.font.latoMedium(size: 15)
        deliveryPriceLabel.textColor = UIColor.black.withAlphaComponent(0.5)
        
        productsPriceLabel.font = R.font.latoMedium(size: 15)
        productsPriceLabel.textColor = UIColor.black.withAlphaComponent(0.5)
        
        orderLabel.text = OrderViewModel.createOrderLabel
        orderLabel.font = R.font.latoBold(size: 17)
        orderLabel.textColor = UIColor.white
        
        deliveryLabel.text = OrderViewModel.deliveryLabel
        deliveryLabel.font = R.font.latoMedium(size: 15)
        deliveryLabel.textColor = UIColor.black.withAlphaComponent(0.5)
        
        productsLabel.text = OrderViewModel.productsPriceLabel
        productsLabel.font = R.font.latoMedium(size: 15)
        productsLabel.textColor = UIColor.black.withAlphaComponent(0.5)
        
        warningLabel.numberOfLines = 0
        warningLabel.font = R.font.latoRegular(size: 15)
        warningLabel.textColor = .red
    }

}
