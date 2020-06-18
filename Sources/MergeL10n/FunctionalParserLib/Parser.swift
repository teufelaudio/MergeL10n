//
//  Parser.swift
//  MergeL10n
//
//  Created by Luiz Barbosa on 17.06.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation

// MARK: - Localizable.strings File Parsing

struct Parser<A> {
    let run: (inout Substring) -> A?

    func run(_ str: String) -> (match: A?, rest: Substring) {
        var str = str[...]
        let match = self.run(&str)
        return (match, str)
    }

    func map<B>(_ f: @escaping (A) -> B) -> Parser<B> {
        Parser<B> { str in
            self.run(&str).map(f)
        }
    }

    func flatMap<B>(_ f: @escaping (A) -> Parser<B>) -> Parser<B> {
        Parser<B> { str in
            let original = str
            let matchA = self.run(&str)
            let parserB = matchA.map(f)
            guard let matchB = parserB?.run(&str) else {
                str = original
                return nil
            }
            return matchB
        }
    }
}
func literal(_ literal: String) -> Parser<Void> {
    Parser<Void> { str in
        guard str.hasPrefix(literal) else { return nil }
        str.removeFirst(literal.count)
        return ()
    }
}
let charParser = Parser<Character> { str in
    guard !str.isEmpty else { return nil }
    return str.removeFirst()
}
func always<A>(_ a: A) -> Parser<A> { Parser { _ in a } }
func never<A>() -> Parser<A> { Parser { _ in nil } }
func zip<A, B>(_ a: Parser<A>, _ b: Parser<B>) -> Parser<(A, B)> {
    Parser<(A, B)> { str in
        let original = str
        guard let matchA = a.run(&str) else { return nil }
        guard let matchB = b.run(&str) else {
            str = original
            return nil
        }
        return (matchA, matchB)
    }
}
func zip<A, B, C>(_ a: Parser<A>, _ b: Parser<B>, _ c: Parser<C> ) -> Parser<(A, B, C)> {
    zip(a, zip(b, c)).map { a, bc in (a, bc.0, bc.1) }
}
func zip<A, B, C, D>(_ a: Parser<A>, _ b: Parser<B>, _ c: Parser<C>, _ d: Parser<D> ) -> Parser<(A, B, C, D)> {
    zip(a, zip(b, c, d)).map { a, bcd in (a, bcd.0, bcd.1, bcd.2) }
}
func zip<A, B, C, D, E>(_ a: Parser<A>, _ b: Parser<B>, _ c: Parser<C>, _ d: Parser<D>, _ e: Parser<E>) -> Parser<(A, B, C, D, E)> {
    zip(a, zip(b, c, d, e)).map { a, bcde in (a, bcde.0, bcde.1, bcde.2, bcde.3) }
}
// swiftlint:disable function_parameter_count line_length
func zip<A, B, C, D, E, F>(_ a: Parser<A>, _ b: Parser<B>, _ c: Parser<C>, _ d: Parser<D>, _ e: Parser<E>, _ f: Parser<F>) -> Parser<(A, B, C, D, E, F)> {
    zip(a, zip(b, c, d, e, f)).map { a, bcdef in (a, bcdef.0, bcdef.1, bcdef.2, bcdef.3, bcdef.4) }
}
func zip<A, B, C, D, E, F, G>(_ a: Parser<A>, _ b: Parser<B>, _ c: Parser<C>, _ d: Parser<D>, _ e: Parser<E>, _ f: Parser<F>, _ g: Parser<G>) -> Parser<(A, B, C, D, E, F, G)> {
    zip(a, zip(b, c, d, e, f, g)).map { a, bcdefg in (a, bcdefg.0, bcdefg.1, bcdefg.2, bcdefg.3, bcdefg.4, bcdefg.5) }
}
// swiftlint:enable function_parameter_count line_length
func prefix(while p: @escaping (Character) -> Bool) -> Parser<Substring> {
    Parser<Substring> { str in
        let prefix = str.prefix(while: p)
        str.removeFirst(prefix.count)
        return prefix
    }
}
let zeroOrMoreSpaces = prefix(while: { $0 == " " }).map { _ in () }
let oneOrMoreSpaces = prefix(while: { $0 == " " }).flatMap { $0.isEmpty ? never() : always(()) }
let zeroOrMoreSpacesOrLines = prefix(while: { $0 == " " || $0 == "\n" }).map { _ in () }
func zeroOrMore<A>(_ p: Parser<A>, separatedBy s: Parser<Void> = literal("")) -> Parser<[A]> {
    Parser<[A]> { str in
        var rest = str
        var matches: [A] = []
        while let match = p.run(&str) {
            rest = str
            matches.append(match)
            if s.run(&str) == nil {
                return matches
            }
        }
        str = rest
        return matches
    }
}
func oneOf<A>(_ ps: [Parser<A>]) -> Parser<A> {
    Parser<A> { str in
        for p in ps {
            if let match = p.run(&str) {
                return match
            }
        }
        return nil
    }
}
func not<A>(_ p: Parser<A>) -> Parser<Character> {
    Parser { str in
        let backup = str
        if p.run(&str) != nil {
            str = backup
            return nil
        }
        return charParser.run(&str)
    }
}
func string<A>(until: Parser<A>) -> Parser<String> {
    zeroOrMore(not(until)).map { String($0) }
}
