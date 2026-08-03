package de.cispa.se.tribble
package generation

import scala.util.Random

class NaiveTreeGenerator(maxRepetitions: Int, regexGenerator: RegexGenerator, maxDepth: Int, random: Random) extends RecursiveTreeGenerator(regexGenerator) {
  require(maxDepth > 0, s"The maximum depth must be positive ($maxDepth given).")

  override protected def instantiateAlternation(alternation: Alternation, parent: Option[DNode], currentDepth: Int)(implicit rules: Map[NonTerminal, DerivationRule]): DTree = {
    // uniform selection across alternation
    val alternatives = alternation.alternatives
    val n = random.nextInt(alternatives.size)
    val alternative = alternatives.iterator.drop(n).next
    val node = DNode(alternation, parent)
    prepareNode(node)
    node.children(0) = gen(alternative, Some(node), currentDepth + 1)
    node
  }

  override protected def instantiateQuantification(quantification: Quantification, parent: Option[DNode], currentDepth: Int)(implicit rules: Map[NonTerminal, DerivationRule]): DTree = {
    val q@Quantification(subj, min, max, _) = quantification
    val constrainedMax = Math.max(min, Math.min(max, maxRepetitions))
    val num = min + random.nextInt(constrainedMax - min + 1)
    val root = DNode(q, parent)
    var depth = 0
    prepareNode(root)
    var node = root
    while (depth < num && (depth < min || canExpandQuantification(q, currentDepth + depth))) {
      val child = DNode(q, Some(node))
      prepareNode(child)
      depth += 1
      node.children(0) = gen(subj, Some(node), currentDepth + depth)
      node.children(1) = child
      node = child
    }
    root
  }

  protected def canExpandQuantification(q: Quantification, currentDepth: Int): Boolean = currentDepth < maxDepth
}
