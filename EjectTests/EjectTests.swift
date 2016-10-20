//
//  EjectTests.swift
//  EjectTests
//
//  Created by Brian King on 10/17/16.
//  Copyright © 2016 Brian King. All rights reserved.
//

import XCTest
func checkXML(_ xml: String, _ expected: [String], file: StaticString = #file, line: UInt = #line) {
    do {
        let builder = try XIBParser(content: xml, documentBuilder: CocoaTouchBuilder())
        let references = builder.document.references
            .map() { $0 as? IBObject }.flatMap() { $0 } // Only generate IBObjects
            .reversed() // Walk the list in reverse
        guard references.count > 0 else {
            XCTFail("No objects in the document", file: file, line: line - 1)
            return
        }
        let context = GenerationContext(document: builder.document, indentation: 0)
        var lines = references.map() { $0.generateCodeForConfiguration(in: context)}.flatMap() { $0 }
        lines.append(contentsOf: references.map() { $0.generateCode(in: context, for: .subviews) }.flatMap() { $0 })
        lines.append(contentsOf: references.map() { $0.generateCode(in: context, for: .constraints) }.flatMap() { $0 })
        
        XCTAssertEqual(lines.count, expected.count, file: file, line:line)
        var i: UInt = 1
        for (actualLine, expectedLine) in zip(lines, expected) {
            XCTAssertEqual(actualLine, expectedLine, file: file, line: line + i)
            i += 1
        }
        if lines != expected {
            print(lines.joined(separator: "\n"))
        }
    }
    catch let error {
        XCTFail(error.localizedDescription, file: file, line: line)
    }
}

func wrap(_ xml: String) -> String {
    return ["<?xml version='1.0' encoding='UTF-8' standalone='no'?>",
            "<document type='com.apple.InterfaceBuilder3.CocoaTouch.XIB' version='3.0' toolsVersion='10116' systemVersion='15F34' targetRuntime='iOS.CocoaTouch' propertyAccessControl='none' useAutolayout='YES' useTraitCollections='YES'>",
            "<dependencies>",
            "<deployment identifier='iOS'/>",
            "<plugIn identifier='com.apple.InterfaceBuilder.IBCocoaTouchPlugin' version='10085'/>",
            "</dependencies>",
            "<objects>",
            "<placeholder placeholderIdentifier='IBFilesOwner' id='-1' userLabel='FileOwner' customClass='TestClass' customModule='' customModuleProvider='target'>",
            "<connections>",
            "<outlet property='view' destination='i5M-Pr-FkT' id='sfx-zR-JGt'/>",
            "</connections>",
            "</placeholder>",
            "<placeholder placeholderIdentifier='IBFirstResponder' id='-2' customClass='UIResponder'/>",
            xml,
            "</objects>",
            "</document>"
    ].joined(separator: "\n")
}

class EjectTests: XCTestCase {

    func testString() {
        let string = "Test String"
        XCTAssertEqual(string.snakeCased(), "testString")
    }

    func testViewPartsWithFrame() {
        let xml = "<view userLabel='test' clearsContextBeforeDrawing='NO' contentMode='scaleToFill' id='i5M-Pr-FkT'><rect key='frame' x='0.0' y='0.0' width='350' height='85'/></view>"
        checkXML(xml, [
            "let test = UIView()",
            "test.clearsContextBeforeDrawing = false",
            "test.contentMode = .scaleToFill",
            "test.frame = CGRect(x: 0.0, y:0.0, width: 350, height: 85)"
            ]
        )
    }

    func testUserDefinedInt() {
        let xml = "<view userLabel='test' id='i5M-Pr-FkT'><userDefinedRuntimeAttributes><userDefinedRuntimeAttribute type='number' keyPath='layer.cornerRadius'><integer key='value' value='25'/></userDefinedRuntimeAttribute></userDefinedRuntimeAttributes></view>"
        checkXML(xml, [
            "let test = UIView()",
            "test.layer.cornerRadius = 25"
            ]
        )
    }

    func testLabelWithTextContent() {
        let xml = "<label userLabel='test' id='i5M-Pr-FkT'><mutableString key='text'>body</mutableString></label>"
        checkXML(xml, [
            "let test = UILabel()",
            "test.text = \"body\""
            ]
        )
    }

