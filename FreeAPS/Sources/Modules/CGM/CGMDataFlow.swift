enum CGM {
    enum Config {}
}

enum cgmConfig {
    enum Config {}
}

protocol CGMProvider: Provider {
    var preferences: Preferences { get }
}
