//
//  CastTrustResponder.swift
//  iTorrent
//

import SwiftVLC

@MainActor
final class CastTrustResponder {
    static let shared = CastTrustResponder()

    private var handler: DialogHandler?
    private var task: Task<Void, Never>?

    func start() {
        guard handler == nil else { return }

        let handler = DialogHandler(instance: .shared)
        self.handler = handler
        let dialogs = handler.dialogs

        task = Task.detached {
            for await event in dialogs {
                guard case .question(let request) = event else { continue }

                if request.isCertificateTrust || request.isCastPerformanceWarning {
                    request.post(action: 1)
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        handler = nil
    }
}

private extension QuestionRequest {
    var isCertificateTrust: Bool {
        action1Text?.localizedCaseInsensitiveContains("certificate") == true
            || title.localizedCaseInsensitiveContains("insecure")
            || text.localizedCaseInsensitiveContains("certificate")
    }

    var isCastPerformanceWarning: Bool {
        title.localizedCaseInsensitiveContains("performance")
            || text.localizedCaseInsensitiveContains("performance")
    }
}
