import Foundation
import Testing

@testable import dauphin

private final class MockViewModelRepository: CourseRepository, @unchecked Sendable {
    var cachedCourses: [dauphin.Course]?
    var savedCourses: [dauphin.Course]?
    var didClear = false
    var fetchCount = 0
    var nextRemoteResult: Result<[dauphin.Course], Error> = .success([])

    func loadCache() -> [dauphin.Course]? { cachedCourses }
    func saveCache(_ courses: [dauphin.Course]) { savedCourses = courses }
    func clearCache() {
        didClear = true
        cachedCourses = nil
    }

    @CourseDataActor func fetchRemote(encryptedQuery _: String) async throws -> [dauphin.Course] {
        fetchCount += 1
        return try nextRemoteResult.get()
    }
}

@MainActor @Suite("Course ViewModel") struct CourseViewModelTests {
    @Test("loadCoursesFromCache updates empty state") func loadCoursesFromCacheUpdatesState() {
        let repo = MockViewModelRepository()
        repo.cachedCourses = []
        let vm = CourseViewModel(repository: repo, encryptor: { _ in "ENC" })

        let loaded = vm.loadCoursesFromCache()
        #expect(loaded?.isEmpty == true)
        #expect(vm.isCacheEmpty)
    }

    @Test("clearCache clears courses and reports message") func clearCacheResetsState() {
        let repo = MockViewModelRepository()
        let vm = CourseViewModel(repository: repo, encryptor: { _ in "ENC" })

        vm.weekCourses = [
            CourseTestSupport.makeCourse(
                name: "Old", weekday: 1, startOffsetFromNow: 0, endOffsetFromNow: 30,
                reference: CourseTestSupport.referenceDate())
        ]

        vm.clearCache()

        #expect(repo.didClear)
        #expect(vm.weekCourses.isEmpty)
        #expect(vm.isCacheEmpty)
        #expect(vm.errorMessage == "Cache cleared. Please refresh to load courses.")
    }

    @Test("first login fetch loads remote and saves cache")
    func firstLoginFetchLoadsRemoteAndSavesCache() async {
        let repo = MockViewModelRepository()
        let remote = [
            CourseTestSupport.makeCourse(
                name: "Remote", weekday: 3, startOffsetFromNow: 20, endOffsetFromNow: 70,
                reference: CourseTestSupport.referenceDate())
        ]
        repo.cachedCourses = []
        repo.nextRemoteResult = .success(remote)

        let vm = CourseViewModel(repository: repo, encryptor: { _ in "ENC" })
        await vm.fetchCourses(with: "410000000", isFirstLogin: true)

        #expect(repo.fetchCount == 1)
        #expect(repo.savedCourses == remote)
        #expect(vm.weekCourses == remote)
        #expect(vm.errorMessage == nil)
    }

    @Test("subsequent non-forced fetch does not re-fetch")
    func subsequentNonForcedFetchSkipsRemote() async {
        let repo = MockViewModelRepository()
        repo.nextRemoteResult = .success([
            CourseTestSupport.makeCourse(
                name: "A", weekday: 2, startOffsetFromNow: 0, endOffsetFromNow: 30,
                reference: CourseTestSupport.referenceDate())
        ])

        let vm = CourseViewModel(repository: repo, encryptor: { _ in "ENC" })
        await vm.fetchCourses(with: "410000000", isFirstLogin: true)
        await vm.fetchCourses(with: "410000000")

        #expect(repo.fetchCount == 1)
    }
}
