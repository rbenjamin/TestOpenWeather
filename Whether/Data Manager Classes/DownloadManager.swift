//
//  DownloadManager.swift
//  Whether
//
//  Created by Ben Davis on 11/21/24.
//

import Foundation

actor DownloadManager: NSObject {
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }()

    private static let mimeType = "application/json"

    private var downloads = [URL: URLSessionDataTask]()
    /**
     `download(url:)` queues multiple `URLSessionDataTask` downloads for URLSession. This ensures we don't receive a `.cancelled` by starting a new task while another task is executing.
     */
    public func download(url: URL) async throws -> Data? {
//        print("download for url: \(url)")
        guard self.downloads[url] == nil else {
            print("Download already in progress for \(url)")
            return nil
        }
        let result: Data? = try await withCheckedThrowingContinuation { continuation in
            downloadData(forURL: url) {  result in

                switch result {
                case .success(let success):
                    guard let success else {
                        print("data == nil!")
                        return
                    }
                    continuation.resume(returning: success)
                case .failure(let failure):
                    continuation.resume(throwing: failure)
                }
            }
        }
        self.downloads.removeValue(forKey: url)
        return result
    }
    /**
     `downloadData(forURL: completion:)` is a private function, called by `download(url:)`, converting completion handler URLSession dataTask call into an async call locally.
     
     */
    private func downloadData(forURL url: URL, completion: @escaping (Result<Data?, Error>) -> Void) {
        let task = self.urlSession.dataTask(with: URLRequest(url: url)) { data, response, error in
            guard let response = response as? HTTPURLResponse,
                  (200...299).contains(response.statusCode),
                  let mimeType = response.mimeType,
                  mimeType == Self.mimeType else {
                completion(.failure(DownloadError.mimeTypeFailure(failureReason: "Wrong mime type: \(response?.mimeType ?? "N/A") should be \(Self.mimeType).")))
                return
            }
            if let error {
                completion(.failure(error))
            }
            completion(.success(data))
        }
        self.downloads[url] = task
        task.resume()
    }
}
