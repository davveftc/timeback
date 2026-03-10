import WidgetKit
import SwiftUI
import CoreData

// MARK: - Timeline Entry

struct BrickStatusEntry: TimelineEntry {
    let date: Date
    let isBricked: Bool
    let modeName: String?
    let modeIcon: String?
    let sessionStartedAt: Date?
}

// MARK: - Timeline Provider

struct BrickStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> BrickStatusEntry {
        BrickStatusEntry(
            date: .now,
            isBricked: false,
            modeName: nil,
            modeIcon: nil,
            sessionStartedAt: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BrickStatusEntry) -> Void) {
        completion(fetchCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BrickStatusEntry>) -> Void) {
        let entry = fetchCurrentEntry()
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchCurrentEntry() -> BrickStatusEntry {
        // Load shared Core Data store
        let model = PersistenceController.createManagedObjectModel()
        let container = NSPersistentContainer(name: "FocusBrickModel", managedObjectModel: model)

        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: PersistenceController.appGroupIdentifier
        ) {
            let storeURL = containerURL.appendingPathComponent("FocusBrick.sqlite")
            let description = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, _ in }

        let context = container.viewContext
        let activeSession = Session.fetchActive(in: context)

        return BrickStatusEntry(
            date: .now,
            isBricked: activeSession != nil,
            modeName: activeSession?.mode?.name,
            modeIcon: activeSession?.mode?.icon,
            sessionStartedAt: activeSession?.startedAt
        )
    }
}

// MARK: - Widget View

struct BrickWidgetView: View {
    let entry: BrickStatusEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.isBricked {
            brickedView
        } else {
            unbrickedView
        }
    }

    private var brickedView: some View {
        VStack(spacing: 4) {
            if let icon = entry.modeIcon, let name = entry.modeName {
                HStack(spacing: 4) {
                    Text(icon)
                    Text(name)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white.opacity(0.8))
            }

            if let startedAt = entry.sessionStartedAt {
                Text(startedAt, style: .timer)
                    .font(.system(size: family == .systemSmall ? 24 : 32, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }

            Text("Bricked")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "1C2833"))
    }

    private var unbrickedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.open.fill")
                .font(.title2)
                .foregroundColor(Color(hex: "2E86C1"))

            Text("Unbricked")
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget Configuration

struct FocusBrickWidget: Widget {
    let kind = "FocusBrickWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: BrickStatusProvider()
        ) { entry in
            BrickWidgetView(entry: entry)
        }
        .configurationDisplayName("FocusBrick")
        .description("See your Brick status at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