    func testColor() {
        let xml = "<view userLabel='test' id='i5M-Pr-FkT'><color key='a' red='0.97254908084869385' green='0.97254908084869385' blue='0.90196084976196289' alpha='1' colorSpace='deviceRGB'/><color key='b' red='0.84705882352941175' green='0.16078431372549021' blue='0.18431372549019609' alpha='1' colorSpace='calibratedRGB'/><color key='c' white='1' alpha='1' colorSpace='custom' customColorSpace='calibratedWhite'/><color key='d' white='0.5' alpha='1' colorSpace='calibratedWhite'/></view>"
        checkXML(xml, [
            "let test = UIView()",
            "test.a = UIColor(red: 0.973, green: 0.973, blue: 0.902, alpha: 1)",
            "test.b = UIColor(red: 0.847, green: 0.161, blue: 0.184, alpha: 1)",
            "test.c = UIColor(white: 1, alpha: 1)",
            "test.d = UIColor(white: 0.5, alpha: 1)",
            ]
        )
    }

    func crashTestAttributedText() {
        let xml = "<attributedString key='attributedText'><fragment content='Get $50 bonus!'><attributes><color key='NSColor' red='0.42745098040000001' green='0.42745098040000001' blue='0.42745098040000001' alpha='1' colorSpace='calibratedRGB'/><font key='NSFont' metaFont='system' size='19'/>                                        <paragraphStyle key='NSParagraphStyle' alignment='center' lineBreakMode='truncatingTail' baseWritingDirection='natural' lineSpacing='5' tighteningFactorForTruncation='0.0'/></attributes></fragment></attributedString>"
        checkXML(xml, [])
    }

    func testFont() {
        let xml = "<view userLabel='test' id='i5M-Pr-FkT'><fontDescription key='a' name='Gotham-Bold' family='Gotham' pointSize='32'/><fontDescription key='b' type='system' pointSize='17'/></view>"
        checkXML(xml, [
            "let test = UIView()",
            "test.a = UIFont(name: \"Gotham-Bold\", size: 32)",
            "test.b = .systemFont(ofSize: 17)",
            ]
        )
    }

    func testLabel() {
        let xml = "<label baselineAdjustment='alignBaselines' minimumFontSize='13' userLabel='test' id='i5M-Pr-FkT'><fontDescription key='fontDescription' type='system' pointSize='17'/></label>"
        checkXML(xml, [
            "let test = UILabel()",
            "test.minimumFontSize = 13",
            "test.baselineAdjustment = .alignBaselines",
            "test.font = .systemFont(ofSize: 17)"
            ]
        )
    }

    func testCollectionView() {
        let xml = wrap("<collectionView contentMode='scaleToFill' dataMode='none' translatesAutoresizingMaskIntoConstraints='NO' id='i5M-Pr-FkT'><rect key='frame' x='11' y='11' width='328' height='578'/><collectionViewFlowLayout key='collectionViewLayout' minimumLineSpacing='10' minimumInteritemSpacing='10' id='sFl-c5-v9d'><size key='itemSize' width='50' height='50'/><size key='headerReferenceSize' width='0.0' height='0.0'/><size key='footerReferenceSize' width='0.0' height='0.0'/><inset key='sectionInset' minX='0.0' minY='0.0' maxX='0.0' maxY='0.0'/></collectionViewFlowLayout><connections><outlet property='dataSource' destination='-1' id='0eg-ac-TGD'/><outlet property='delegate' destination='-1' id='jQ0-LG-WAK'/></connections></collectionView>")
        checkXML(xml, [
            "let collectionViewFlowLayout = UICollectionViewFlowLayout()",
            "collectionViewFlowLayout.itemSize = CGSize(width: 50, height: 50)",
            "collectionViewFlowLayout.headerReferenceSize = CGSize(width: 0.0, height: 0.0)",
            "collectionViewFlowLayout.footerReferenceSize = CGSize(width: 0.0, height: 0.0)",
            "collectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)",
            "let collectionView = UICollectionView()",
            "collectionView.translatesAutoresizingMaskIntoConstraints = false",
            "collectionView.contentMode = .scaleToFill",
            "collectionView.frame = CGRect(x: 11, y:11, width: 328, height: 578)",
            "collectionView.collectionViewLayout = collectionViewFlowLayout",
            "collectionView.dataSource = fileOwner",
            "collectionView.delegate = fileOwner",
        ])
    }

