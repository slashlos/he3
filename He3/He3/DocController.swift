//
//  DocController.swift
//  He3 (Helium 3)
//
//  Created by Carlos D. Santiago on 5/9/20.
//  Copyright © 2020-2021 Carlos D. Santiago. All rights reserved.
//

import Foundation
import Cocoa
import OSLog

class DocumentController : NSDocumentController {
    static let poi = OSLog(subsystem: "com.slashlos.he3", category: .pointsOfInterest)

	@objc override func typeForContents(of url: URL) throws -> String {
		let type = [k.hpi:k.ItemType,
					k.h3i:k.ItemType,
					k.hpl:k.PlayType,
					k.h3l:k.PlayType,
					k.hic:k.IcntType][url.pathExtension] ?? k.ItemType
		return type
	}

    override func makeDocument(for urlOrNil: URL?, withContentsOf contentsURL: URL, ofType typeName: String) throws -> Document {
        os_signpost(.begin, log: MyWebView.poi, name: "makeDocument:3")
        defer { os_signpost(.end, log: DocumentController.poi, name: "makeDocument:3") }

		var doc: Document
         do {
			if [k.ItemType,k.IcntType,k.PlayType].contains(typeName)
			|| [k.ItemName,k.IcntName,k.PlayName].contains(typeName)
			|| [k.h3i,k.hpi,k.hic,k.h3l,k.hpl].contains(contentsURL.pathExtension) {
				doc = try super.makeDocument(for: urlOrNil, withContentsOf: contentsURL, ofType: typeName) as! Document
				return doc
            }
        } catch let error {
			print("\(error.localizedDescription)")
        }
		
		//	dynamic type names come here as workaround
		doc = try Document.init(contentsOf: contentsURL, ofType: typeName)
		doc.makeWindowControllers()
		doc.revertToSaved(self)

        return doc
    }

    override func makeDocument(withContentsOf url: URL, ofType typeName: String) throws -> Document {
        os_signpost(.begin, log: MyWebView.poi, name: "makeDocument:2")
        defer { os_signpost(.end, log: DocumentController.poi, name: "makeDocument:2") }

        var doc: Document
        do {
            doc = try self.makeDocument(for: url, withContentsOf: url, ofType: typeName)
        } catch let error {
            NSApp.presentError(error)
            doc = try self.makeUntitledDocument(ofType: typeName) as! Document
        }
		
		//	some URLs (asset: scheme) need explicit handling
		if 0 == doc.windowControllers.count { doc.makeWindowControllers() }
        return doc
    }
    
    override func makeUntitledDocument(ofType typeName: String) throws -> NSDocument {
        os_signpost(.begin, log: MyWebView.poi, name: "makeUntitledDocument")
        defer { os_signpost(.end, log: DocumentController.poi, name: "makeUntitledDocument") }

        var doc: Document
        do {
            doc = try super.makeUntitledDocument(ofType: typeName) as! Document
        } catch let error {
            NSApp.presentError(error)
            doc = try Document.init(type: typeName)
            doc.makeWindowControllers()
            doc.revertToSaved(self)
        }
        return doc
    }
    
    @objc @IBAction func altDocument(_ sender: NSMenuItem) {
        var doc: Document
        do {
			// MARK: toolTip *must* be English in all locales
			let typeName = sender.toolTip ?? k.Helium
			let fileType = [k.Helium:k.ItemType,
							k.PlayName:k.PlayType,
							k.IcntName:k.IcntType][typeName] ?? k.Helium
            doc = try makeUntitledDocument(ofType: fileType) as! Document
            if 0 == doc.windowControllers.count { doc.makeWindowControllers() }
			doc.showWindows()
        } catch let error {
            NSApp.presentError(error)
        }
    }
    
    class override func restoreWindow(withIdentifier identifier: NSUserInterfaceItemIdentifier, state: NSCoder, completionHandler: @escaping (NSWindow?, Error?) -> Void) {
        if (NSApp.delegate as! AppDelegate).disableDocumentReOpening {
            completionHandler(nil, NSError.init(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil) )
        }
        else
        {
			super.restoreWindow(withIdentifier: identifier, state: state, completionHandler: completionHandler)
        }
    }
}

