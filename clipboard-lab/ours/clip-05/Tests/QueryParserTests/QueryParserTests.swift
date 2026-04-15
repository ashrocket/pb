import Foundation

@testable import Clip05App

enum Clip05HarnessCompilationSmoke {
    static func load() {
        _ = QueryParser.ParsedQuery(clauses: [], bindings: [], textTerms: [])
    }
}
