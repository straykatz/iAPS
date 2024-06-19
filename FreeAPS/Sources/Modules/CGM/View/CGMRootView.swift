import LoopKitUI
import SwiftUI
import Swinject

extension CGM {
    struct RootView: BaseView {
        let resolver: Resolver
        @StateObject var state = StateModel()
        @State private var setupCGM = false

        @State var isPresented = false
        @State var description = Text("")
        @State var descriptionHeader = Text("")
        @State var scrollView = false
        @State var graphics: (any View)?

        @Environment(\.colorScheme) var colorScheme
        var color: LinearGradient {
            colorScheme == .dark ? LinearGradient(
                gradient: Gradient(colors: [
                    Color.bgDarkBlue,
                    Color.bgDarkerDarkBlue
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
                :
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
        }

        // @AppStorage(UserDefaults.BTKey.cgmTransmitterDeviceAddress.rawValue) private var cgmTransmitterDeviceAddress: String? = nil

        private var formatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter
        }

        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("CGM")) {
                        Picker("Type", selection: $state.cgm) {
                            ForEach(CGMType.allCases) { type in
                                VStack(alignment: .leading) {
                                    Text(type.displayName)
                                    Text(type.subtitle).font(.caption).foregroundColor(.secondary)
                                }.tag(type)
                            }
                        }
                        if let link = state.cgm.externalLink {
                            Button("About this source") {
                                UIApplication.shared.open(link, options: [:], completionHandler: nil)
                            }
                        }
                    }
                    if [.dexcomG5, .dexcomG6, .dexcomG7].contains(state.cgm) {
                        Section {
                            Button("CGM Configuration") {
                                setupCGM.toggle()
                            }
                        }
                    }
                    if state.cgm == .xdrip {
                        Section(header: Text("Heartbeat")) {
                            VStack(alignment: .leading) {
                                if let cgmTransmitterDeviceAddress = state.cgmTransmitterDeviceAddress {
                                    Text("CGM address :")
                                    Text(cgmTransmitterDeviceAddress)
                                } else {
                                    Text("CGM is not used as heartbeat.")
                                }
                            }
                        }
                    }
                    if state.cgm == .libreTransmitter {
                        Button("Configure Libre Transmitter") {
                            state.showModal(for: .libreConfig)
                        }
                        Text("Calibrations").navigationLink(to: .calibrations, from: self)
                    }
                    Section(header: Text("Calendar")) {
                        Toggle("Create Events in Calendar", isOn: $state.createCalendarEvents)
                        if state.calendarIDs.isNotEmpty {
                            Picker("Calendar", selection: $state.currentCalendarID) {
                                ForEach(state.calendarIDs, id: \.self) {
                                    Text($0).tag($0)
                                }
                            }
                            Toggle("Display Emojis as Labels", isOn: $state.displayCalendarEmojis)
                            Toggle("Display IOB and COB", isOn: $state.displayCalendarIOBandCOB)
                        } else if state.createCalendarEvents {
                            if #available(iOS 17.0, *) {
                                Text(
                                    "If you are not seeing calendars to choose here, please go to Settings -> iAPS -> Calendars and change permissions to \"Full Access\""
                                ).font(.footnote)

                                Button("Open Settings") {
                                    // Get the settings URL and open it
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        }
                    }

                    Section(header: Text("Experimental")) {
                        VStack {
                            Toggle("Smooth Glucose Value", isOn: $state.smoothGlucose)
                            if state.cgm == .glucoseDirect || state.cgm == .simulator || state.cgm == .libreTransmitter {
                                Picker(
                                    selection: $state.sgvInt,
                                    label: Text("SGV Interval")
                                ) {
                                    ForEach(SGVInt.allCases) { selection in
                                        Text(selection.displayName).tag(selection)
                                    }
                                }
                                Text("Apple Health will be force deactivated if 1min glucose values are used!")
                                    .font(.caption).italic()
                            }
                        }
                    }

                    if state.sgvInt == .sgv1min {
                        Section(header: Text("1min Settings")) {
                            VStack {
                                Text(
                                    "With 1min glucose values Loops will also be calculated every minute. Seriously consider adjusting down the SMB delivery Ratio as now instead of just 1 SMB every 5min, potentially 5 SMB's can be enacted. This would require to set the SMB interval to 1min."
                                )
                            }
                            HStack {
                                Text("SMB Interval")
                                    .onTapGesture {
                                        info(
                                            header: "Adjust SMB Interval:",
                                            body: "For 5min CGM values use a 3-5min SMB Interval, for 1min CGM Values use 1min",
                                            useGraphics: nil
                                        )
                                    }
                                Spacer()
                                DecimalTextField("0", value: $state.smbInterval, formatter: formatter)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden).background(color)
                .onAppear(perform: configureView)
                .navigationTitle("CGM")
                .navigationBarTitleDisplayMode(.automatic)
                .sheet(isPresented: $setupCGM) {
                    if let cgmFetchManager = state.cgmManager, cgmFetchManager.glucoseSource.cgmType == state.cgm {
                        CGMSettingsView(
                            cgmManager: cgmFetchManager.glucoseSource.cgmManager!,
                            bluetoothManager: state.provider.apsManager.bluetoothManager!,
                            unit: state.settingsManager.settings.units,
                            completionDelegate: state
                        )
                    } else {
                        CGMSetupView(
                            CGMType: state.cgm,
                            bluetoothManager: state.provider.apsManager.bluetoothManager!,
                            unit: state.settingsManager.settings.units,
                            completionDelegate: state,
                            setupDelegate: state
                        )
                    }
                }
                .onChange(of: setupCGM) { setupCGM in
                    state.setupCGM = setupCGM
                }
                .onChange(of: state.setupCGM) { setupCGM in
                    self.setupCGM = setupCGM
                }
            }
        }

        func info(header: String, body: String, useGraphics: (any View)?) {
            isPresented.toggle()
            description = Text(NSLocalizedString(body, comment: "Dynamic ISF Setting"))
            descriptionHeader = Text(NSLocalizedString(header, comment: "Dynamic ISF Setting Title"))
            graphics = useGraphics
        }

        var info: some View {
            VStack(spacing: 20) {
                descriptionHeader.font(.title2).bold()
                description.font(.body)
            }
        }

        func infoView() -> some View {
            info
                .formatDescription()
                .onTapGesture {
                    isPresented.toggle()
                }
        }

        func infoScrollView() -> some View {
            ScrollView {
                VStack(spacing: 20) {
                    info
                    if let view = graphics {
                        view.asAny()
                    }
                }
            }
            .formatDescription()
            .onTapGesture {
                isPresented.toggle()
                scrollView = false
            }
        }
    }
}
