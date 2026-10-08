import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private init() {}

    let healthStore = HKHealthStore()

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard isHealthDataAvailable else {
            completion(false)
            return
        }

        let menstrualType = HKObjectType.categoryType(forIdentifier: .menstrualFlow)!
        let typesToShare: Set<HKSampleType> = [menstrualType]
        let typesToRead: Set<HKObjectType> = [menstrualType]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    func writeMenstrualPeriod(startDate: Date, endDate: Date, completion: @escaping (Bool) -> Void) {
        guard isHealthDataAvailable else {
            completion(false)
            return
        }

        let menstrualType = HKObjectType.categoryType(forIdentifier: .menstrualFlow)!
        // HKCategoryValueMenstrualFlow.unspecified
        let sample = HKCategorySample(
            type: menstrualType,
            value: HKCategoryValueMenstrualFlow.unspecified.rawValue,
            start: startDate,
            end: endDate
        )

        healthStore.save(sample) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}
