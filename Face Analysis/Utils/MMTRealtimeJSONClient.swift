import Foundation
import CoreData

/// Queues Core Data recordings locally and streams them to the Ubuntu WebSocket receiver.
final class MMTRealtimeJSONClient: NSObject, URLSessionWebSocketDelegate {
    static let shared = MMTRealtimeJSONClient()

    private let queue = DispatchQueue(label: "com.digital-medicine.niwface.realtime-upload")
    private var session: URLSession!
    private var pendingRecords: [[String: Any]] = []
    private var didLoadQueue = false
    private var isUploading = false
    private var flushScheduled = false
    private var retryDelay: TimeInterval = 1
    private var webSocketTask: URLSessionWebSocketTask?
    private var webSocketSessionID: String?
    private var webSocketReady = false
    private var probeTask: URLSessionWebSocketTask?
    private var probeCompletion: ((Result<Void, Error>) -> Void)?

    private let serverURLKey = "realtimeReceiverURL"
    private static let serverPort = 8000

    private var queueFileURL: URL {
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return supportDirectory.appendingPathComponent("realtime-upload-queue.jsonl")
    }

    private override init() {
        super.init()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    /// Saves the WebSocket base URL, for example ws://192.168.1.20:8000.
    func configure(serverURL: String) throws {
        let baseURL = try Self.baseURL(from: serverURL)
        UserDefaults.standard.set(baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/")), forKey: serverURLKey)

        queue.async {
            self.webSocketTask?.cancel(with: .goingAway, reason: nil)
            self.webSocketTask = nil
            self.webSocketSessionID = nil
            self.webSocketReady = false
            self.isUploading = false
            self.loadQueueIfNeeded()
            self.scheduleFlush(after: 0)
        }
    }

    /// Verifies that the configured route accepts a WebSocket connection without sending a sample.
    func testConnection(serverURL: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let socketURL: URL
        do {
            let baseURL = try Self.baseURL(from: serverURL)
            guard let url = Self.webSocketURL(baseURL: baseURL, sessionID: "connectivity-check") else {
                throw ConfigurationError.invalidURL
            }
            socketURL = url
        } catch {
            DispatchQueue.main.async { completion(.failure(error)) }
            return
        }

        queue.async {
            self.probeTask?.cancel(with: .goingAway, reason: nil)
            self.finishProbe(.failure(ConfigurationError.connectionClosed))
            let task = self.session.webSocketTask(with: socketURL)
            self.probeTask = task
            self.probeCompletion = completion
            task.resume()
            self.queue.asyncAfter(deadline: .now() + 6) {
                guard self.probeTask === task else { return }
                task.cancel(with: .goingAway, reason: nil)
                self.finishProbe(.failure(ConfigurationError.connectionTimedOut))
            }
        }
    }

    var configuredServerURL: String {
        UserDefaults.standard.string(forKey: serverURLKey) ?? ""
    }

    /// Reads the managed object on its Core Data queue, then stores an immutable JSON-safe copy.
    func enqueue(recording: NSManagedObject) {
        let context = recording.managedObjectContext
        let copy = { [weak self] in
            guard let strongSelf = self else { return }
            var values: [String: Any] = [:]
            let dateFormatter = ISO8601DateFormatter()

            for key in recording.entity.attributesByName.keys {
                guard let value = recording.value(forKey: key) else {
                    values[key] = NSNull()
                    continue
                }
                if let date = value as? Date {
                    values[key] = dateFormatter.string(from: date)
                } else if let uuid = value as? UUID {
                    values[key] = uuid.uuidString
                } else if let uuid = value as? NSUUID {
                    values[key] = uuid.uuidString
                } else if value is String || value is NSNumber {
                    values[key] = value
                } else {
                    values[key] = String(describing: value)
                }
            }
            strongSelf.enqueue(values)
        }

        if let context {
            context.perform(copy)
        } else {
            copy()
        }
    }

    private func enqueue(_ record: [String: Any]) {
        queue.async {
            self.loadQueueIfNeeded()
            self.pendingRecords.append(record)
            self.appendToDisk(record)
            self.scheduleFlush(after: 0.25)
        }
    }

    private func scheduleFlush(after delay: TimeInterval) {
        guard !flushScheduled else { return }
        flushScheduled = true
        queue.asyncAfter(deadline: .now() + delay) {
            self.flushScheduled = false
            self.flushNextRecord()
        }
    }

    private func flushNextRecord() {
        guard !isUploading,
              !pendingRecords.isEmpty,
              let baseURL = URL(string: configuredServerURL),
              let rawSessionID = pendingRecords[0]["sessionId"] as? String,
              let sessionID = Self.validSessionID(rawSessionID) else {
            return
        }

        if webSocketTask == nil || webSocketSessionID != sessionID {
            webSocketTask?.cancel(with: .goingAway, reason: nil)
            webSocketTask = nil
            webSocketReady = false
            webSocketSessionID = sessionID

            guard let socketURL = Self.webSocketURL(baseURL: baseURL, sessionID: sessionID) else {
                scheduleFlush(after: retryDelay)
                retryDelay = min(retryDelay * 2, 30)
                return
            }
            let task = session.webSocketTask(with: socketURL)
            webSocketTask = task
            task.resume()
            return
        }

        guard webSocketReady, let task = webSocketTask,
              JSONSerialization.isValidJSONObject(pendingRecords[0]),
              let data = try? JSONSerialization.data(withJSONObject: pendingRecords[0]),
              let message = String(data: data, encoding: .utf8) else {
            return
        }

        isUploading = true
        task.send(.string(message)) { error in
            if let error = error {
                self.queue.async { self.handleFailure(task: task, error: error) }
                return
            }
            task.receive { result in
                self.queue.async {
                    guard self.webSocketTask === task else { return }
                    switch result {
                    case .success(let response):
                        let expectedID = self.pendingRecords.first?["uuid"] as? String ?? ""
                        guard self.isSuccessAcknowledgement(response, expectedID: expectedID) else {
                            self.handleFailure(task: task, error: ConfigurationError.invalidAcknowledgement)
                            return
                        }
                        self.isUploading = false
                        self.pendingRecords.removeFirst()
                        self.persistQueueAtomically()
                        self.retryDelay = 1
                        self.scheduleFlush(after: 0)
                    case .failure(let error):
                        self.handleFailure(task: task, error: error)
                    }
                }
            }
        }
    }

    private func isSuccessAcknowledgement(_ message: URLSessionWebSocketTask.Message, expectedID: String) -> Bool {
        let data: Data
        switch message {
        case .string(let text):
            guard let encoded = text.data(using: .utf8) else { return false }
            data = encoded
        case .data(let receivedData):
            data = receivedData
        @unknown default:
            return false
        }
        guard let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        guard let acknowledgedID = response["uuid"] as? String,
              let expectedUUID = UUID(uuidString: expectedID),
              let acknowledgedUUID = UUID(uuidString: acknowledgedID) else { return false }
        return response["success"] as? Bool == true && expectedUUID == acknowledgedUUID
    }

    private func isProbeAcknowledgement(_ message: URLSessionWebSocketTask.Message) -> Bool {
        let data: Data
        switch message {
        case .string(let text):
            guard let encoded = text.data(using: .utf8) else { return false }
            data = encoded
        case .data(let receivedData):
            data = receivedData
        @unknown default:
            return false
        }
        guard let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        return response["success"] as? Bool == true && response["type"] as? String == "pong"
    }

    private func failProbe(task: URLSessionWebSocketTask, error: Error) {
        guard probeTask === task else { return }
        task.cancel(with: .goingAway, reason: nil)
        finishProbe(.failure(error))
    }

    private func handleFailure(task: URLSessionWebSocketTask, error: Error) {
        guard webSocketTask === task else { return }
        isUploading = false
        webSocketReady = false
        webSocketTask = nil
        webSocketSessionID = nil
        task.cancel(with: .goingAway, reason: nil)
        retryDelay = min(retryDelay * 2, 30)
        print("Ubuntu WebSocket upload failed; retrying in \(Int(retryDelay))s: \(error.localizedDescription)")
        scheduleFlush(after: retryDelay)
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol proto: String?) {
        queue.async {
            if self.probeTask === webSocketTask {
                webSocketTask.send(.string("{\"type\":\"ping\"}")) { error in
                    if let error = error {
                        self.queue.async { self.failProbe(task: webSocketTask, error: error) }
                        return
                    }
                    webSocketTask.receive { result in
                        self.queue.async {
                            guard self.probeTask === webSocketTask else { return }
                            switch result {
                            case .success(let response) where self.isProbeAcknowledgement(response):
                                webSocketTask.cancel(with: .normalClosure, reason: nil)
                                self.finishProbe(.success(()))
                            case .success(_):
                                self.failProbe(task: webSocketTask, error: ConfigurationError.invalidAcknowledgement)
                            case .failure(let error):
                                self.failProbe(task: webSocketTask, error: error)
                            }
                        }
                    }
                }
                return
            }
            guard self.webSocketTask === webSocketTask else { return }
            self.webSocketReady = true
            self.flushNextRecord()
        }
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        queue.async {
            if self.probeTask === webSocketTask {
                self.finishProbe(.failure(ConfigurationError.connectionClosed))
                return
            }
            guard self.webSocketTask === webSocketTask else { return }
            self.webSocketTask = nil
            self.webSocketSessionID = nil
            self.webSocketReady = false
            self.isUploading = false
            if !self.pendingRecords.isEmpty {
                self.retryDelay = min(self.retryDelay * 2, 30)
                self.scheduleFlush(after: self.retryDelay)
            }
        }
    }

    private static func validSessionID(_ sessionID: String) -> String? {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
        guard !sessionID.isEmpty, sessionID.count <= 80, sessionID.unicodeScalars.allSatisfy(allowed.contains) else {
            return nil
        }
        return sessionID
    }

    private static func baseURL(from input: String) throws -> URL {
        let trimmedURL = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmedURL),
              components.scheme?.lowercased() == "ws",
              let host = components.host, !host.isEmpty,
              components.path.isEmpty || components.path == "/",
              components.query == nil, components.fragment == nil else {
            throw ConfigurationError.invalidURL
        }
        if components.port == nil {
            components.port = serverPort
        }
        guard let baseURL = components.url else { throw ConfigurationError.invalidURL }
        return baseURL
    }

    private static func webSocketURL(baseURL: URL, sessionID: String) -> URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
        components.path = "/ws/arkit/\(sessionID)"
        return components.url
    }

