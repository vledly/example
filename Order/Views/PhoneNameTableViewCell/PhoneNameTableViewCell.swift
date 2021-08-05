
import UIKit

protocol PhoneNamePredentable {
    var name: String? { get set }
    var phone: String? { get set }
    var isEditable: Bool { get set }
}

final class PhoneNameTableViewCell: UITableViewCell, CellButtonActionTriggerable {
    
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var phoneTextField: PhoneTextField!
    @IBOutlet private weak var descriptionLabel: UILabel!
    
    // MARK: - CellButtonActionTriggerable
    
    weak var actionHandler: CellButtonActionHandler?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
}

private extension PhoneNameTableViewCell {
    func setup() {
        selectionStyle = .none
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        containerView.layer.cornerRadius = 4
        
        titleLabel.text = RStrings.client()
        titleLabel.font = SPFonts.medium(size: 17)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.5)
        
        nameTextField.delegate = self
        nameTextField.font = SPFonts.medium(size: 17)
        nameTextField.placeholder = RStrings.name()

        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = SPFonts.regular(size: 14)
        descriptionLabel.text = OrderViewModel.phoneWarningLabel
        
        phoneTextField.setup()
        phoneTextField.delegate = self
        phoneTextField.font = SPFonts.medium(size: 17)
        phoneTextField.placeholder = RStrings.phone()
    }
}

// MARK: - CellViewModelConfigurable

extension PhoneNameTableViewCell: CellViewModelConfigurable {
    func configure(with viewModel: ItemViewModel) {
        guard let viewModel = viewModel as? PhoneNamePredentable else {
            return
        }
        
        nameTextField.text = viewModel.name
        
        phoneTextField.text = viewModel.phone
        phoneTextField.isUserInteractionEnabled = viewModel.isEditable
    }
}

// MARK: - UITextFieldDelegate

extension PhoneNameTableViewCell: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case phoneTextField:
            let formattedText = textField.text?.applyPatternOnNumbers(pattern: .russian)
            phoneTextField.text = formattedText
            actionHandler?.triggerAction(EditOrderType.phone(textField.text ?? ""))
        case nameTextField:
            actionHandler?.triggerAction(EditOrderType.name(textField.text ?? ""))
        default:
            break
        }
    }
}
