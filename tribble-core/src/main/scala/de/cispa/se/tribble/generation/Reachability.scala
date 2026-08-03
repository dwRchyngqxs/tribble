package de.cispa.se.tribble
package generation

import org.jgrapht.Graph
import org.jgrapht.alg.shortestpath.{CHManyToManyShortestPaths, EppsteinShortestPathIterator}
import org.jgrapht.graph.DefaultEdge
import org.jgrapht.graph.builder.{GraphBuilder, GraphTypeBuilder}
import org.jgrapht.util.{ConcurrencyUtil, SupplierUtil}

import java.util.{Collections, Map => JMap, Set => JSet}
import scala.collection.JavaConverters._
import scala.collection.mutable
import org.jgrapht.graph.GraphWalk
import de.cispa.se.tribble.output.{TextDSLPrettyPrinter, Precedence}

sealed class Reachability(grammar: GrammarRepr) {
  /**
    * This directed unweighted graph represents the derivations of the grammar.
    * The vertices are [[DerivationRule]]s and the edges are possible derivations.
    */
  val grammarGraph: Graph[DerivationRule, DefaultEdge] = Reachability.constructGraph(grammar)

  private val _immediateSuccessors: mutable.Map[DerivationRule, mutable.Set[DerivationRule]] =
    mutable.Map(grammarGraph.vertexSet().asScala.toSeq.map(_ -> mutable.Set[DerivationRule]()): _*)

  private val _reachability: mutable.Map[DerivationRule, mutable.Map[DerivationRule, Int]] =
    mutable.Map(grammarGraph.vertexSet().asScala.toSeq.map(_ -> new mutable.HashMap[DerivationRule, Int].withDefaultValue(Int.MaxValue)): _*)

  // gather interesting rules that are not guaranteed to be reachable from the root
  private val preliminaryTargets = grammarGraph.vertexSet().asScala.filter(isInteresting).toSet
  private val paths = {
    val executor = ConcurrencyUtil.createThreadPoolExecutor(Runtime.getRuntime.availableProcessors())
    val calc = new CHManyToManyShortestPaths(grammarGraph, executor)
    val paths = calc.getManyToManyPaths(grammarGraph.vertexSet(), preliminaryTargets.asJava)
    executor.shutdown()
    paths
  }

  def pp(x: DerivationRule) = TextDSLPrettyPrinter(x)
  // Populate the reachability and immediate successors by consulting the shortest paths
  // from all nodes in the graph to all interesting nodes.
  grammarGraph.vertexSet().forEach { s =>
    preliminaryTargets.foreach { t =>
      // There is an edge case if s == t, the shotest reported path is of length 0.
      // Instead we try a self loop or use the shortest path starting from a children
      val path = if (s != t) paths.getPath(s, t)
      else if (grammarGraph.containsEdge(s, t)) {
        new GraphWalk(grammarGraph, s, t, List(grammarGraph.getEdge(s, t)).asJava, 1)
      } else {
        val candidates = grammarGraph.outgoingEdgesOf(s).asScala.map { e =>
          val p = paths.getPath(grammarGraph.getEdgeTarget(e), t)
          if (p == null) null else new GraphWalk(grammarGraph, s, t, (e :: p.getEdgeList().asScala.toList).asJava, p.getWeight() + 1)
        }.filter(_ != null)
        if (candidates.isEmpty) null else candidates.minBy(_.getLength())
      }
      if (path != null) {
        _reachability(s)(t) = path.getLength
        // if there are no interesting rules between the source and target, the target is immediately reachable
        if (path.getVertexList.asScala.drop(1).reverseIterator.drop(1).forall(!isInteresting(_))) {
          _immediateSuccessors(s).add(t)
        }
      }
    }
  }

  /** The set of derivation rules that are of interest to the current metric. */
  val interestingRules: Set[DerivationRule] = {
    _reachability(grammar.root).keySet.toSet ++ (if (isInteresting(grammar.root)) {
      // Edge case: the root may not be reachable from itself,
      // however, it should still count as an interesting rule.
      Set(grammar.root)
    } else {
      Set()
    })
  }

  /** The set of derivation rules that are of interest to the current metric. */
  def getInterestingRules: JSet[DerivationRule] = Collections.unmodifiableSet(interestingRules.asJava)

  /** For all derivation rules, gives which interesting rules are reachable and after how many derivations at the least. */
  val reachability: Map[DerivationRule, mutable.Map[DerivationRule, Int]] = _reachability.toMap

  /** For all derivation rules, gives which interesting rules are reachable and after how many derivations at the least. */
  def getReachability: JMap[DerivationRule, JMap[DerivationRule, Int]] = {
    Collections.unmodifiableMap(_reachability.mapValues[JMap[DerivationRule, Int]](x => Collections.unmodifiableMap(x.asJava)).asJava)
  }

  /** For all derivation rules, gives which interesting rules are reachable as the next k-path node. */
  val immediateSuccessors: Map[DerivationRule, Set[DerivationRule]] = _immediateSuccessors.mapValues(_.toSet).toMap

  /** For all derivation rules, gives which interesting rules are reachable as the next k-path node. */
  def getImmediateSuccessors: JMap[DerivationRule, JSet[DerivationRule]] = {
    Collections.unmodifiableMap(_immediateSuccessors.mapValues(x => Collections.unmodifiableSet(x.asJava)).asJava)
  }

  /** Indicates whether to consider this rule as a target for reachability. References and Terminals by default. */
  protected def isInteresting(rule: DerivationRule): Boolean = rule match {
    case _: Reference => true
    case _: TerminalRule => true
    case _ => false
  }
}

object Reachability {
  private[tribble] def constructGraph(g: GrammarRepr): Graph[DerivationRule, DefaultEdge] = {
    val emptyGraph: Graph[DerivationRule, DefaultEdge] = GraphTypeBuilder
      .directed()
      .weighted(false)
      .allowingMultipleEdges(false)
      .allowingSelfLoops(true)
      .edgeSupplier(SupplierUtil.DEFAULT_EDGE_SUPPLIER)
      .buildGraph()

    val builder: GraphBuilder[DerivationRule, DefaultEdge, Graph[DerivationRule, DefaultEdge]] = new GraphBuilder(emptyGraph)

    var found = mutable.Set[NonTerminal]()
    g.rules.values.flatMap(_.toStream).foreach {
      case ref: Reference => {
        found += ref.name
        builder.addEdge(ref, g(ref))
      }
      case c: Concatenation => c.elements.foreach(builder.addEdge(c, _))
      case a: Alternation => a.alternatives.foreach(builder.addEdge(a, _))
      case q: Quantification => if (q.max > 0) {
        builder.addEdge(q, q.subject)
        if (q.max > 1) builder.addEdge(q, q)
      }
      case _: TerminalRule =>
    }
    builder.addVertex(g.root)
    if (g.ignore != "") builder.addVertex(g(g.ignore))

    builder.buildAsUnmodifiable()
  }
}

class NonTerminalReachability(grammar: GrammarRepr) extends Reachability(grammar) {

  override protected def isInteresting(rule: DerivationRule): Boolean = rule.isInstanceOf[Reference]
}

class NewReachability(grammar: GrammarRepr) extends Reachability(grammar) {
  override protected def isInteresting(rule: DerivationRule): Boolean =
    grammarGraph.incomingEdgesOf(rule).asScala.exists(grammarGraph.getEdgeSource(_) match {
      case Alternation(alts, _) => alts.size > 1
      case Quantification(_, min, max, _) => min < max // Quantifications have a self-edge so may be interesting
      case _ => false
    })
}