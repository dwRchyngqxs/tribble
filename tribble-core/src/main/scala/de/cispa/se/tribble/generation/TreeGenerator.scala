package de.cispa.se.tribble
package generation

trait TreeGenerator {
  def generate(grammar: GrammarRepr): DTree = gen(grammar.root, None, 0)(grammar.rules)
  def generate(rules: Map[NonTerminal, DerivationRule], from: DerivationRule): DTree = gen(from, None, 0)(rules)

  private[tribble] def gen(decl: DerivationRule, parent: Option[DNode], currentDepth: Int)(implicit rules: Map[NonTerminal, DerivationRule]): DTree
}
