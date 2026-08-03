package de.cispa.se.tribble
package generation

import scala.collection.mutable
import scala.util.Random
import de.cispa.se.tribble.output.{TextDSLPrettyPrinter, Precedence}

/** A Goal consists of multiple Targets */
trait CoverageGoal {
  def name: String
  def usedDerivation(rule: DerivationRule, parent: Option[DNode]): Unit
  def cost(from: DerivationRule): Int
  def targetReached: Boolean
  def nextTarget(): Boolean
  def targetCount: Int
  def coveredTargets: Int
}


class KPathCoverageGoal(k: Int)(implicit grammar: GrammarRepr, random: Random, reach: Reachability) extends CoverageGoal {
  require(k > 0, s"k must be greater than one! ($k given)")
  val name = s"$k-path coverage"
  protected[tribble] val targets: mutable.Set[List[DerivationRule]] = {
    // step 1/2: gather the targets in a deterministic order
    val linearTargets = if (k == 1) {
      reach.interestingRules.map(List(_))
    } else {
      reach.interestingRules.collect { case x if !x.isInstanceOf[TerminalRule] => List(x) }.flatMap(calcTuples)
    }
    // step 2/2: shuffle the targets
    mutable.Set(random.shuffle(linearTargets).toSeq:_*)
  }
  // the target is ordered such that the next rule to be reached is in head position. E.g. root :: child1 :: grandchild3 :: Nil
  protected var target: List[DerivationRule] = grammar.root :: Nil

  override val targetCount: Int = targets.size

  override def coveredTargets: Int = targetCount - targets.size

  override def nextTarget(): Boolean = {
    require(targetReached, s"Cannot select a new target because the current target has not been reached! $target")
    val hasNext = targets.nonEmpty
    if (hasNext) target = targets.head
    hasNext
  }

  override def usedDerivation(rule: DerivationRule, parent: Option[DNode]): Unit = {
    val tuple = getTupleEndingIn(rule, parent)
    if (tuple.nonEmpty)
      targets -= tuple
    if (target.headOption.contains(rule))
      target = target.tail
  }

  /** Weight of the shortest path from [[from]] to [[target]] or Int.MaxValue if not reachable. */
  override def cost(from: DerivationRule): Int = {
    assert(target.nonEmpty, s"Asking for the cost of deriving $from with no current goal!")
    val t = target.head
    if (from == t) 0 else reach.reachability(from).getOrElse(t, Int.MaxValue)
  }

  override def targetReached: Boolean = target.isEmpty

  /** Collects possible k-paths starting with the given prefix. */
  private def calcTuples(prefix: List[DerivationRule]): Set[List[DerivationRule]] = {
    require(prefix.nonEmpty)
    require(prefix.size < k)
    val start = prefix.head
    val immediateSteps = reach.immediateSuccessors(start)
    start match {
      case Quantification(subject, min, max, _) => {
        var curPath = prefix
        val paths = mutable.ArrayBuffer[List[DerivationRule]]()
        for (_ <- 1 to Math.min(k - prefix.size, max)) {
          paths += subject :: curPath
          curPath = start :: curPath
        }
        paths.toSet.flatMap{ p: List[DerivationRule] => if (p.size == k) Set(p.reverse) else calcTuples(p) }
      }
      case _ => {
        if (prefix.size == k - 1) {
          // last element: nonterminals and terminals allowed as last element
          immediateSteps.collect { case x if reach.interestingRules.contains(x) => (x :: prefix).reverse }
        } else {
          // only interested in nonterminals
          immediateSteps.collect { case x if !x.isInstanceOf[TerminalRule] && reach.interestingRules.contains(x) => x :: prefix }.flatMap(calcTuples)
        }
      }
    }
  }

  protected def lookUp(p: Option[DNode], limit: Int): mutable.ListBuffer[DerivationRule] = {
    val prefix = mutable.ListBuffer[DerivationRule]()
    var n = p
    while (prefix.size < limit && n.isDefined) {
      val dr = n.get.decl
      if (reach.interestingRules.contains(dr)) prefix.prepend(dr)
      n = n.get.parent
    }
    prefix
  }

  protected def getTupleEndingIn(rule: DerivationRule, parent: Option[DNode]): List[DerivationRule] = {
    if (reach.interestingRules.contains(rule)) {
      val prefix = lookUp(parent, k - 1)
      prefix.append(rule)
      prefix.toList
    } else Nil
  }

