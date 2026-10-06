import Foundation
import UserNotifications

final class ForegroundNotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ForegroundNotificationPresenter()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}

protocol NotificationServiceProtocol {
    func requestAuthorization() async -> Bool
    func fireAlert(coinName: String, targetPrice: Double, currentPrice: Double)
}

struct NotificationService: NotificationServiceProtocol {

    func requestAuthorization() async -> Bool {
        UNUserNotificationCenter.current().delegate = ForegroundNotificationPresenter.shared
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        print("[NotificationService] autorização concedida: \(granted)")
        return granted
    }

    func fireAlert(coinName: String, targetPrice: Double, currentPrice: Double) {
        let content = UNMutableNotificationContent()
        content.title = "\(coinName) bateu o alvo!"
        content.body = String(
            format: "Preço atual: $%.2f (alvo: $%.2f)",
            currentPrice,
            targetPrice
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NotificationService] erro ao disparar notificação: \(error)")
            } else {
                print("[NotificationService] notificação disparada: \(coinName)")
            }
        }
    }
}
