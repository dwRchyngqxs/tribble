package de.cispa.se.tribble
package input

import de.cispa.se.tribble.generation.Reachability
import de.cispa.se.tribble.model.AutomatonTransformer
import org.jgrapht.alg.connectivity.ConnectivityInspector
import org.log4s.getLogger

import java.util.StringJoiner
import scala.collection.JavaConverters._
import scala.collection.mutable

private[tribble] class ModelAssembler(
    automatonCache: AutomatonCache,
    damping: Double = Double.MinPositiveValue,
    similarity: Double = 1.0d,
    transformRegexes: Boolean = false,
    checkDuplicateAlternatives: Boolean = true,
    checkIds: Boolean = true,
    assignProbabilities: Boolean = true,
    epsilonizeQuantifications: Boolean = false,
    startRule: Option[String] = None,
    ignoreRule: Option[String] = None,
  ) {

  private val phases = mutable.ListBuffer[AssemblyPhase]()
  private[tribble] def appendPhase(phase: AssemblyPhase): Unit = phases.append(phase)

  appendPhase(EnsureConnected)
  appendPhase(new AutomatonAssembly(automatonCache))
  if (transformRegexes) appendPhase(RegexTransformation)
  if (checkDuplicateAlternatives) appendPhase(CheckDuplicateAlternatives)
  if (epsilonizeQuantifications) appendPhase(QuantificationEpsilonization)
  appendPhase(AssignIds)
  if (checkIds) appendPhase(CheckIds)
  appendPhase(ShortestDerivationComputation)
  if (assignProbabilities) {
    appendPhase(ProbabilityAssignment)
    appendPhase(new ProbabilityRemapping(damping, similarity))
  }
  appendPhase(GrammarStatistics)

  def assemble(rules: Map[NonTerminal, DerivationRule]): GrammarRepr = {
    val nts = rules.keySet
    val ignore = ignoreRule match {
      case Some(nt) =>
        if (!nts.contains(nt)) throw new IllegalArgumentException(s"Provided ignore rule $nt doesn't exist!")
        nt
      case None => if (nts.contains("ignore")) "ignore" else ""
    }
    // We want to keep track of non-terminals that are used in the grammar
    // to find undefined referenced and also if required
    // to find the one that is unused and will be treated as the root.
    val used = rules.flatMap(_._2.toStream.collect{ case Reference(name, _) => name }).toSet
    val start = startRule match {
      case Some(nt) =>
        if (!nts.contains(nt)) throw new IllegalArgumentException(s"Provided start rule $nt doesn't exist!")
        nt
      case None if nts.contains("start") => "start"
      case None => {
        val unused = nts diff (used + ignore)
        if (unused.isEmpty) throw new IllegalArgumentException("Cannot infer grammar start symbol as there are no unused symbol!")
        if (unused.size > 1) throw new IllegalArgumentException(s"Cannot infer grammar start symbol as there are multiple unused symbols: ${unused.mkString(", ")}")
        unused.head
      }
    }    
    val undefined = used diff nts
    if (undefined.nonEmpty) throw new IllegalArgumentException(raw"Grammar contains undefined symbols: ${undefined.mkString(", ")}")
    var grammar = GrammarRepr(start, ignore, rules)
    for (phase <- phases) grammar = phase.process(grammar)
    grammar
  }
}

private[tribble] object ModelAssembler {
  def makeMap(productions: Seq[Production]): Map[NonTerminal, DerivationRule] = {    
    val rules = productions.groupBy(_._1)
    val duplicated = rules.filter(_._2.size > 1).map(_._1)
    if (duplicated.size > 0) throw new IllegalArgumentException(s"Cannot have multiple declarations for: ${duplicated.mkString(", ")}")
    rules.mapValues(_.head._2)
  }
}

trait AssemblyPhase {
  def process(grammar: GrammarRepr): GrammarRepr

  protected case class Box[T](var value: T)
}

object EnsureConnected extends AssemblyPhase {
  override def process(grammar: GrammarRepr): GrammarRepr = {
    // Throw if there are rules in the grammar that are not reachable from the root or ignore.
    val graph = Reachability.constructGraph(grammar)
    val allNodes = graph.vertexSet().asScala
    val inspector = new ConnectivityInspector(graph)
    val rootReach = inspector.connectedSetOf(grammar.root).asScala
    val ignoreReach = if (grammar.ignore == "") mutable.Set()
      else inspector.connectedSetOf(grammar(grammar.ignore)).asScala
    val reach = rootReach ++ ignoreReach
    if (reach.size < allNodes.size) {
      val unreachable = allNodes diff reach
      throw new IllegalArgumentException(s"Grammar contains symbols unreachable from the root ${grammar.start} and ignore: ${unreachable.mkString(", ")}")
    }
    grammar
  }
}

object ShortestDerivationComputation extends AssemblyPhase {
  private val logger = getLogger

  private def incNoOverflow(value: Int): Int = if (value >= Int.MaxValue - 1) Int.MaxValue else value + 1

