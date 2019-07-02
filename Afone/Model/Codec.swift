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

import Foundation

struct Codec: Equatable, Codable {
    enum CodecType: Int, Codable {
        case audio
        case video
    }

    var name: String
    var type: CodecType
    var value: Any

    static func == (lhs: Codec, rhs: Codec) -> Bool {
        return lhs.name == rhs.name &&
            lhs.type == rhs.type
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case type
        case value
    }

    init(name: String, type: CodecType, value: Any) {
        self.name = name
        self.type = type
        self.value = value
    }

    init(from decoder: Decoder) throws {
        do {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            name = try values.decode(String.self, forKey: .name)
            type = try values.decode(CodecType.self, forKey: .type)
            if let newValue = try? values.decode(String.self, forKey: .value) {
                value = newValue
            } else if let newValue = try? values.decode(Int.self, forKey: .value) {
                value = newValue
            } else if let newValue = try? values.decode(Int8.self, forKey: .value) {
                value = newValue
            } else if let newValue = try? values.decode(Int16.self, forKey: .value) {
                value = newValue
            } else if let newValue = try? values.decode(Int32.self, forKey: .value) {
                value = newValue
            } else if let newValue = try? values.decode(Int64.self, forKey: .value) {
                value = newValue
            } else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: values.codingPath, debugDescription: "Couldn't get value for value"))
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        switch value {
        case let int as Int:
            try container.encode(int, forKey: .value)
        case let int8 as Int8:
            try container.encode(int8, forKey: .value)
        case let int16 as Int16:
            try container.encode(int16, forKey: .value)
        case let int32 as Int32:
            try container.encode(int32, forKey: .value)
        case let int64 as Int64:
            try container.encode(int64, forKey: .value)
        case let string as String:
            try container.encode(string, forKey: .value)
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "Value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
}
