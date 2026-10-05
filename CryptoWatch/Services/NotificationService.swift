import Foundation
import UserNotifications

struct NotificationService {

    func requestAuthorization() async -> Bool {
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
            trigger: nil // nil = dispara imediatamente
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