  private def resolve(rule: DerivationRule)(implicit resolved: mutable.Map[NonTerminal, Int], grammar: GrammarRepr): Int = {
    rule match {
      case r@Reference(name, _) =>
        r.shortestDerivation = incNoOverflow(resolved.getOrElse(name, Int.MaxValue))
      case c@Concatenation(elements, _) =>
        c.shortestDerivation = incNoOverflow(elements.map(resolve).max)
      case a@Alternation(alternatives, _) =>
        a.shortestDerivation = incNoOverflow(alternatives.map(resolve).min)
      case q@Quantification(subject, min, _, _) =>
        q.shortestDerivation = if (min == 0) 1 else incNoOverflow(resolve(subject))
      case _ =>
    }
    rule.shortestDerivation
  }


  private def updateShortestDerivation(prod: Production)(implicit resolved: mutable.Map[NonTerminal, Int], grammar: GrammarRepr): Unit = {
    val (nonterm, rule) = prod
    val min = rule.toStream.minBy(resolve).shortestDerivation
    if (min < Int.MaxValue)
      resolved(nonterm) = rule.shortestDerivation
  }

  override def process(grammar: GrammarRepr): GrammarRepr = {
    val storage = new mutable.HashMap[NonTerminal, Int]()
    var c = 1
    do {
      grammar.rules.foreach(updateShortestDerivation(_)(storage, grammar))
      c += 1
    } while (grammar.rules.values.flatMap(_.toStream).exists(_.shortestDerivation == Int.MaxValue))
    logger.info(s"Computed shortest derivations in $c iterations.")
    grammar
  }
}

class AutomatonAssembly(automatonCache: AutomatonCache) extends AssemblyPhase {
  private val logger = getLogger

  override def process(grammar: GrammarRepr): GrammarRepr = {
    logger.info("Constructing regex automata...")
    var constructed = 0
    grammar.rules.values.flatMap(_.toStream).foreach {
      case r@Regex(pattern, _) if r.automaton == null =>
        r.automaton = automatonCache.getAutomaton(pattern)
        constructed += 1
      case _ =>
    }
    logger.info(s"Constructed $constructed automata.")
    grammar
  }
}

object RegexTransformation extends AssemblyPhase {
  private val logger = getLogger

  private def expandedRule(rule: DerivationRule)(implicit transformedAutomata: Box[Int]): (DerivationRule, Map[NonTerminal, DerivationRule]) = {
    val expanded: (DerivationRule, Map[NonTerminal, DerivationRule]) = rule match {
      case q@Quantification(subject, min, max, _) =>
        val (s, additions) = expandedRule(subject)
        val newQ = Quantification(s, min, max)
        newQ.probability = q.probability
        newQ -> additions
      case alt@Alternation(alternatives, _) =>
        val set = alternatives.map(expandedRule)
        val a = set.map(_._1)
        val additions = set.flatMap(_._2)
        val newAlt = Alternation(a)
        newAlt.probability = alt.probability
        newAlt -> additions.toMap
      case conc@Concatenation(elements, _) =>
        val list = elements.map(expandedRule)
        val e = list.map(_._1)
        val additions = list.flatMap(_._2)
        val newConc = Concatenation(e)
        newConc.probability = conc.probability
        newConc -> additions.toMap
      case r: Reference => r -> Map.empty
      case l: Literal => l -> Map.empty
      case r: Regex =>
        val (name, productions) = AutomatonTransformer.transform(r.automaton, s"r_${transformedAutomata.value}_")
        transformedAutomata.value += 1
        val newRef = Reference(name)
        newRef.probability = r.probability
        newRef -> productions
    }
    expanded
  }

  override def process(grammar: GrammarRepr): GrammarRepr = {
    logger.info("Transforming automata into productions...")
    implicit val transformedAutomata: Box[Int] = Box(0)

    // keep outstanding changes
    val updatedProductions = mutable.Map[NonTerminal, DerivationRule]()

    grammar.rules.foreach { case (nonterm, rule) =>
      val (newRule, productions) = expandedRule(rule)
      updatedProductions(nonterm) = newRule
      updatedProductions ++= productions
    }
    // might need to force the view

    logger.info(s"Transformed ${transformedAutomata.value} automata into productions.")
    GrammarRepr(grammar.start, grammar.ignore, updatedProductions.toMap)
  }

}

/** Assigns unique ids to all derivation rules that have it as [[DerivationRule.DEFAULT_ID]]. */
object AssignIds extends AssemblyPhase {
  override def process(grammar: GrammarRepr): GrammarRepr = {
    // phase 1: scan for rules that already have ids set
    val seenIds = grammar.rules.values.flatMap(_.toStream).map(_.id).toSet

    // phase 2: assign outstanding ids
    val availableIds = Iterator.from(0).filterNot(seenIds)

    grammar.rules.values.flatMap(_.toStream)
      .filter(_.id == DerivationRule.DEFAULT_ID)
      .foreach { rule =>
        rule.id = availableIds.next()
      }

    grammar
  }
}

trait ApproximateDoubleCalc {
  private val precision = 1E-9d

  protected def approxEqual(value: Double, other: Double): Boolean = (value - other).abs < precision

  protected def approxLess(value: Double, other: Double): Boolean = (other - value) > precision
}

