import UIKit
import Vision

enum CameraRecognitionService {
    /// Analyzes a camera frame using Vision text + image classification.
    static func recognize(in image: UIImage) async -> [ServiceDetection] {
        guard let cgImage = image.cgImage else { return [] }

        async let textScores = recognizeText(in: cgImage)
        async let classScores = classifyImage(cgImage)

        let combined = await mergeScores(text: textScores, classification: classScores)
        return combined
            .sorted { $0.confidence > $1.confidence }
            .prefix(3)
            .map { $0 }
    }

    /// Demo-friendly: analyze a still image from camera buffer or photo.
    static func recognizeFromPixelBuffer(_ pixelBuffer: CVPixelBuffer) async -> [ServiceDetection] {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return [] }
        return await recognize(in: UIImage(cgImage: cgImage))
    }

    private static func recognizeText(in cgImage: CGImage) async -> [ServiceType: Double] {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let allText = observations
                    .compactMap { $0.topCandidates(1).first?.string.lowercased() }
                    .joined(separator: " ")

                var scores: [ServiceType: Double] = [:]
                for service in ServiceType.allCases {
                    let matches = service.recognitionKeywords.filter { allText.contains($0) }
                    if !matches.isEmpty {
                        scores[service] = min(0.95, 0.55 + Double(matches.count) * 0.12)
                    }
                }
                continuation.resume(returning: scores)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    private static func classifyImage(_ cgImage: CGImage) async -> [ServiceType: Double] {
        await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, _ in
                let observations = request.results as? [VNClassificationObservation] ?? []
                var scores: [ServiceType: Double] = [:]

                for observation in observations.prefix(15) {
                    let label = observation.identifier.lowercased()
                    for service in ServiceType.allCases {
                        if service.classificationLabels.contains(where: { label.contains($0) }) {
                            let existing = scores[service] ?? 0
                            scores[service] = max(existing, Double(observation.confidence))
                        }
                    }
                }
                continuation.resume(returning: scores)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    private static func mergeScores(
        text: [ServiceType: Double],
        classification: [ServiceType: Double]
    ) -> [ServiceDetection] {
        var merged: [ServiceType: (score: Double, methods: [String])] = [:]

        for (service, score) in text {
            merged[service] = (score * 0.6, ["text"])
        }
        for (service, score) in classification {
            if var existing = merged[service] {
                existing.score += score * 0.4
                existing.methods.append("vision")
                merged[service] = existing
            } else {
                merged[service] = (score * 0.4, ["vision"])
            }
        }

        return merged.map { service, value in
            ServiceDetection(
                service: service,
                confidence: min(0.98, value.score),
                method: value.methods.joined(separator: " + ")
            )
        }
    }
}
