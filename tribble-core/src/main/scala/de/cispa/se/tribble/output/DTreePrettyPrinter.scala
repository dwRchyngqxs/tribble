package de.cispa.se.tribble
package output

import de.cispa.se.tribble.{GrammarRepr, DTree}
import de.cispa.se.tribble.generation.TreeGenerator

class DTreePrettyPrinter(grammar: GrammarRepr, treegen: TreeGenerator) {
  def apply(tree: DTree): String = {
    // TODO: test token merging
    val lvs = tree.leaves
    val ignore = grammar.rules.get(grammar.ignore)
    if (lvs.isEmpty || ignore.isEmpty)
      lvs.mkString(" ")
    else
      lvs.map((x: DLeaf) => new StringBuffer(x.toString))
        .reduceLeft((B, s) => B.append(treegen.generate(grammar.rules, ignore.get).leaves.mkString).append(s))
        .toString
  }
}
