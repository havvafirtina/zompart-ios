import Foundation
import Testing
@testable import ZomPart

@Suite
struct DisplayCasedTests {

    @Test func recasesShoutyMakes() {
        #expect("FORD".displayCased == "Ford")
        #expect("VOLVO".displayCased == "Volvo")
        #expect("ALFA ROMEO".displayCased == "Alfa Romeo")
        #expect("MERCEDES-BENZ".displayCased == "Mercedes-Benz")
    }

    @Test func keepsAcronymsAndModelCodes() {
        #expect("BMW".displayCased == "BMW")
        #expect("VW".displayCased == "VW")
        #expect("KIA".displayCased == "KIA")
        #expect("XC60".displayCased == "XC60")
        #expect("V70".displayCased == "V70")
    }

    @Test func keepsAlreadyDeliberateCasing() {
        #expect("Focus".displayCased == "Focus")
        #expect("Focus IV".displayCased == "Focus IV")
        #expect("e-tron".displayCased == "e-tron")
    }

    /// Locale is pinned to en_US_POSIX: even on a Turkish device, "FIAT"
    /// must become "Fiat" (dotted i), never "Fıat".
    @Test func turkishLocaleDoesNotProduceDotlessI() {
        #expect("FIAT".displayCased == "Fiat")
        #expect(!"FIAT".displayCased.contains("ı"))
    }
}
