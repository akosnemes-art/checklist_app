import Flutter
import ImageIO
import Vision

final class PhotoRecognition {
  private let queue = DispatchQueue(label: "checklist.vision", qos: .userInitiated)

  func register(with messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "checklist/ocr", binaryMessenger: messenger)
      .setMethodCallHandler { [self] call, result in
        guard let arguments = call.arguments as? [String: Any] else {
          result(FlutterError(code: "invalid_image", message: nil, details: nil))
          return
        }
        switch call.method {
        case "recognisePhoto":
          recognisePhoto(arguments, result: result)
        case "scanCameraFrame":
          scanFrame(arguments, result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }

  private func recognisePhoto(_ arguments: [String: Any], result: @escaping FlutterResult) {
    queue.async {
      let options: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: 1600,
      ]
      guard
        let path = arguments["path"] as? String,
        let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
        let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
      else {
        DispatchQueue.main.async {
          result(FlutterError(code: "invalid_image", message: nil, details: nil))
        }
        return
      }
      self.recognise(image, level: .accurate, result: result)
    }
  }

  private func scanFrame(_ arguments: [String: Any], result: @escaping FlutterResult) {
    queue.async {
      guard
        let bytes = arguments["luma"] as? FlutterStandardTypedData,
        let width = arguments["width"] as? Int, (1...4096).contains(width),
        let height = arguments["height"] as? Int, (1...4096).contains(height),
        let stride = arguments["rowStride"] as? Int, (width...8192).contains(stride),
        stride * height <= bytes.data.count,
        arguments["pixelStride"] as? Int == 1,
        let provider = CGDataProvider(data: bytes.data as CFData),
        let image = CGImage(
          width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8,
          bytesPerRow: stride, space: CGColorSpaceCreateDeviceGray(),
          bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
          provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
      else {
        DispatchQueue.main.async { result(["text": ""]) }
        return
      }
      // AVFoundation already rotates the pixel buffer to the device orientation.
      let ratio = arguments["aspectRatio"] as? Double ?? 0
      let cropped = self.cropToPreview(image, ratio: ratio)
      let orientation: CGImagePropertyOrientation =
        arguments["mirrored"] as? Bool == true ? .upMirrored : .up
      self.recognise(cropped, level: .fast, orientation: orientation, result: result)
    }
  }

  private func cropToPreview(_ image: CGImage, ratio: Double) -> CGImage {
    guard ratio.isFinite, ratio > 0 else { return image }
    let width = Double(image.width)
    let height = Double(image.height)
    let cropWidth = min(width, height * ratio)
    let cropHeight = min(height, width / ratio)
    let rect = CGRect(
      x: (width - cropWidth) / 2, y: (height - cropHeight) / 2,
      width: cropWidth, height: cropHeight)
    return image.cropping(to: rect.integral) ?? image
  }

  private func recognise(
    _ image: CGImage, level: VNRequestTextRecognitionLevel,
    orientation: CGImagePropertyOrientation = .up, result: @escaping FlutterResult
  ) {
    let text = VNRecognizeTextRequest()
    text.recognitionLevel = level
    text.usesLanguageCorrection = false
    let supported = (try? text.supportedRecognitionLanguages()) ?? []
    let languages = ["en", "hu"].compactMap { language in
      supported.first { $0 == language || $0.hasPrefix(language + "-") }
    }
    if !languages.isEmpty { text.recognitionLanguages = languages }
    let qr = VNDetectBarcodesRequest()
    qr.symbologies = [.qr]
    let handler = VNImageRequestHandler(cgImage: image, orientation: orientation, options: [:])

    do {
      try handler.perform([text, qr])
      let lines = (text.results ?? []).compactMap { $0.topCandidates(1).first?.string }
      var response = ["text": lines.joined(separator: "\n")]
      if let link = (qr.results ?? []).compactMap(\.payloadStringValue).first(where: isWebLink) {
        response["qr"] = link
      }
      DispatchQueue.main.async { result(response) }
    } catch {
      DispatchQueue.main.async {
        result(FlutterError(code: "recognition_failed", message: nil, details: nil))
      }
    }
  }

  private func isWebLink(_ payload: String) -> Bool {
    let address = payload.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !address.contains(where: \.isWhitespace) else { return false }
    let hasScheme = address.contains("://")
    let absolute = hasScheme ? address : "https://" + address
    guard let url = URL(string: absolute), let host = url.host, !host.isEmpty else {
      return false
    }
    let scheme = url.scheme?.lowercased()
    return (scheme == "https" || scheme == "http") && (hasScheme || host.contains("."))
  }
}
