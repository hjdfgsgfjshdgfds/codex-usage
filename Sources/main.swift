import SwiftUI

@main
struct CodexUsageMenubarApp: App {
    @StateObject private var viewModel = UsageViewModel(service: CodexUsageService())

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 12) {
                Text("ChatGPT Plus usage")
                    .font(.headline)

                Group {
                    switch viewModel.state {
                    case .idle, .loading:
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Loading usage…")
                        }
                    case .loaded(let snapshot):
                        VStack(alignment: .leading, spacing: 4) {
                            Text("5-hour window: \(snapshot.usedInWindow)/\(snapshot.windowLimit) (\(snapshot.windowPercentUsed)%)")
                            Text("Remaining: \(snapshot.remainingInWindow)")

                            if let total = snapshot.totalMessages {
                                Text("Total messages: \(total)")
                            }

                            if let reset = snapshot.resetAtText {
                                Text("Resets: \(reset)")
                            }
                        }
                    case .failed(let error):
                        Text("Failed: \(error)")
                            .foregroundStyle(.red)
                    }
                }
                .font(.subheadline)

                Divider()

                HStack {
                    Button("Refresh") {
                        Task { await viewModel.refresh() }
                    }

                    Spacer()

                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            .padding(14)
            .frame(minWidth: 320)
            .task {
                await viewModel.start()
            }
        } label: {
            Text(viewModel.menuBarTitle)
                .monospacedDigit()
        }
    }
}

@MainActor
final class UsageViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded(UsageSnapshot)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var menuBarTitle: String = "Plus --%"

    private let service: CodexUsageService

    init(service: CodexUsageService) {
        self.service = service
    }

    func start() async {
        await refresh()

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(300))
            await refresh()
        }
    }

    func refresh() async {
        state = .loading

        do {
            let snapshot = try await service.fetchUsageSnapshot()
            state = .loaded(snapshot)
            menuBarTitle = "Plus \(snapshot.windowPercentUsed)%"
        } catch {
            state = .failed(error.localizedDescription)
            menuBarTitle = "Plus ERR"
        }
    }
}
