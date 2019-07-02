//
// Automat
//
// Copyright (c) 2019 Automat Berlin GmbH - https://automat.berlin/
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import AVFoundation

class DTMF {

    private static let dtmfFreqs: [String: [Float]] = {
        ["0": [ 941, 1336 ],
         "1": [ 697, 1209 ],
         "2": [ 697, 1336 ],
         "3": [ 697, 1477 ],
         "4": [ 770, 1209 ],
         "5": [ 770, 1336 ],
         "6": [ 770, 1477 ],
         "7": [ 852, 1209 ],
         "8": [ 852, 1336 ],
         "9": [ 852, 1477 ],
         "*": [ 941, 1209 ],
         "#": [ 941, 1477 ]]
    }()

    static func dtmf(for character: String) -> Data? {
        guard let freqValues = dtmfFreqs[character] else {
            return nil
        }

        let freq1 = freqValues[0]
        let freq2 = freqValues[1]

        let sampleRate: Int32 = 44100
        let duration: Int32 = 2
        let gain: Float32 = 0.5
        let subChunkSize: Int32 = 16
        let format: Int16 = 1
        let channels: Int16 = 2
        let bitsPerSample: Int16 = 16
        let byteRate: Int32 = sampleRate * Int32(channels * bitsPerSample / 8)
        let blockAlign: Int16 = channels * 2

        let header = NSMutableData()

        let frames = duration * sampleRate
        let payloadSize = frames * 2
        let chunkSize: Int32 = payloadSize + 36

        // RIFF
        header.append([UInt8]("RIFF".utf8), length: 4)
        header.append(chunkSize.byteArray(), length: 4)

        // WAVE
        header.append([UInt8]("WAVE".utf8), length: 4)

        // FMT
        header.append([UInt8]("fmt ".utf8), length: 4)

        header.append(subChunkSize.byteArray(), length: 4)
        header.append(format.byteArray(), length: 2)
        header.append(channels.byteArray(), length: 2)
        header.append(sampleRate.byteArray(), length: 4)
        header.append(byteRate.byteArray(), length: 4)
        header.append(blockAlign.byteArray(), length: 2)
        header.append(bitsPerSample.byteArray(), length: 2)

        header.append([UInt8]("data".utf8), length: 4)

        header.append(payloadSize.byteArray(), length: 4)

        for frame in 0..<Int(frames) {
            let soundWave = Int32(gain * (sinf(Float(frame) * 2.0 * .pi * freq1 / Float(sampleRate)) + sinf(Float(frame) * 2.0 * .pi * freq2 / Float(sampleRate))) * 0x7fff)

            header.append(soundWave.byteArray(), length: 4)
        }

        return header as Data
    }

}

extension SignedInteger {

    func byteArray() -> [UInt8] {
        var value = self
        return withUnsafeBytes(of: &value) { Array($0) }
    }
}