    func testTableView() {
        let xml = wrap("<tableView alwaysBounceVertical='YES' style='plain' separatorStyle='default' rowHeight='44' sectionHeaderHeight='28' sectionFooterHeight='28' translatesAutoresizingMaskIntoConstraints='NO' id='i5M-Pr-FkT'><rect key='frame' x='11' y='11' width='328' height='578'/><color key='backgroundColor' white='1' alpha='1' colorSpace='calibratedWhite'/><inset key='separatorInset' minX='15' minY='0.0' maxX='15' maxY='0.0'/><connections><outlet property='dataSource' destination='-1' id='0eg-ac-TGD'/><outlet property='delegate' destination='-1' id='jQ0-LG-WAK'/></connections></tableView>")
        checkXML(xml, [
            "let tableView = UITableView(frame: .zero, style: .plain)",
            "tableView.translatesAutoresizingMaskIntoConstraints = false",
            "tableView.alwaysBounceVertical = true",
            "tableView.separatorStyle = .default",
            "tableView.rowHeight = 44",
            "tableView.sectionHeaderHeight = 28",
            "tableView.sectionFooterHeight = 28",
            "tableView.frame = CGRect(x: 11, y:11, width: 328, height: 578)",
            "tableView.backgroundColor = UIColor(white: 1, alpha: 1)",
            "tableView.separatorInset = UIEdgeInsets(top: 0.0, left: 15.0, bottom: 0.0, right: 30.0)",
            "tableView.dataSource = fileOwner",
            "tableView.delegate = fileOwner",
            ])
    }

    func testImageView() {
        let xml = "<imageView contentMode='center' image='icon' translatesAutoresizingMaskIntoConstraints='NO' id='i5M-Pr-FkT'></imageView>"
        checkXML(xml, [
            "let imageView = UIImageView()",
            "imageView.translatesAutoresizingMaskIntoConstraints = false",
            "imageView.contentMode = .center",
            "imageView.image = UIImage(named: \"icon\")",
        ])
    }

    func testButtonState() {
        let xml = "<button contentHorizontalAlignment='center' contentVerticalAlignment='center' lineBreakMode='middleTruncation' id='i5M-Pr-FkT'><rect key='frame' x='11' y='11' width='328' height='578'/><state key='normal' title='Title' image='icon'><color key='titleColor' white='1' alpha='1' colorSpace='calibratedWhite'/><color key='titleShadowColor' white='0.0' alpha='0.0' colorSpace='calibratedWhite'/></state><connections><action selector='doThing:' destination='-1' eventType='touchUpInside' id='39P-Rs-7z2'/></connections></button>"
        checkXML(xml, [
            "let button = UIButton()",
            "button.lineBreakMode = .middleTruncation", // This is deprecated and should be .titleLabel.lineBreakMode
            "button.frame = CGRect(x: 11, y:11, width: 328, height: 578)",
            "button.setTitle(\"Title\", for: .normal)",
            "button.setImage(UIImage(named: \"icon\"), for: .normal)",
            "button.setTitlecolor(UIColor(white: 1, alpha: 1), for: .normal)",
            "button.setTitleshadowcolor(UIColor(white: 0, alpha: 0), for: .normal)",
            ])
    }

    func testViewHierarchy() {
        let xml = "<view id='i5M-Pr-FkT'><subviews><view id='FUp-2k-EIR' userLabel='BorderView'><subviews><webView id='glB-HT-PdE'/></subviews></view><view id='aaa-bb-ccc' userLabel='OtherView'/></subviews></view>"
        checkXML(xml, [
            "let otherView = UIView()",
            "let webView = UIWebView()",
            "let borderView = UIView()",
            "let view = UIView()",
            "borderView.addSubview(webView)",
            "view.addSubview(borderView)",
            "view.addSubview(otherView)",
            ])
    }

    func testVisualEffectViewKey() {
        let xml = "<visualEffectView opaque='NO' contentMode='scaleToFill' translatesAutoresizingMaskIntoConstraints='NO' id='i5M-Pr-FkT' userLabel='Top Bar Blur Container'><view key='contentView' opaque='NO' id='u6B-MW-OWb'></view></visualEffectView>"
        checkXML(xml, [])
    }

    func testSegmentedControl() {
        let xml = "<segmentedControl segmentControlStyle='plain' selectedSegmentIndex='0' id='i5M-Pr-FkT'><rect key='frame' x='11' y='11' width='328' height='578'/><segments><segment title='Overview'/><segment title='Description'/></segments></segmentedControl>"
        checkXML(xml, [])
    }

    /// This test will validate the generation eventually. The hope is to have a directory full of xib files and the generated code and ensure things don't change.
    func testXibResources() {
        for path in Bundle(for: type(of: self)).paths(forResourcesOfType: "xibtest", inDirectory: "") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let builder = try XIBParser(data: data, documentBuilder: CocoaTouchBuilder())
                let code = builder.document.generateCode()
                print(code)
            }
            catch let error {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
}
