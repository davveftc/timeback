import ManagedSettings
import ManagedSettingsUI

/// Shield configuration extension.
/// MVP: returns default Apple shield UI.
/// Future: customizable with FocusBrick branding.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(
        shielding application: ApplicationToken
    ) -> ShieldConfiguration {
        // MVP: use default Apple shield configuration
        return ShieldConfiguration()

        // Future customization:
        // return ShieldConfiguration(
        //     backgroundBlurStyle: .systemThickMaterial,
        //     backgroundColor: UIColor(red: 0.11, green: 0.16, blue: 0.20, alpha: 1.0),
        //     title: ShieldConfiguration.Label(
        //         text: "Your phone is Bricked",
        //         color: .white
        //     ),
        //     subtitle: ShieldConfiguration.Label(
        //         text: "Return to your FocusBrick to unlock",
        //         color: UIColor.white.withAlphaComponent(0.6)
        //     ),
        //     primaryButtonLabel: ShieldConfiguration.Label(
        //         text: "Back to living",
        //         color: .white
        //     ),
        //     primaryButtonBackgroundColor: UIColor(red: 0.18, green: 0.53, blue: 0.76, alpha: 1.0)
        // )
    }

    override func configuration(
        shielding application: ApplicationToken,
        in category: ActivityCategoryToken
    ) -> ShieldConfiguration {
        configuration(shielding: application)
    }

    override func configuration(
        shielding webDomain: WebDomainToken
    ) -> ShieldConfiguration {
        return ShieldConfiguration()
    }

    override func configuration(
        shielding webDomain: WebDomainToken,
        in category: ActivityCategoryToken
    ) -> ShieldConfiguration {
        return ShieldConfiguration()
    }
}