    private func loadQueueIfNeeded() {
        guard !didLoadQueue else { return }
        didLoadQueue = true
        guard let data = try? Data(contentsOf: queueFileURL),
              let text = String(data: data, encoding: .utf8) else { return }

        for line in text.split(whereSeparator: { $0.isNewline }) {
            guard let lineData = String(line).data(using: .utf8),
                  let record = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else { continue }
            pendingRecords.append(record)
        }
    }

    private func appendToDisk(_ record: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(record),
              let data = try? JSONSerialization.data(withJSONObject: record),
              let directory = try? FileManager.default.url(for: .applicationSupportDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil,
                                                            create: true) else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: queueFileURL.path) {
                FileManager.default.createFile(atPath: queueFileURL.path, contents: nil)
            }
            let handle = try FileHandle(forWritingTo: queueFileURL)
            defer { try? handle.close() }
            try handle.seekToEnd()
            var line = data
            line.append(0x0A)
            try handle.write(contentsOf: line)
        } catch {
            print("Realtime upload queue could not be written locally: \(error.localizedDescription)")
        }
    }

    private func persistQueueAtomically() {
        do {
            let directory = queueFileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let lines = try pendingRecords.map { record -> Data in
                try JSONSerialization.data(withJSONObject: record)
            }
            var data = Data()
            for line in lines {
                data.append(line)
                data.append(0x0A)
            }
            try data.write(to: queueFileURL, options: .atomic)
        } catch {
            print("Realtime upload queue could not be compacted: \(error.localizedDescription)")
        }
    }

    private func finishProbe(_ result: Result<Void, Error>) {
        guard let completion = probeCompletion else { return }
        probeCompletion = nil
        probeTask = nil
        DispatchQueue.main.async { completion(result) }
    }

    private enum ConfigurationError: LocalizedError {
        case invalidURL
        case invalidAcknowledgement
        case connectionClosed
        case connectionTimedOut

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Enter the Ubuntu WebSocket address, such as ws://192.168.1.20:8000."
            case .invalidAcknowledgement:
                return "The Ubuntu receiver did not acknowledge the JSON recording."
            case .connectionClosed:
                return "The Ubuntu receiver closed the WebSocket before confirming the connection."
            case .connectionTimedOut:
                return "Could not connect to the Ubuntu WebSocket endpoint within 6 seconds."
            }
        }
    }
}
