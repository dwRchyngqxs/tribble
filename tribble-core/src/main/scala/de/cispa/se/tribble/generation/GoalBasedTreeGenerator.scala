package de.cispa.se.tribble
package generation

import scala.util.Random

private[tribble] class GoalBasedTreeGenerator(closeOffGenerator: TreeGenerator, random: Random)(implicit grammar: GrammarRepr, goal: CoverageGoal) extends ForestGenerator {
  private implicit val rules = grammar.rules

  private def gen(rule: DerivationRule, parent: Option[DNode], currentDepth: Int)(implicit goal: CoverageGoal): DTree = {
    goal.usedDerivation(rule, parent)
    if (goal.targetReached) {
      delegateToCloseOff(rule, parent, currentDepth)
    } else {
      rule match {
        case Reference(name, _) =>
          val node = DNode(rule, parent)
          node.children(0) = gen(grammar(name), Some(node), currentDepth + 1)
          node
        case Alternation(alternatives, _) =>
          // take the alternative leading to the goal fastest
          val shortestAlts = minimalElementsBy(alternatives, goal.cost)
          val alternative = shortestAlts(random.nextInt(shortestAlts.length))
          val node = DNode(rule, parent)
          node.children(0) = gen(alternative, Some(node), currentDepth + 1)
          node
        case Concatenation(elements, _) =>
          // problem with left recursion
          // we have to expand the closest-to-target element first!
          val node = DNode(rule, parent)
          val toExpand = elements.zipWithIndex.sortBy { case (e, _) => goal.cost(e) }
          node.children ++= toExpand.map { case (e, i) => i -> gen(e, Some(node), currentDepth + 1) }
          node
        case Quantification(subj, min, max, _) => {
          val root = DNode(rule, parent)
          var node = root
          var depth = 1
          // use as many repetition as possible from the k-path
          // last repetition has no child so no 0 cost child
          while (depth < max && !goal.targetReached && goal.cost(rule) == 0) {
            goal.usedDerivation(rule, Some(node))
            val child = DNode(rule, Some(node))
            node.children(1) = child
            node = child
            depth += 1
          }
          if (max > 0) {
            goal.usedDerivation(rule, Some(node))
            val child = DNode(rule, Some(node))
            node.children(0) = gen(subj, Some(node), currentDepth + depth)
            node.children(1) = child
          }
          node = root
          for (d <- 1 to depth - 1) {
            node.children(0) = gen(subj, Some(node), currentDepth + d)
            node = node.children(1).asInstanceOf[DNode]
          }
          if (max > 0) {
            node = node.children(1).asInstanceOf[DNode]
            depth += 1
          }
          // complete to minimum number of repetitions - 1
          while (depth <= max && (depth <= min || !goal.targetReached)) {
            goal.usedDerivation(rule, Some(node))
            val child = DNode(rule, Some(node))
            node.children(0) = gen(subj, Some(node), currentDepth + depth)
            node.children(1) = child
            node = child
            depth += 1
          }
          root
        }
        case t: TerminalRule =>
          // we do not use delegateToCloseOff here because we have already called goal.usedDerivation
          closeOffGenerator.gen(t, parent, currentDepth)
      }
    }
  }

  private def delegateToCloseOff(rule: DerivationRule, parent: Option[DNode], currentDepth: Int): DTree = {
    val node = closeOffGenerator.gen(rule, parent, currentDepth)
    // because we do not return to this method recursively when closing off the tree, we have to update the goal post-factum
    // the node itself, however, has already been reported to the goal at the beginning of the method gen
    node match {
      case DNode(_, _, children) => children.values.foreach(informGoal)
      case _ =>
    }
    node
  }

  @inline private def informGoal(t: DTree): Unit = t dfs { n => goal.usedDerivation(n.decl, n.parent) }


  /** Generates a forest satisfying the coverage goal */
  override def generateForest(): Stream[DTree] = {
    gen(grammar.root, None, 0) #:: (if (goal.nextTarget()) generateForest() else Stream.empty)
  }

}
