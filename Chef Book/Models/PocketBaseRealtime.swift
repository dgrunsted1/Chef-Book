//
//  PocketBaseRealtime.swift
//  Chef Book
//

import Foundation

class PocketBaseRealtime: NSObject, URLSessionDataDelegate {
    private let baseURL: String
    private var urlSession: URLSession?
    private var dataTask: URLSessionDataTask?
    private var clientId: String?
    private var subscriptions: [String: (([String: Any]) -> Void)] = []
    private var token: String?
    private var buffer = Data()

    init(baseURL: String) {
        self.baseURL = baseURL
        super.init()
    }

    func connect(token: String?) {
        self.token = token
        disconnect()

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(INT_MAX)
        config.timeoutIntervalForResource = TimeInterval(INT_MAX)
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)

        guard let url = URL(string: "\(baseURL)/api/realtime") else { return }
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        dataTask = urlSession?.dataTask(with: request)
        dataTask?.resume()
    }

    func disconnect() {
        dataTask?.cancel()
        dataTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        clientId = nil
        buffer = Data()
    }

    func subscribe(to topic: String, handler: @escaping ([String: Any]) -> Void) {
        subscriptions[topic] = handler

        // If we already have a clientId, send the subscription
        if let clientId = clientId {
            sendSubscription(clientId: clientId, topic: topic)
        }
    }

    func unsubscribe(from topic: String) {
        subscriptions.removeValue(forKey: topic)
    }

    private func sendSubscription(clientId: String, topic: String) {
        guard let url = URL(string: "\(baseURL)/api/realtime") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "clientId": clientId,
            "subscriptions": Array(subscriptions.keys)
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("Realtime subscription error: \(error)")
            }
        }.resume()
    }

    // MARK: - URLSessionDataDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)

        guard let text = String(data: buffer, encoding: .utf8) else { return }

        // SSE events are separated by double newlines
        let events = text.components(separatedBy: "\n\n")

        // Keep the last incomplete event in buffer
        if !text.hasSuffix("\n\n") {
            if let lastEvent = events.last {
                buffer = lastEvent.data(using: .utf8) ?? Data()
            }
            // Process all complete events (except the last incomplete one)
            for event in events.dropLast() {
                processSSEEvent(event)
            }
        } else {
            buffer = Data()
            for event in events where !event.isEmpty {
                processSSEEvent(event)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Realtime connection closed: \(error.localizedDescription)")
        }
        // Reconnect after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.connect(token: self?.token)
        }
    }

    // MARK: - SSE Parsing

    private func processSSEEvent(_ raw: String) {
        var eventName = ""
        var eventData = ""

        for line in raw.split(separator: "\n", omittingEmptySubsequences: false) {
            let lineStr = String(line)
            if lineStr.hasPrefix("event:") {
                eventName = String(lineStr.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if lineStr.hasPrefix("data:") {
                eventData = String(lineStr.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            }
        }

        guard !eventData.isEmpty else { return }

        // Parse the JSON data
        guard let jsonData = eventData.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else { return }

        if eventName == "PB_CONNECT" {
            // Initial connection — extract clientId
            if let id = json["clientId"] as? String {
                clientId = id
                // Re-subscribe to all topics
                for topic in subscriptions.keys {
                    sendSubscription(clientId: id, topic: topic)
                }
            }
            return
        }

        // Dispatch to matching subscription handlers
        // Event name format from PB: "collectionName/recordId" or just "collectionName"
        for (topic, handler) in subscriptions {
            if eventName.hasPrefix(topic) || topic == "*" {
                handler(json)
            }
        }
    }
}
