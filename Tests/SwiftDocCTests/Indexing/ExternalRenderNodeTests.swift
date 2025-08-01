/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2025 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation
import XCTest
@_spi(ExternalLinks) @testable import SwiftDocC

class ExternalRenderNodeTests: XCTestCase {
    func generateExternalResover() -> TestMultiResultExternalReferenceResolver {
        let externalResolver = TestMultiResultExternalReferenceResolver()
        externalResolver.bundleID = "com.test.external"
        externalResolver.entitiesToReturn["/path/to/external/swiftArticle"] = .success(
            .init(
                    referencePath: "/path/to/external/swiftArticle",
                    title: "SwiftArticle",
                    kind: .article,
                    language: .swift
                )
        )
        externalResolver.entitiesToReturn["/path/to/external/objCArticle"] = .success(
            .init(
                    referencePath: "/path/to/external/objCArticle",
                    title: "ObjCArticle",
                    kind: .article,
                    language: .objectiveC
                )
        )
        externalResolver.entitiesToReturn["/path/to/external/swiftSymbol"] = .success(
            .init(
                referencePath: "/path/to/external/swiftSymbol",
                title: "SwiftSymbol",
                kind: .class,
                language: .swift
            )
        )
        externalResolver.entitiesToReturn["/path/to/external/objCSymbol"] = .success(
            .init(
                referencePath: "/path/to/external/objCSymbol",
                title: "ObjCSymbol",
                kind: .function,
                language: .objectiveC
            )
        )
        return externalResolver
    }
        
    func testExternalRenderNode() throws {
        
        let externalResolver = generateExternalResover()
        let (_, bundle, context) = try testBundleAndContext(
            copying: "MixedLanguageFramework",
            externalResolvers: [externalResolver.bundleID: externalResolver]
        ) { url in
            let mixedLanguageFrameworkExtension = """
                # ``MixedLanguageFramework``
                
                This symbol has a Swift and Objective-C variant.

                ## Topics
                
                ### External Reference

                - <doc://com.test.external/path/to/external/swiftArticle>
                - <doc://com.test.external/path/to/external/swiftSymbol>
                - <doc://com.test.external/path/to/external/objCArticle>
                - <doc://com.test.external/path/to/external/objCSymbol>
                """
            try mixedLanguageFrameworkExtension.write(to: url.appendingPathComponent("/MixedLanguageFramework.md"), atomically: true, encoding: .utf8)
        }
        
        var externalRenderNodes = [ExternalRenderNode]()
        for externalLink in context.externalCache {
            externalRenderNodes.append(
                ExternalRenderNode(externalEntity: externalLink.value, bundleIdentifier: bundle.id)
            )
        }
        externalRenderNodes.sort(by: \.titleVariants.defaultValue)
        XCTAssertEqual(externalRenderNodes.count, 4)
        
        XCTAssertEqual(externalRenderNodes[0].identifier.absoluteString, "doc://org.swift.MixedLanguageFramework/example/path/to/external/objCArticle")
        XCTAssertEqual(externalRenderNodes[0].kind, .article)
        XCTAssertEqual(externalRenderNodes[0].symbolKind, nil)
        XCTAssertEqual(externalRenderNodes[0].role, "article")
        XCTAssertEqual(externalRenderNodes[0].externalIdentifier.identifier, "doc://com.test.external/path/to/external/objCArticle")
        
        XCTAssertEqual(externalRenderNodes[1].identifier.absoluteString, "doc://org.swift.MixedLanguageFramework/example/path/to/external/objCSymbol")
        XCTAssertEqual(externalRenderNodes[1].kind, .symbol)
        XCTAssertEqual(externalRenderNodes[1].symbolKind, nil)
        XCTAssertEqual(externalRenderNodes[1].role, "symbol")
        XCTAssertEqual(externalRenderNodes[1].externalIdentifier.identifier, "doc://com.test.external/path/to/external/objCSymbol")
        
        XCTAssertEqual(externalRenderNodes[2].identifier.absoluteString, "doc://org.swift.MixedLanguageFramework/example/path/to/external/swiftArticle")
        XCTAssertEqual(externalRenderNodes[2].kind, .article)
        XCTAssertEqual(externalRenderNodes[2].symbolKind, nil)
        XCTAssertEqual(externalRenderNodes[2].role, "article")
        XCTAssertEqual(externalRenderNodes[2].externalIdentifier.identifier, "doc://com.test.external/path/to/external/swiftArticle")
        
        XCTAssertEqual(externalRenderNodes[3].identifier.absoluteString, "doc://org.swift.MixedLanguageFramework/example/path/to/external/swiftSymbol")
        XCTAssertEqual(externalRenderNodes[3].kind, .symbol)
        XCTAssertEqual(externalRenderNodes[3].symbolKind, nil)
        XCTAssertEqual(externalRenderNodes[3].role, "symbol")
        XCTAssertEqual(externalRenderNodes[3].externalIdentifier.identifier, "doc://com.test.external/path/to/external/swiftSymbol")
    }
    
