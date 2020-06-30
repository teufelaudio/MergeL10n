import Foundation
import L10nModels
import XCTest

class ParserTests: XCTestCase {
    func testSingleLine() throws {
        let file =
        """
        /* These are some 'commends' from the developer (4.1.2) * and also ** some / from the translator */
        "L10n.MyModule.SomeView.title" = "Hello, " parser world";
        """

        let expectedResult = [
            LocalizedStringEntry(
                key: "L10n.MyModule.SomeView.title",
                value: "Hello, \" parser world",
                comment: "These are some 'commends' from the developer (4.1.2) * and also ** some / from the translator")
        ]

        let (match, rest) = LocalizedStringFile.parser().run(file)

        XCTAssertEqual(expectedResult.count, match?.count)
        XCTAssertEqual(expectedResult[0].comment, match?[0].comment)
        XCTAssertEqual(expectedResult[0].key, match?[0].key)
        XCTAssertEqual(expectedResult[0].value, match?[0].value)

        XCTAssertEqual("", rest)
    }

    func testMultiLine() throws {
        let file =
        """


        /* Comment number 1 */
        "L10n.MyModule.SomeView.title" = "This is the title";

        /* Comment number 2 */
        "L10n.MyModule.SomeView.body" = "This is the body";



        /* Comment number 3 */
        "L10n.MyModule.SomeView.caption" = "Some caption";




        """

        let expectedResult = [
            LocalizedStringEntry(
                key: "L10n.MyModule.SomeView.title",
                value: "This is the title",
                comment: "Comment number 1"
            ),
            LocalizedStringEntry(
                key: "L10n.MyModule.SomeView.body",
                value: "This is the body",
                comment: "Comment number 2"
            ),
            LocalizedStringEntry(
                key: "L10n.MyModule.SomeView.caption",
                value: "Some caption",
                comment: "Comment number 3"
            )
        ]

        let (match, rest) = LocalizedStringFile.parser().run(file)

        XCTAssertEqual(expectedResult, match)

        XCTAssertEqual("", rest)
    }

    func testEmptyValue() throws {
        let file =
        """
        /* These are some 'commends' from the developer (4.1.2) * and also ** some / from the translator */
        "L10n.MyModule.SomeView.title" = "";
        """

        let expectedResult = [
            LocalizedStringEntry(
                key: "L10n.MyModule.SomeView.title",
                value: "",
                comment: "These are some 'commends' from the developer (4.1.2) * and also ** some / from the translator")
        ]

        let (match, rest) = LocalizedStringFile.parser().run(file)

        XCTAssertEqual(expectedResult.count, match?.count)
        XCTAssertEqual(expectedResult[0].comment, match?[0].comment)
        XCTAssertEqual(expectedResult[0].key, match?[0].key)
        XCTAssertEqual(expectedResult[0].value, match?[0].value)

        XCTAssertEqual("", rest)
    }

    func testRequiresCommentShouldFailWhenThereIsNoComment() throws {
        let file =
        """
        /* Comment for title */
        "L10n.MyModule.SomeView.title" = "This is the title";
        "L10n.MyModule.SomeView.body" = "This is the body";
        /* Comment for caption */
        "L10n.MyModule.SomeView.caption" = "This is the caption";
        """

        let expectedResult = [
            LocalizedStringEntry(
                key: "L10n.MyModule.SomeView.title",
                value: "This is the title",
                comment: "Comment for title")
        ]

        let (match, rest) = LocalizedStringFile.parser().run(file)

        XCTAssertEqual(expectedResult, match)

        XCTAssertEqual(
            """
            "L10n.MyModule.SomeView.body" = "This is the body";
            /* Comment for caption */
            "L10n.MyModule.SomeView.caption" = "This is the caption";
            """,
            rest)
    }

    func testRequiresCommentsDisabledShouldSucceedWhenThereIsNoComment() throws {
        let file =
        """
        /* Comment for title */
        "L10n.MyModule.SomeView.title" = "This is the title";
        "L10n.MyModule.SomeView.body" = "This is the body";
        /* Comment for caption */
        "L10n.MyModule.SomeView.caption" = "This is the caption";
        """

        let expectedResult = [
            LocalizedStringEntry(
                key: "L10n.MyModule.SomeView.title",
                value: "This is the title",
                comment: "Comment for title"
            ),
            LocalizedStringEntry(
                key: "L10n.MyModule.SomeView.body",
                value: "This is the body",
                comment: ""
            ),
            LocalizedStringEntry(
                key: "L10n.MyModule.SomeView.caption",
                value: "This is the caption",
                comment: "Comment for caption"
            )
        ]

        let (match, rest) = LocalizedStringFile.parser(requiresComments: false).run(file)

        XCTAssertEqual(expectedResult, match)

        XCTAssertEqual("", rest)
    }

    func testRequiresCommentsDisabledShouldSucceedWhenThereAreMultipleLinesWithNoComment() throws {
        let file =
        """
        /* Comment for title */
        "L10n.MyModule.SomeView.title" = "This is the title";
        "L10n.MyModule.SomeView.body" = "This is the body";
        "L10n.MyModule.SomeView.body2" = "This is the body2";
        "L10n.MyModule.SomeView.body3" = "This is the body3";
        /* Comment for caption */
        "L10n.MyModule.SomeView.caption" = "This is the caption";
        """

        let expectedResult = [
            LocalizedStringEntry(
                key: "L10n.MyModule.SomeView.title",
                value: "This is the title",
                comment: "Comment for title"
            ),
            LocalizedStringEntry(
                key: "L10n.MyModule.SomeView.body",
                value: "This is the body",
                comment: ""
            ),
            LocalizedStringEntry(
                key: "L10n.MyModule.SomeView.body2",
                value: "This is the body2",
                comment: ""
            ),
            LocalizedStringEntry(
                key: "L10n.MyModule.SomeView.body3",
                value: "This is the body3",
                comment: ""
            ),
            LocalizedStringEntry(
                key: "L10n.MyModule.SomeView.caption",
                value: "This is the caption",
                comment: "Comment for caption"
            )
        ]

        let (match, rest) = LocalizedStringFile.parser(requiresComments: false).run(file)

        XCTAssertEqual(expectedResult, match)

        XCTAssertEqual("", rest)
    }
}
