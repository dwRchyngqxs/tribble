package de.cispa.se.tribble
package output

import de.cispa.se.tribble.{GrammarRepr, DTree}
import de.cispa.se.tribble.generation.TreeGenerator

class DTreePrettyPrinter(grammar: GrammarRepr, treegen: TreeGenerator) {
  def apply(tree: DTree): String = {
    val lvs = tree.leaves
    var stack: List[Option[DerivationRule]] = List(grammar.rules.get(grammar.ignore))
    val sb: StringBuilder = new StringBuilder
    var insertSep = false
    for (lv <- lvs) lv match {
      case DTerminal(decl, parent, value) => {
        val ignore = stack.head
        if (insertSep && ignore.isDefined)
          sb ++= treegen.generate(grammar.rules, ignore.get).leaves.filter(_.isInstanceOf[DTerminal]).mkString
        sb ++= lv.toString
        insertSep = true
      }
      case DPushIgnore(decl, parent) => {
        if (decl.lsep.isDefined)
          sb ++= treegen.generate(grammar.rules, decl.lsep.get).leaves.filter(_.isInstanceOf[DTerminal]).mkString
        stack = decl.ignore :: stack
        insertSep = false
      }
      case DPopIgnore(decl, parent) => {
        if (decl.rsep.isDefined)
          sb ++= treegen.generate(grammar.rules, decl.rsep.get).leaves.filter(_.isInstanceOf[DTerminal]).mkString
        stack = stack.tail
        insertSep = false
      }
    }
    sb.toString
  }
}