    func testExternalRenderNodeVariantRepresentation() throws {
        let renderReferenceIdentifier = RenderReferenceIdentifier(forExternalLink: "doc://com.test.external/path/to/external/symbol")
        
        // Variants for the title
        let swiftTitle = "Swift Symbol"
        let occTitle = "Occ Symbol"
        
        // Variants for the navigator title
        let navigatorTitle: [DeclarationRenderSection.Token] = [.init(text: "symbol", kind: .identifier)]
        let occNavigatorTitle: [DeclarationRenderSection.Token] = [.init(text: "occ_symbol", kind: .identifier)]
        
        // Variants for the fragments
        let fragments: [DeclarationRenderSection.Token] = [.init(text: "func", kind: .keyword), .init(text: "symbol", kind: .identifier)]
        let occFragments: [DeclarationRenderSection.Token] = [.init(text: "func", kind: .keyword), .init(text: "occ_symbol", kind: .identifier)]
        
        let externalEntity = LinkResolver.ExternalEntity(
            topicRenderReference: .init(
                identifier: renderReferenceIdentifier,
                titleVariants: .init(defaultValue: swiftTitle, objectiveCValue: occTitle),
                abstractVariants: .init(defaultValue: []),
                url: "/example/path/to/external/symbol",
                kind: .symbol,
                fragmentsVariants: .init(defaultValue: fragments, objectiveCValue: occFragments),
                navigatorTitleVariants: .init(defaultValue: navigatorTitle, objectiveCValue: occNavigatorTitle)
            ),
            renderReferenceDependencies: .init(),
            sourceLanguages: [SourceLanguage(name: "swift"), SourceLanguage(name: "objc")])
        let externalRenderNode = ExternalRenderNode(
            externalEntity: externalEntity,
            bundleIdentifier: "com.test.external"
        )
        
        let swiftNavigatorExternalRenderNode = try XCTUnwrap(
            NavigatorExternalRenderNode(renderNode: externalRenderNode)
        )
        XCTAssertEqual(swiftNavigatorExternalRenderNode.metadata.title, swiftTitle)
        XCTAssertEqual(swiftNavigatorExternalRenderNode.metadata.navigatorTitle, navigatorTitle)
        
        let objcNavigatorExternalRenderNode = try XCTUnwrap(
            NavigatorExternalRenderNode(renderNode: externalRenderNode, trait: .interfaceLanguage("objc"))
        )
        XCTAssertEqual(objcNavigatorExternalRenderNode.metadata.title, occTitle)
        XCTAssertEqual(objcNavigatorExternalRenderNode.metadata.navigatorTitle, occNavigatorTitle)
    }
    
    func testNavigatorWithExternalNodes() throws {
        let externalResolver = generateExternalResover()
        let (_, bundle, context) = try testBundleAndContext(
            copying: "MixedLanguageFramework",
            externalResolvers: [externalResolver.bundleID: externalResolver]
        ) { url in
            let mixedLanguageFrameworkExtension = """
                # ``MixedLanguageFramework``
                
                This symbol has a Swift and Objective-C variant.

                ## Topics

                ### External Reference

                - <doc://com.test.external/path/to/external/swiftArticle>
                - <doc://com.test.external/path/to/external/swiftSymbol>
                - <doc://com.test.external/path/to/external/objCArticle>
                - <doc://com.test.external/path/to/external/objCSymbol>
                """
            try mixedLanguageFrameworkExtension.write(to: url.appendingPathComponent("/MixedLanguageFramework.md"), atomically: true, encoding: .utf8)
        }
        let renderContext = RenderContext(documentationContext: context, bundle: bundle)
        let converter = DocumentationContextConverter(bundle: bundle, context: context, renderContext: renderContext)
        let targetURL = try createTemporaryDirectory()
        let builder = NavigatorIndex.Builder(outputURL: targetURL, bundleIdentifier: bundle.id.rawValue, sortRootChildrenByName: true, groupByLanguage: true)
        builder.setup()
        for externalLink in context.externalCache {
            let externalRenderNode = ExternalRenderNode(externalEntity: externalLink.value, bundleIdentifier: bundle.id)
            try builder.index(renderNode: externalRenderNode)
        }
        for identifier in context.knownPages {
            let entity = try context.entity(with: identifier)
            let renderNode = try XCTUnwrap(converter.renderNode(for: entity))
            try builder.index(renderNode: renderNode)
        }
        builder.finalize()
        let renderIndex = try RenderIndex.fromURL(targetURL.appendingPathComponent("index.json"))

        // Verify that there are no uncurated external links at the top level
        let swiftTopLevelExternalNodes = renderIndex.interfaceLanguages["swift"]?.filter { $0.path?.contains("/path/to/external") ?? false } ?? []
        let occTopLevelExternalNodes = renderIndex.interfaceLanguages["occ"]?.filter { $0.path?.contains("/path/to/external") ?? false } ?? []
        XCTAssertEqual(swiftTopLevelExternalNodes.count, 0)
        XCTAssertEqual(occTopLevelExternalNodes.count, 0)

        // Verify that the curated external links are part of the index.
        let swiftExternalNodes = renderIndex.interfaceLanguages["swift"]?.first { $0.path == "/documentation/mixedlanguageframework" }?.children?.filter { $0.path?.contains("/path/to/external") ?? false } ?? []
        let occExternalNodes = renderIndex.interfaceLanguages["occ"]?.first { $0.path == "/documentation/mixedlanguageframework" }?.children?.filter { $0.path?.contains("/path/to/external") ?? false } ?? []
        XCTAssertEqual(swiftExternalNodes.count, 2)
        XCTAssertEqual(occExternalNodes.count, 2)
        XCTAssertEqual(swiftExternalNodes.map(\.title), ["SwiftArticle", "SwiftSymbol"])
        XCTAssertEqual(occExternalNodes.map(\.title), ["ObjCArticle", "ObjCSymbol"])
        XCTAssert(swiftExternalNodes.allSatisfy(\.isExternal))
        XCTAssert(occExternalNodes.allSatisfy(\.isExternal))
    }
    
