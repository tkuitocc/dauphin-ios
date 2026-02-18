import Foundation

protocol CourseAPIClient {
    @CourseDataActor func fetchCoursesData(encryptedQuery: String) async throws -> Data
}

struct DefaultCourseAPIClient: CourseAPIClient {
    @CourseDataActor func fetchCoursesData(encryptedQuery: String) async throws -> Data {
        var comps = URLComponents(string: Constants.courseAPIEndpoint)!
        comps.queryItems = [URLQueryItem(name: "q", value: encryptedQuery)]
        guard let url = comps.url else { throw URLError(.badURL) }
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse, 200 ... 299 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
