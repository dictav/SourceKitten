//
//  SwiftDocs.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SwiftXPC

/// Represents docs for a Swift file.
public struct SwiftDocs {
    /// Docs information as an XPCDictionary.
    public let docsDictionary: XPCDictionary

    /**
    Create docs for the specified Swift file and compiler arguments.

    :param: file Swift file to document
    :param: arguments compiler arguments to pass to SourceKit
    */
    public init(file: File, arguments: [String]) {
        self.init(
            file: file,
            dictionary: Request.EditorOpen(file).send(),
            cursorInfoRequest: Request.cursorInfoRequestForFilePath(file.path, arguments: arguments)
        )
    }

    /**
    Create docs for the specified Swift file, editor.open SourceKit response and cursor info request.

    :param: file Swift file to document
    :param: dictionary editor.open response from SourceKit
    :param: cursorInfoRequest SourceKit xpc dictionary to use to send cursorinfo request.
    */
    public init(file: File, var dictionary: XPCDictionary, cursorInfoRequest: xpc_object_t?) {
        let syntaxMapData = dictionary.removeValueForKey(SwiftDocKey.SyntaxMap.rawValue) as! NSData
        let syntaxMap = SyntaxMap(data: syntaxMapData)
        dictionary = file.processDictionary(dictionary, cursorInfoRequest: cursorInfoRequest, syntaxMap: syntaxMap)
        if let cursorInfoRequest = cursorInfoRequest {
            let documentedTokenOffsets = file.contents.documentedTokenOffsets(syntaxMap)
            dictionary = file.furtherProcessDictionary(
                dictionary,
                documentedTokenOffsets: documentedTokenOffsets,
                cursorInfoRequest: cursorInfoRequest,
                syntaxMap: syntaxMap
            )
        }
        docsDictionary = dictionary
    }
}

// MARK: Printable

extension SwiftDocs: Printable {
    /// A textual JSON representation of `SwiftDocs`.
    public var description: String { return toJSON(docsDictionary) }
}