object ProbabilityAssignment extends AssemblyPhase with ApproximateDoubleCalc {
  private val logger = getLogger

  private def processRHS(lhs: NonTerminal, rhs: DerivationRule): Unit = rhs match {
    case Alternation(alternatives, _) =>
      var p = 1.0d
      var unaccounted = mutable.ListBuffer[DerivationRule]()
      for (a <- alternatives) {
        if (a.probability.isNaN)
          unaccounted += a
        else
          p -= a.probability
      }
      if (approxLess(p, 0)) throw new IllegalArgumentException(s"The alternatives for $lhs have cumulative probability > 1!")
      if (approxEqual(p, 0) && unaccounted.nonEmpty) logger.warn(s"Some un-annotated alternatives for $lhs have probability zero!")
      // uniformly distribute the remaining probability
      unaccounted.foreach(_.probability = p / unaccounted.size)

      // scale up if necessary
      val orderedAlts = alternatives.toList
      val sum = orderedAlts.map(_.probability).sum
      if (approxLess(sum, 1.0d)) {
        logger.warn(s"The alternatives for $lhs have cumulative probability < 1. They will be effectively scaled up proportionately!")
        val factor = 1.0d / sum
        for (a <- orderedAlts)
          a.probability *= factor
      }
      assert(approxEqual(1.0d, alternatives.map(_.probability).sum))
    case _ =>
  }

  private def issueWarnings(lhs: NonTerminal, parent: DerivationRule): Unit = parent match {
    case Alternation(alternatives, _) => alternatives.foreach(issueWarnings(lhs, _))
    case _ =>
      val annotated = parent.children.filterNot(_.probability.isNaN)
      if (annotated.nonEmpty)
        logger.warn(s"The following elements annotated with probabilities are not direct children of any alternation in rule $lhs. The annotations will have no effect.\n${annotated.mkString("\n")}")
      parent.children.foreach(issueWarnings(lhs, _))
  }

  override def process(grammar: GrammarRepr): GrammarRepr = {
    for ((lhs, rhs) <- grammar.rules) {
      issueWarnings(lhs, rhs)
      for (elem <- rhs.toStream) {
        processRHS(lhs, elem)
      }
    }
    grammar
  }
}

/**
  * Maps probabilities according to p’ := (p + damping) ^similarity^
  */
class ProbabilityRemapping(damping: Double, similarity: Double) extends AssemblyPhase with ApproximateDoubleCalc {
  override def process(grammar: GrammarRepr): GrammarRepr = {
    grammar.rules.values.flatMap(_.toStream).foreach {
      case Alternation(alternatives, _) =>
        assert(alternatives.forall(!_.probability.isNaN))
        val orderedAlts = alternatives.toList

        assert(approxEqual(orderedAlts.map(_.probability).sum, 1.0d))
        for (a <- orderedAlts) {
          a.probability = math.pow(a.probability + damping, similarity)
        }

        val maxProb2 = orderedAlts.map(_.probability).sum
        for (a <- orderedAlts) {
          a.probability = a.probability / maxProb2
        }

      case _ =>
    }
    grammar
  }
}

object GrammarStatistics extends AssemblyPhase {
  private val logger = getLogger

  override def process(grammar: GrammarRepr): GrammarRepr = {
    val nodes = grammar.rules.values.flatMap(_.toStream).size
    logger.info(s"The Grammar has ${grammar.rules.size} productions and $nodes nodes")
    grammar
  }
}

object CheckDuplicateAlternatives extends AssemblyPhase {
  override def process(grammar: GrammarRepr): GrammarRepr = {
    val violations = mutable.ArrayBuffer[(NonTerminal, Seq[DerivationRule])]()
    grammar.rules.foreach {
      case (production, Alternation(alts, _)) if alts.distinct.size != alts.size => violations += production -> alts
      case _ =>
    }
    if (violations.nonEmpty) {
      val message = new StringJoiner(System.lineSeparator())
      for ((terminal, rules) <- violations) {
        val joiner = new StringJoiner(" | ", s"$terminal: [", "]")
        rules.foreach(r => joiner.add(r.toString))
        message.add(joiner.toString)
      }
      throw new IllegalArgumentException(s"Duplicate alternatives found in $message")
    }
    grammar
  }
}

/** Ensures all derivation rules have unique, valid ids. */
object CheckIds extends AssemblyPhase {
  private val logger = getLogger

  override def process(grammar: GrammarRepr): GrammarRepr = {
    var violations = false
    val seenIds = mutable.HashSet[Int]()

    grammar.rules.foreach { case (name, rule) =>
      rule.toStream.foreach { subRule =>
        if (seenIds(subRule.id)) {
          logger.error(s"Duplicate id ${subRule.id} in rule $name at $subRule")
          violations = true
        } else if (subRule.id == DerivationRule.DEFAULT_ID) {
          logger.error(s"Uninitialized id in rule $name at $subRule")
          violations = true
        }
        seenIds.add(subRule.id)
      }
    }

    if (violations) {
      throw new IllegalArgumentException("Invalid ids detected! See log for details.")
    }

    grammar
  }
}
