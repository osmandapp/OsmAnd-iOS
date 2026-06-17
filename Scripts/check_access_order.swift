#!/usr/bin/env swift

import Foundation

private enum AccessGroup: Hashable {
    case open
    case publicOnly
    case package
    case internalOnly
    case privateOnly
    case fileprivateOnly

    var order: Int {
        switch self {
        case .open:
            return 0
        case .publicOnly:
            return 1
        case .package:
            return 2
        case .internalOnly:
            return 3
        case .privateOnly:
            return 4
        case .fileprivateOnly:
            return 5
        }
    }

    var displayName: String {
        switch self {
        case .open:
            return "open"
        case .publicOnly:
            return "public"
        case .package:
            return "package"
        case .internalOnly:
            return "internal"
        case .privateOnly:
            return "private"
        case .fileprivateOnly:
            return "fileprivate"
        }
    }
}

private enum MemberBucket: String, CaseIterable {
    case instanceProperty
    case typeProperty
    case instanceMethod
    case typeMethod

    var displayName: String {
        switch self {
        case .instanceProperty:
            return "instance property"
        case .typeProperty:
            return "type property"
        case .instanceMethod:
            return "instance method"
        case .typeMethod:
            return "type method"
        }
    }

    var pluralDisplayName: String {
        switch self {
        case .instanceProperty:
            return "instance properties"
        case .typeProperty:
            return "type properties"
        case .instanceMethod:
            return "instance methods"
        case .typeMethod:
            return "type methods"
        }
    }
}

private struct TypeContext {
    let bodyDepth: Int
    var lastAccessGroup: [MemberBucket: AccessGroup] = [:]
    var sawWeakProperty: [AccessGroup: Set<MemberBucket>] = [:]

    mutating func markAccessGroup(_ accessGroup: AccessGroup, bucket: MemberBucket) {
        let current = lastAccessGroup[bucket]
        if current == nil || accessGroup.order > current!.order {
            lastAccessGroup[bucket] = accessGroup
        }
    }

    mutating func markWeakProperty(_ bucket: MemberBucket, accessGroup: AccessGroup) {
        sawWeakProperty[accessGroup, default: []].insert(bucket)
    }

    func hasSeenMoreRestrictiveAccessGroup(
        than accessGroup: AccessGroup,
        bucket: MemberBucket
    ) -> AccessGroup? {
        guard let current = lastAccessGroup[bucket], current.order > accessGroup.order else {
            return nil
        }
        return current
    }

    func hasSeenWeakProperty(_ bucket: MemberBucket, accessGroup: AccessGroup) -> Bool {
        sawWeakProperty[accessGroup]?.contains(bucket) == true
    }
}

private struct MemberDeclaration {
    let bucket: MemberBucket
    let accessGroup: AccessGroup
    let isWeakProperty: Bool
}

private func accessGroup(from tokens: [String]) -> AccessGroup {
    if tokens.contains("open") {
        return .open
    }
    if tokens.contains("public") {
        return .publicOnly
    }
    if tokens.contains("package") {
        return .package
    }
    if tokens.contains("fileprivate") {
        return .fileprivateOnly
    }
    if tokens.contains("private") {
        return .privateOnly
    }
    return .internalOnly
}

private let ignoredAttributeNames: Set<String> = [
    "IBAction",
    "IBInspectable",
    "IBOutlet",
    "IBSegueAction"
]

private func inputFiles() -> [String] {
    let arguments = Array(CommandLine.arguments.dropFirst())
    if !arguments.isEmpty {
        return arguments
    }

    let environment = ProcessInfo.processInfo.environment
    guard let countString = environment["SCRIPT_INPUT_FILE_COUNT"],
          let count = Int(countString),
          count > 0 else {
        return []
    }

    return (0..<count).compactMap { environment["SCRIPT_INPUT_FILE_\($0)"] }
}

private func codeWithoutCommentsAndStrings(
    from line: String,
    inBlockComment: inout Bool
) -> String {
    var result = ""
    var index = line.startIndex
    var inString = false
    var escaped = false

    while index < line.endIndex {
        let character = line[index]
        let nextIndex = line.index(after: index)
        let nextCharacter = nextIndex < line.endIndex ? line[nextIndex] : nil

        if inBlockComment {
            if character == "*", nextCharacter == "/" {
                inBlockComment = false
                index = line.index(after: nextIndex)
            } else {
                index = nextIndex
            }
            continue
        }

        if inString {
            if escaped {
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == "\"" {
                inString = false
            }
            index = nextIndex
            continue
        }

        if character == "/", nextCharacter == "/" {
            break
        }

        if character == "/", nextCharacter == "*" {
            inBlockComment = true
            index = line.index(after: nextIndex)
            continue
        }

        if character == "\"" {
            inString = true
            index = nextIndex
            continue
        }

        result.append(character)
        index = nextIndex
    }

    return result
}

private func braceDelta(in code: String) -> Int {
    code.reduce(0) { delta, character in
        switch character {
        case "{":
            return delta + 1
        case "}":
            return delta - 1
        default:
            return delta
        }
    }
}

private func opensTypeDeclaration(_ code: String) -> Bool {
    let pattern = #"(^|[^A-Za-z0-9_])(actor|class|enum|extension|protocol|struct)([^A-Za-z0-9_]|$).*[\{]"#
    return code.range(of: pattern, options: .regularExpression) != nil
}

private func attributeNames(in text: String) -> Set<String> {
    let pattern = #"@([A-Za-z_][A-Za-z0-9_]*)"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return []
    }

    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return Set(regex.matches(in: text, range: range).compactMap { match in
        guard let nameRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[nameRange])
    })
}

