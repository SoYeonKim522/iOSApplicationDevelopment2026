//
//  OpenAIAudioEncoder.swift
//  IELTSBuddy
//

import AVFoundation
import Foundation

enum OpenAIAudioEncoderError: LocalizedError {
    case unreadableFile
    case exportFailed(String?)

    var errorDescription: String? {
        switch self {
        case .unreadableFile:
            return "The recorded audio file could not be read."
        case .exportFailed(let detail):
            if let detail, !detail.isEmpty {
                return "Failed to prepare audio for evaluation: \(detail)"
            }
            return "Failed to prepare audio for evaluation."
        }
    }
}

enum OpenAIAudioEncoder {
    private static let shineSupportedSampleRates = [8_000, 11_025, 12_000, 16_000, 22_050, 24_000, 32_000, 44_100, 48_000]

    /// Returns base64-encoded MP3 audio and `format = "mp3"` for the OpenAI payload.
    static func base64EncodedAudio(from sourceURL: URL) async throws -> (data: String, format: String) {
        let mp3URL = try await exportToMP3(sourceURL: sourceURL)
        defer { try? FileManager.default.removeItem(at: mp3URL) }

        let audioData = try Data(contentsOf: mp3URL)
        guard !audioData.isEmpty else {
            throw OpenAIAudioEncoderError.unreadableFile
        }

        return (audioData.base64EncodedString(), "mp3")
    }

    private static func exportToMP3(sourceURL: URL) async throws -> URL {
        let pcm = try await extractPCM(from: sourceURL)
        let preparedPCM = try resampleIfNeeded(pcm)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("openai-audio-\(UUID().uuidString).mp3")

        let status = preparedPCM.samples.withUnsafeBufferPointer { buffer in
            outputURL.path.withCString { path in
                openai_encode_pcm_to_mp3(
                    buffer.baseAddress,
                    Int32(buffer.count),
                    Int32(preparedPCM.sampleRate),
                    Int32(preparedPCM.channels),
                    path
                )
            }
        }

        guard status == 0 else {
            throw OpenAIAudioEncoderError.exportFailed("MP3 encoding failed (code \(status)).")
        }

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw OpenAIAudioEncoderError.exportFailed("MP3 output file was not created.")
        }

        return outputURL
    }

    private struct PCMBuffer {
        let samples: [Int16]
        let sampleRate: Int
        let channels: Int
    }

    private static func extractPCM(from sourceURL: URL) async throws -> PCMBuffer {
        let asset = AVURLAsset(url: sourceURL)
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard let track = tracks.first else {
            throw OpenAIAudioEncoderError.unreadableFile
        }

        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ]

        let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        guard reader.canAdd(output) else {
            throw OpenAIAudioEncoderError.exportFailed("Unable to configure audio reader.")
        }
        reader.add(output)

        guard reader.startReading() else {
            throw OpenAIAudioEncoderError.exportFailed(reader.error?.localizedDescription)
        }

        var samples: [Int16] = []
        var sampleRate = 44_100
        var channels = 1

        while reader.status == .reading {
            guard let sampleBuffer = output.copyNextSampleBuffer() else { break }

            if let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
               let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) {
                sampleRate = Int(streamDescription.pointee.mSampleRate.rounded())
                channels = max(1, Int(streamDescription.pointee.mChannelsPerFrame))
            }

            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }

            var dataLength = 0
            var dataPointer: UnsafeMutablePointer<Int8>?
            let blockStatus = CMBlockBufferGetDataPointer(
                blockBuffer,
                atOffset: 0,
                lengthAtOffsetOut: nil,
                totalLengthOut: &dataLength,
                dataPointerOut: &dataPointer
            )
            guard blockStatus == kCMBlockBufferNoErr, let dataPointer, dataLength > 0 else { continue }

            let sampleCount = dataLength / MemoryLayout<Int16>.size
            dataPointer.withMemoryRebound(to: Int16.self, capacity: sampleCount) { pointer in
                samples.append(contentsOf: UnsafeBufferPointer(start: pointer, count: sampleCount))
            }
        }

        if reader.status == .failed {
            throw OpenAIAudioEncoderError.exportFailed(reader.error?.localizedDescription)
        }

        guard !samples.isEmpty else {
            throw OpenAIAudioEncoderError.unreadableFile
        }

        return PCMBuffer(samples: samples, sampleRate: sampleRate, channels: channels)
    }

    private static func resampleIfNeeded(_ pcm: PCMBuffer) throws -> PCMBuffer {
        if shineSupportedSampleRates.contains(pcm.sampleRate) {
            return pcm
        }

        let targetRate = 44_100
        let inputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: Double(pcm.sampleRate),
            channels: AVAudioChannelCount(pcm.channels),
            interleaved: true
        )
        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: Double(targetRate),
            channels: AVAudioChannelCount(pcm.channels),
            interleaved: true
        )

        guard let inputFormat, let outputFormat else {
            throw OpenAIAudioEncoderError.exportFailed("Unsupported PCM format.")
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw OpenAIAudioEncoderError.exportFailed("Unable to resample audio.")
        }

        let frameCapacity = AVAudioFrameCount(pcm.samples.count / pcm.channels)
        guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: frameCapacity) else {
            throw OpenAIAudioEncoderError.exportFailed("Unable to allocate input buffer.")
        }

        inputBuffer.frameLength = frameCapacity
        pcm.samples.withUnsafeBufferPointer { source in
            guard let channelData = inputBuffer.int16ChannelData else { return }
            channelData[0].update(from: source.baseAddress!, count: pcm.samples.count)
        }

        let estimatedOutputFrames = AVAudioFrameCount(
            Double(frameCapacity) * Double(targetRate) / Double(pcm.sampleRate)
        ) + 1
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: estimatedOutputFrames) else {
            throw OpenAIAudioEncoderError.exportFailed("Unable to allocate output buffer.")
        }

        var conversionError: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }

        converter.convert(to: outputBuffer, error: &conversionError, withInputFrom: inputBlock)

        if let conversionError {
            throw OpenAIAudioEncoderError.exportFailed(conversionError.localizedDescription)
        }

        guard let channelData = outputBuffer.int16ChannelData else {
            throw OpenAIAudioEncoderError.exportFailed("Resampling produced no audio.")
        }

        let outputSampleCount = Int(outputBuffer.frameLength) * pcm.channels
        let resampled = Array(UnsafeBufferPointer(start: channelData[0], count: outputSampleCount))

        guard !resampled.isEmpty else {
            throw OpenAIAudioEncoderError.exportFailed("Resampling produced no audio.")
        }

        return PCMBuffer(samples: resampled, sampleRate: targetRate, channels: pcm.channels)
    }
}
