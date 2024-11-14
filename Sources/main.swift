import SwiftSyntax
import SwiftParser
@_spi(Experimental) import SwiftLexicalLookup

class GuardRewriter: SyntaxRewriter {
  let lookupFrom: TokenSyntax
  let optionalBindingCondition: OptionalBindingConditionSyntax
  let name: String
  
  init(lookupFrom: TokenSyntax, optionalBindingCondition: OptionalBindingConditionSyntax, name: String) {
    self.lookupFrom = lookupFrom
    self.optionalBindingCondition = optionalBindingCondition
    self.name = name
  }
  
  override func visit(
    _ node: OptionalBindingConditionSyntax
  ) -> OptionalBindingConditionSyntax {
    guard node == optionalBindingCondition,
          let identifierPattern = node.pattern.as(IdentifierPatternSyntax.self) else { return node }
    
    var newBindingCondition = node
    newBindingCondition.initializer = InitializerClauseSyntax(
      equal: .equalToken(
        leadingTrivia: Trivia(arrayLiteral: .spaces(1)),
        trailingTrivia: Trivia(arrayLiteral: .spaces(1))
      ), value: DeclReferenceExprSyntax(baseName: identifierPattern.identifier))
    newBindingCondition.pattern = PatternSyntax(IdentifierPatternSyntax(identifier: .identifier(name)))
    
    return newBindingCondition
  }
  
  override func visit(_ token: TokenSyntax) -> TokenSyntax {
    guard token == lookupFrom else { return token }
    
    var newToken = token
    newToken.tokenKind = .identifier(name)
    
    return newToken
  }
}

func refersTo(lookupFrom: TokenSyntax, identifier: Identifier) -> OptionalBindingConditionSyntax? {
  lookupFrom
    .lookup(identifier)
    .first?
    .names
    .first?
    .syntax
    .parent?
    .as(OptionalBindingConditionSyntax.self)
}

var parser = Parser("""
func foo(a: Int?, b: Int?) -> Int {
  if let a {
    print(a)
  }

  guard let b, let a else { return -1 }

  return a + b
}
""")
let sourceFileSyntax = SourceFileSyntax.parse(from: &parser)

if let lookupFrom = sourceFileSyntax.token(at: AbsolutePosition(utf8Offset: 118)),
   let optionalBindingCondition = refersTo(lookupFrom: lookupFrom, identifier: Identifier(canonicalName: "a")) {
  let guardRewriter = GuardRewriter(
    lookupFrom: lookupFrom,
    optionalBindingCondition: optionalBindingCondition,
    name: "x"
  )
  
  print("Before rewriting:")
  print(sourceFileSyntax)
  print("\nAfter rewriting:")
  print(guardRewriter.visit(sourceFileSyntax))
}