private func tokens(before declarationKeyword: String, in code: String) -> [String]? {
    guard let range = code.range(
        of: #"(^|[^A-Za-z0-9_])\#(declarationKeyword)([^A-Za-z0-9_]|$)"#,
        options: .regularExpression
    ) else {
        return nil
    }

    let prefix = String(code[..<range.lowerBound])
        .replacingOccurrences(of: #"private\s*\(set\)"#, with: " ", options: .regularExpression)
        .replacingOccurrences(of: #"fileprivate\s*\(set\)"#, with: " ", options: .regularExpression)
    return prefix.split { !$0.isLetter && !$0.isNumber && $0 != "_" }.map(String.init)
}

private func memberDeclaration(from code: String, pendingAttributes: [String]) -> MemberDeclaration? {
    let combinedAttributes = attributeNames(in: (pendingAttributes + [code]).joined(separator: "\n"))
    if !combinedAttributes.isDisjoint(with: ignoredAttributeNames) {
        return nil
    }

    if let propertyTokens = tokens(before: "var|let", in: code) {
        let isTypeMember = propertyTokens.contains("static") || propertyTokens.contains("class")
        let accessGroup = accessGroup(from: propertyTokens)

        return MemberDeclaration(
            bucket: isTypeMember ? .typeProperty : .instanceProperty,
            accessGroup: accessGroup,
            isWeakProperty: propertyTokens.contains("weak")
        )
    }

    if let methodTokens = tokens(before: "func", in: code) {
        if methodTokens.contains("override") {
            return nil
        }

        let isTypeMember = methodTokens.contains("static") || methodTokens.contains("class")
        let accessGroup = accessGroup(from: methodTokens)

        return MemberDeclaration(
            bucket: isTypeMember ? .typeMethod : .instanceMethod,
            accessGroup: accessGroup,
            isWeakProperty: false
        )
    }

    return nil
}

private func check(filePath: String) -> Int {
    guard filePath.hasSuffix(".swift") else {
        return 0
    }

    guard let contents = try? String(contentsOfFile: filePath, encoding: .utf8) else {
        return 0
    }

    var violationCount = 0
    var braceDepth = 0
    var inBlockComment = false
    var contexts: [TypeContext] = []
    var pendingAttributes: [String] = []
    let lines = contents.components(separatedBy: .newlines)

    for (offset, line) in lines.enumerated() {
        let lineNumber = offset + 1
        let code = codeWithoutCommentsAndStrings(from: line, inBlockComment: &inBlockComment)
        let trimmedCode = code.trimmingCharacters(in: .whitespaces)

        while let context = contexts.last, braceDepth < context.bodyDepth {
            contexts.removeLast()
        }

        if trimmedCode.hasPrefix("@") {
            pendingAttributes.append(trimmedCode)
        } else if !trimmedCode.isEmpty, !trimmedCode.hasPrefix("#") {
            if contexts.last?.bodyDepth == braceDepth,
               let member = memberDeclaration(from: trimmedCode, pendingAttributes: pendingAttributes) {
                if member.bucket == .instanceProperty || member.bucket == .typeProperty {
                    if member.isWeakProperty {
                        contexts[contexts.count - 1].markWeakProperty(
                            member.bucket,
                            accessGroup: member.accessGroup
                        )
                    } else if contexts[contexts.count - 1].hasSeenWeakProperty(
                        member.bucket,
                        accessGroup: member.accessGroup
                    ) {
                        print("\(filePath):\(lineNumber):1: warning: Non-weak \(member.accessGroup.displayName) \(member.bucket.displayName) should be declared before weak \(member.bucket.pluralDisplayName) (property_access_order)")
                        violationCount += 1
                    }
                }

                if let moreRestrictiveAccessGroup = contexts[contexts.count - 1]
                    .hasSeenMoreRestrictiveAccessGroup(
                        than: member.accessGroup,
                        bucket: member.bucket
                    ) {
                    print("\(filePath):\(lineNumber):1: warning: \(member.accessGroup.displayName.capitalized) \(member.bucket.displayName) should be declared before \(moreRestrictiveAccessGroup.displayName) \(member.bucket.pluralDisplayName) (access_control_order)")
                    violationCount += 1
                }

                contexts[contexts.count - 1].markAccessGroup(member.accessGroup, bucket: member.bucket)
            }

            pendingAttributes.removeAll()
        }

        if opensTypeDeclaration(trimmedCode) {
            contexts.append(TypeContext(bodyDepth: braceDepth + 1))
        }

        braceDepth += braceDelta(in: code)
    }

    return violationCount
}

let files = inputFiles()
_ = files.reduce(0) { count, filePath in
    count + check(filePath: filePath)
}

exit(0)
