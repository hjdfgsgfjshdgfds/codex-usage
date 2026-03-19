import Foundation

struct UsageSnapshot {
    let usedInWindow: Int
    let windowLimit: Int
    let remainingInWindow: Int
    let windowPercentUsed: Int
    let totalMessages: Int?
    let resetAtText: String?
}

struct CodexUsageService {
    private let baseURL = URL(string: "https://chatgpt.com/backend-api")!

    func fetchUsageSnapshot() async throws -> UsageSnapshot {
        let token = try loadSessionToken()
        let payload = try await fetchUsageLimitsPayload(sessionToken: token)

        let used = intValue(in: payload, keys: ["used_messages", "messages_used", "used", "count_used"])
        let remaining = intValue(in: payload, keys: ["remaining_messages", "messages_remaining", "remaining", "count_remaining"])
        let limit = intValue(in: payload, keys: ["max_messages", "messages_limit", "limit", "cap"]) ?? ((used ?? 0) + (remaining ?? 0))

        guard let used, let limit, limit > 0 else {
            throw NSError(
                domain: "CodexUsageService",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Could not find usage counters in ChatGPT response. Set CHATGPT_DEBUG_DUMP=1 to inspect payload shape."]
            )
        }

        let computedRemaining = remaining ?? max(limit - used, 0)
        let percent = Int((Double(used) / Double(limit) * 100).rounded())

        let totalMessages = intValue(in: payload, keys: ["total_messages", "monthly_total_messages", "lifetime_messages", "total"])
        let resetAtText = dateText(from: payload)

        return UsageSnapshot(
            usedInWindow: used,
            windowLimit: limit,
            remainingInWindow: computedRemaining,
            windowPercentUsed: percent,
            totalMessages: totalMessages,
            resetAtText: resetAtText
        )
    }

    private func loadSessionToken() throws -> String {
        if let key = ProcessInfo.processInfo.environment["CHATGPT_SESSION_TOKEN"], !key.isEmpty {
            return key
        }

        throw NSError(
            domain: "CodexUsageService",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Set CHATGPT_SESSION_TOKEN in your app scheme environment variables."]
        )
    }

    private func fetchUsageLimitsPayload(sessionToken: String) async throws -> [String: Any] {
        var request = URLRequest(url: baseURL.appendingPathComponent("usage_limits"))
        request.setValue("https://chatgpt.com", forHTTPHeaderField: "Origin")
        request.setValue("https://chatgpt.com/", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.setValue("__Secure-next-auth.session-token=\(sessionToken)", forHTTPHeaderField: "Cookie")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        if ProcessInfo.processInfo.environment["CHATGPT_DEBUG_DUMP"] == "1" {
            if let raw = String(data: data, encoding: .utf8) {
                print("usage_limits payload:\n\(raw)")
            }
        }

        let object = try JSONSerialization.jsonObject(with: data)

        guard let dict = object as? [String: Any] else {
            throw NSError(
                domain: "CodexUsageService",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Unexpected ChatGPT response payload type."]
            )
        }

        return dict
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8 response>"
            throw NSError(
                domain: "CodexUsageService",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "ChatGPT request error \(http.statusCode): \(body)"]
            )
        }
    }

    private func intValue(in payload: [String: Any], keys: [String]) -> Int? {
        for key in keys {
            if let value = findFirstValue(for: key, in: payload) {
                if let intValue = value as? Int {
                    return intValue
                }
                if let doubleValue = value as? Double {
                    return Int(doubleValue)
                }
                if let stringValue = value as? String, let intValue = Int(stringValue) {
                    return intValue
                }
            }
        }
        return nil
    }

    private func dateText(from payload: [String: Any]) -> String? {
        let possibleKeys = ["reset_at", "resets_at", "next_reset_at", "window_reset_at", "reset_time"]

        for key in possibleKeys {
            guard let value = findFirstValue(for: key, in: payload) else { continue }

            if let iso = value as? String {
                return iso
            }

            if let unix = value as? Double {
                return formatDate(fromUnix: unix)
            }

            if let unixInt = value as? Int {
                return formatDate(fromUnix: Double(unixInt))
            }
        }

        return nil
    }

    private func formatDate(fromUnix value: Double) -> String {
        let date = Date(timeIntervalSince1970: value)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func findFirstValue(for targetKey: String, in dictionary: [String: Any]) -> Any? {
        if let direct = dictionary[targetKey] {
            return direct
        }

        for value in dictionary.values {
            if let nestedDictionary = value as? [String: Any], let found = findFirstValue(for: targetKey, in: nestedDictionary) {
                return found
            }

            if let nestedArray = value as? [Any] {
                for element in nestedArray {
                    if let nestedDictionary = element as? [String: Any], let found = findFirstValue(for: targetKey, in: nestedDictionary) {
                        return found
                    }
                }
            }
        }

        return nil
    }
}