    func testNavigatorWithExternalNodesOnlyAddsCuratedNodesToNavigator() throws {
        let externalResolver = generateExternalResover()
        
        let (_, bundle, context) = try testBundleAndContext(
            copying: "MixedLanguageFramework",
            externalResolvers: [externalResolver.bundleID: externalResolver]
        ) { url in
            let mixedLanguageFrameworkExtension = """
                # ``MixedLanguageFramework``
                
                This symbol has a Swift and Objective-C variant.
                
                It also has an external reference which is not curated in the Topics section:
                <doc://com.test.external/path/to/external/objCArticle>
                <doc://com.test.external/path/to/external/swiftSymbol>
                
                ## Topics
                
                ### External Reference
                
                - <doc://com.test.external/path/to/external/swiftArticle>
                - <doc://com.test.external/path/to/external/objCSymbol>
                """
            try mixedLanguageFrameworkExtension.write(to: url.appendingPathComponent("/MixedLanguageFramework.md"), atomically: true, encoding: .utf8)
        }
        let renderContext = RenderContext(documentationContext: context, bundle: bundle)
        let converter = DocumentationContextConverter(bundle: bundle, context: context, renderContext: renderContext)
        let targetURL = try createTemporaryDirectory()
        let builder = NavigatorIndex.Builder(outputURL: targetURL, bundleIdentifier: bundle.id.rawValue, sortRootChildrenByName: true, groupByLanguage: true)
        builder.setup()
        for externalLink in context.externalCache {
            let externalRenderNode = ExternalRenderNode(externalEntity: externalLink.value, bundleIdentifier: bundle.id)
            try builder.index(renderNode: externalRenderNode)
        }
        for identifier in context.knownPages {
            let entity = try context.entity(with: identifier)
            let renderNode = try XCTUnwrap(converter.renderNode(for: entity))
            try builder.index(renderNode: renderNode)
        }
        builder.finalize()
        let renderIndex = try RenderIndex.fromURL(targetURL.appendingPathComponent("index.json"))

        
        // Verify that there are no uncurated external links at the top level
        let swiftTopLevelExternalNodes = renderIndex.interfaceLanguages["swift"]?.filter { $0.path?.contains("/path/to/external") ?? false } ?? []
        let occTopLevelExternalNodes = renderIndex.interfaceLanguages["occ"]?.filter { $0.path?.contains("/path/to/external") ?? false } ?? []
        XCTAssertEqual(swiftTopLevelExternalNodes.count, 0)
        XCTAssertEqual(occTopLevelExternalNodes.count, 0)

        // Verify that the curated external links are part of the index.
        let swiftExternalNodes = renderIndex.interfaceLanguages["swift"]?.first { $0.path == "/documentation/mixedlanguageframework" }?.children?.filter { $0.path?.contains("/path/to/external") ?? false } ?? []
        let occExternalNodes = renderIndex.interfaceLanguages["occ"]?.first { $0.path == "/documentation/mixedlanguageframework" }?.children?.filter { $0.path?.contains("/path/to/external") ?? false } ?? []
        XCTAssertEqual(swiftExternalNodes.count, 1)
        XCTAssertEqual(occExternalNodes.count, 1)
        XCTAssertEqual(swiftExternalNodes.map(\.title), ["SwiftArticle"])
        XCTAssertEqual(occExternalNodes.map(\.title), ["ObjCSymbol"])
        XCTAssert(swiftExternalNodes.allSatisfy(\.isExternal))
        XCTAssert(occExternalNodes.allSatisfy(\.isExternal))
    }
}
