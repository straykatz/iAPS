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
        @State private var showText = false // State variable to manage text visibility
        @State private var currentScale: CGFloat = 1.0 // State variable for scaling

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

                    Section(header: Text("Adjust SMB settings")) {
                        VStack {
                            Text(
                                "With 1min glucose values Loops will also be calculated every minute. Seriously consider adjusting down the SMB delivery Ratio as now instead of just 1 SMB every 5min, potentially 5 SMB's can be enacted. This would require to set the SMB interval to 1min."
                            )
                            .font(.caption).italic()
                        }
                    }
                    Section(header: Text("Adjust SMB interval")) {
                        HStack {
                            Text("SMB Interval")
                                .onTapGesture {
                                    info(
                                        header: "Adjust SMB Interval:",
                                        body: "For 5min SGVs values use a 3-5min SMB Interval, for 1min SGV'S use 1min",
                                        useGraphics: nil
                                    )
                                }
                            Spacer()
                            DecimalTextField("0", value: $state.smbInterval, formatter: formatter)
                        }
                    }
                    Section(header: Text("Adjust SMB delivery ratio settings")) {
                        HStack {
                            Text("SMB DeliveryRatio")
                                .onTapGesture {
                                    scrollView = true
                                    graphics = ratioImage().asAny()
                                    info(
                                        header: "SMB DeliveryRatio:",
                                        body: "Specifies what share of the total insulin required, can be delivered as SMB. Using 5 Loop calculations and potentially 5 SMB's requires a drastically smaller SMB ratio to deliver the same percentage of Insulin required as with 1 SMB in 5 minutes. The grapph shows 1min-to-5min SMB ratio equivalents. E.g. a 5min SMB ratio of 70& only requires a 21% SMB ratio using 1min SMB intervals.",
                                        useGraphics: graphics
                                    )
                                }
                            Spacer()
                            DecimalTextField("0", value: $state.smbDeliveryRatio, formatter: formatter)
                        }
                        HStack {
                            Text("Dynamic SMB DeliveryRatio range")
                                .onTapGesture {
                                    info(
                                        header: "May be adjust dynamic range:",
                                        body: "Default value: 0, which disables the dynamic ratio adjustment. Sensible is between 40 and 120. The linearly increasing SMB delivery ratio is mapped to the glucose range [target_bg, target_bg+bg_range]. At target_bg the SMB ratio is smb_delivery_ratio_min, at target_bg+bg_range it is SMB delivery_ratio_max. With 0 the linearly increasing SMB ratio is disabled and the fix smb_deliveryRatio is used.",
                                        useGraphics: nil
                                    )
                                }
                            Spacer()
                            DecimalTextField("0", value: $state.smbDeliveryRatioBGrange, formatter: formatter)
                        }
                        HStack {
                            Text("SMB DeliveryRatio BG Maximum")
                                .onTapGesture {
                                    info(
                                        header: "Adjust if using dynamic SMB DeliveryRatio:",
                                        body: "Default value: 0.5 This is the higher end of a linearly increasing SMB DeliveryRatio rather than the fix value above in SMB DeliveryRatio.",
                                        useGraphics: nil
                                    )
                                }
                            Spacer()
                            DecimalTextField("0", value: $state.smbDeliveryRatioMax, formatter: formatter)
                        }
                        HStack {
                            Text("SMB DeliveryRatio BG Minimum")
                                .onTapGesture {
                                    info(
                                        header: "Adjust if using dynamic SMB DeliveryRatio:",
                                        body: "Default value: 0.5 This is the lower end of a linearly increasing SMB DeliveryRatio rather than the fix value above in SMB DeliveryRatio.",
                                        useGraphics: nil
                                    )
                                }
                            Spacer()
                            DecimalTextField("0", value: $state.smbDeliveryRatioMin, formatter: formatter)
                        }
                    }
                }
                .scrollContentBackground(.hidden).background(color)
                .onAppear(perform: configureView)
                .navigationTitle("CGM")
                .navigationBarTitleDisplayMode(.automatic)
                .description(isPresented: isPresented, alignment: .center) {
                    if scrollView { infoScrollView() } else { infoView() }
                }
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
                .onDisappear {
                    state.saveIfChanged()
                }
            }
        }

        func info(header: String, body: String, useGraphics: (any View)?) {
            isPresented.toggle()
            description = Text(NSLocalizedString(body, comment: "SMB ratio adjustments"))
            descriptionHeader = Text(NSLocalizedString(header, comment: "Ratio Adjustment Title"))
            graphics = useGraphics
        }

        var info: some View {
            VStack(spacing: 20) {
                descriptionHeader.font(.title2).bold()
                description.font(.body)
            }
            .padding()
            .scrollContentBackground(.hidden).background(color)
            .cornerRadius(10)
            .shadow(radius: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .padding()
        }

        func infoView() -> some View {
            info
                .formatDescription()
                .padding(.all, 10)
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

        func ratioString(_ ratio: Decimal) -> String {
            formatter.string(for: ratio as NSNumber) ?? ""
        }

        @ViewBuilder func ratioImage() -> some View {
            VStack {
                Image("RatioEquivalents")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(currentScale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                currentScale = value
                            }
                            .onEnded { value in
                                currentScale = value
                            }
                    )
                    .padding(.all, 20)
            }
        }
    }
}
