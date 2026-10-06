import XCTest

final class ScreenshotUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func attach(_ app: XCUIApplication, name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCaptureAppScreens() throws {
        let app = XCUIApplication()
        app.launch()

        let firstCell = app.collectionViews.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 20), "lista de moedas não carregou a tempo")
        sleep(1)
        attach(app, name: "01-moedas")

        firstCell.swipeRight()
        sleep(1)
        let favoritarButton = app.buttons["Favoritar"]
        if favoritarButton.waitForExistence(timeout: 5) {
            favoritarButton.tap()
        }
        sleep(1)

        app.tabBars.buttons["Favoritos"].tap()
        sleep(1)
        attach(app, name: "02-favoritos")

        app.tabBars.buttons["Em Alta"].tap()
        sleep(1)
        attach(app, name: "03-em-alta")

        app.tabBars.buttons["Moedas"].tap()
        sleep(1)
        let coinCell = app.collectionViews.cells.element(boundBy: 0)
        coinCell.tap()

        let chart = app.otherElements.containing(.image, identifier: nil).firstMatch
        _ = chart
        sleep(3)
        attach(app, name: "04-detalhe-grafico")

        let targetField = app.textFields["targetPriceField"]
        if targetField.waitForExistence(timeout: 5) {
            targetField.tap()
            targetField.typeText("500000")
            app.buttons["Definir"].tap()

            let systemAlert = app.alerts.firstMatch
            if systemAlert.waitForExistence(timeout: 5) {
                if systemAlert.buttons["Permitir"].exists {
                    systemAlert.buttons["Permitir"].tap()
                } else if systemAlert.buttons["Allow"].exists {
                    systemAlert.buttons["Allow"].tap()
                }
            }
            sleep(1)
            attach(app, name: "05-detalhe-alerta")
        }

        if app.navigationBars.buttons.element(boundBy: 0).exists {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        sleep(1)

        app.buttons["settingsButton"].tap()
        sleep(1)
        attach(app, name: "06-configuracoes")
    }
}