  override def toString(): String = {
    def pp(x: DerivationRule): String = TextDSLPrettyPrinter(x, Precedence.PAlternation)
    targets.map(_.map(pp(_)).mkString(", ")).mkString(";\n")
  }
}

class KPathThroughPath(p: Int, path: List[DerivationRule])(implicit grammar: GrammarRepr, random: Random, reach: Reachability) extends KPathCoverageGoal(p + path.length - 1) {
  val newk = p + path.length - 1
  override val name = s"$newk-path through path"
  override protected[tribble] val targets: mutable.Set[List[DerivationRule]] = {
    // step 1/2: gather the targets in a deterministic order
    val linearTargets = if (p == 1) List(path) else calcTuplesThrough
    // step 2/2: shuffle the targets
    mutable.Set(random.shuffle(linearTargets).toSeq:_*)
  }
  print(toString() + ";\n") // TODO: REMOVE after testing
  target = targets.head

  private def validPath(p: List[DerivationRule]): Boolean = {
    var parent = p.head
    var rpt = 1
    for (r <- p.tail) {
      if (r == parent) {
        r match {
          case Quantification(_, _, max, _) =>
            rpt += 1
            if (rpt > max) return false
          case _ =>
        }
      } else {
        parent = r
        rpt = 1
      }
    }
    return true
  }

  /** Collects possible k-paths passing through the given sequence. */
  private def calcTuplesThrough(): List[List[DerivationRule]] = {
    var final_paths = List(path)
    if (!path.head.isInstanceOf[TerminalRule]) {
      var build_paths = List(path)
      for (_ <- 2 to p) {
        val new_paths = build_paths.groupBy(_.head).flatMap( x =>
          reach.immediateSuccessors(x._1).flatMap {
            case y if reach.interestingRules.contains(y) => x._2.map(y :: _)
          }
        )
        final_paths ++= new_paths
        build_paths = new_paths.filter(!_.head.isInstanceOf[TerminalRule]).toList
      }
    }
    var build_paths = {
      val paths = final_paths.map(_.reverse).partition(_.length < newk)
      final_paths = paths._2
      paths._1
    }
    var reverseSuccessors = mutable.Map[DerivationRule, mutable.Set[DerivationRule]]()
    reach.interestingRules.foreach(s =>
      reach.immediateSuccessors(s).foreach(t =>
        reverseSuccessors.getOrElseUpdate(t, mutable.Set()) += s
      )
    )
    while (build_paths.nonEmpty) {
      val new_paths = build_paths.groupBy(_.head).flatMap( x =>
        reverseSuccessors(x._1).flatMap {
          case y if !y.isInstanceOf[TerminalRule] && reach.interestingRules.contains(y) => x._2.map(y :: _)
        }
      )
      build_paths = {
        val paths = build_paths.partition(_.length < newk)
        final_paths ++= paths._2
        paths._1
      }
    }
    final_paths.filter(validPath)
  }
}

class RecurrentKPathCoverageGoal(k: Int)(implicit grammar: GrammarRepr, random: Random, reach: Reachability) extends KPathCoverageGoal(k) {
  // backup of original targets
  private val targetPool = targets.toList

  // never ending targets
  override val targetCount: Int = Int.MaxValue

  override def usedDerivation(rule: DerivationRule, parent: Option[DNode]): Unit = {
    val tuple = getTupleEndingIn(rule, parent)
    targets -= tuple
    // difference from superclass: refill targets
    if (targets.isEmpty)
      targets ++= random.shuffle(targetPool)
    if (target.headOption.contains(rule))
      target = target.tail
  }
}

class PowerSetCoverageGoals(k: Int, p: Int)(implicit grammar: GrammarRepr, random: Random, reach: Reachability) {
  require(p >= 1, s"p must be >= 1 ($p given)")
  private val original = new KPathCoverageGoal(k)

  def goals: Iterator[KPathCoverageGoal] = (1 to original.targets.size).view.flatMap { n =>
    original.targets.subsets(n).take(p).map { ts =>
      val goal = new KPathCoverageGoal(k)
      goal.targets.clear()
      goal.targets ++= ts
      goal
    }
  }.iterator
}
