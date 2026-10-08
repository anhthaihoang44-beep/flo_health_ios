import Foundation

enum AuthResult {
    case success(userId: String, email: String?, isAnonymous: Bool)
    case failure(String)
}

class SupabaseManager {
    static let shared = SupabaseManager()

    var supabaseUrl: String = "https://demo-cyclecare.supabase.co"
    var anonKey: String = "mock-anon-key"

    var isConfigured: Bool {
        !supabaseUrl.contains("demo") && !supabaseUrl.contains("placeholder") && !anonKey.contains("mock")
    }

    func signInAnonymously() async -> AuthResult {
        guard isConfigured else {
            let mockId = UUID().uuidString
            return .success(userId: mockId, email: nil, isAnonymous: true)
        }

        guard let url = URL(string: "\(supabaseUrl)/auth/v1/signup") else {
            return .failure("URL không hợp lệ")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["data": ["is_anonymous": true]]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let user = json["user"] as? [String: Any],
                   let id = user["id"] as? String {
                    return .success(userId: id, email: nil, isAnonymous: true)
                }
            }
            return .success(userId: UUID().uuidString, email: nil, isAnonymous: true)
        } catch {
            return .success(userId: UUID().uuidString, email: nil, isAnonymous: true)
        }
    }

    func signInWithEmail(email: String, password: String) async -> AuthResult {
        guard isConfigured else {
            return .success(userId: UUID().uuidString, email: email, isAnonymous: false)
        }

        guard let url = URL(string: "\(supabaseUrl)/auth/v1/token?grant_type=password") else {
            return .failure("URL không hợp lệ")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let user = json["user"] as? [String: Any],
                   let id = user["id"] as? String {
                    return .success(userId: id, email: email, isAnonymous: false)
                }
            }
            return .failure("Đăng nhập thất bại. Vui lòng kiểm tra email và mật khẩu.")
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    func linkIdentity(userId: String, email: String, password: String) async -> AuthResult {
        return await signInWithEmail(email: email, password: password)
    }
}
