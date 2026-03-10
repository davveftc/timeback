import CoreData
import FamilyControls

@objc(Mode)
public class Mode: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var icon: String
    @NSManaged public var blockedAppTokensData: Data
    @NSManaged public var blockedCategoryTokensData: Data?
    @NSManaged public var blockedWebDomainsData: Data?
    @NSManaged public var isDefault: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var sessions: NSSet?
    @NSManaged public var schedules: NSSet?

    /// Decoded FamilyActivitySelection for reading/writing blocked apps.
    var familyActivitySelection: FamilyActivitySelection {
        get {
            guard let data = blockedAppTokensData as Data?,
                  let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            else { return FamilyActivitySelection() }
            return selection
        }
        set {
            blockedAppTokensData = (try? JSONEncoder().encode(newValue)) ?? Data()
            updatedAt = Date()
        }
    }

    var blockedAppTokens: Set<ApplicationToken> {
        familyActivitySelection.applicationTokens
    }

    var blockedCategoryTokens: Set<ActivityCategoryToken> {
        familyActivitySelection.categoryTokens
    }

    var blockedWebDomainTokens: Set<WebDomainToken> {
        familyActivitySelection.webDomainTokens
    }
}

extension Mode {
    static let availableIcons = ["💼", "💤", "👪", "🏋️", "📚", "🎮", "🌙", "☕", "🎯", "🧘", "🚗", "✈️"]
    static let maxModes = 10
    static let maxNameLength = 20

    static func create(
        name: String,
        icon: String = "💼",
        selection: FamilyActivitySelection = FamilyActivitySelection(),
        isDefault: Bool = false,
        in context: NSManagedObjectContext
    ) -> Mode {
        let mode = Mode(context: context)
        mode.id = UUID()
        mode.name = name
        mode.icon = icon
        mode.familyActivitySelection = selection
        mode.isDefault = isDefault
        mode.createdAt = Date()
        mode.updatedAt = Date()
        return mode
    }

    static func fetchAll(in context: NSManagedObjectContext) -> [Mode] {
        let request = NSFetchRequest<Mode>(entityName: "Mode")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    static func fetchDefault(in context: NSManagedObjectContext) -> Mode? {
        let request = NSFetchRequest<Mode>(entityName: "Mode")
        request.predicate = NSPredicate(format: "isDefault == YES")
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    static func count(in context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<Mode>(entityName: "Mode")
        return (try? context.count(for: request)) ?? 0
    }
}
