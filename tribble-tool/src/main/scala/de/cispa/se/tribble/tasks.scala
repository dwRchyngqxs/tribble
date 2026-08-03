package de.cispa.se.tribble

import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Path}

import de.cispa.se.tribble.Internal._
import de.cispa.se.tribble.input.{AlternationExtraction, ObjectStreamGrammarCache, RuleInlining}
import de.cispa.se.tribble.generation.{GoalBasedTreeGenerator, KPathThroughPath}
import org.backuity.clist.{Command, opt}
import org.log4s.getLogger

trait Task {
  def execute(): Unit
}

final class GenerateTask extends Command("generate", "Generate sample inputs")
  with Task with ForestGeneratorModule with OutputModule with TreeOutputModule with RandomnessModule with GrammarModule with CacheModule with RegexModule with ReportingModule with HeuristicModule with CloseOffControlModule {
  private val logger = getLogger

  override def execute(): Unit = {
    logger.info(s"Using random seed $randomSeed")
    logger.info(s"Writing generated files to $outputDir")
    val trees = forestGenerator.generateForest()
    for ((tree, i) <- trees.zipWithIndex) {
      reporter.processTree(i + 1, tree)
      val input = treePP(tree)
      val path = Files.write(Files.createTempFile(outputDir, f"file${i + 1}%06d_${tree.size()}%d_${tree.depth()}%d_", suffix), input.getBytes(StandardCharsets.UTF_8))
      logger.debug(s"Generated $path")
    }

  }
}

final class InlineGrammarTask extends Command("inline", "Output grammar with inlined productions")
  with Task with CacheModule with GrammarModule with GrammarOutputModule {
  var inlineLevels: Int = opt[Int](description = "How many times to perform inlining. Default 1", default = 1)

  override def execute(): Unit = {
    val inlined = new RuleInlining(inlineLevels).process(grammar)
    val serialized = grammarPP(inlined)
    Files.write(Files.createFile(Path.of(outputPath)), serialized.getBytes(StandardCharsets.UTF_8))
  }
}

final class ExtractAlternationsTask extends Command("extract-alternations", "Output grammar with all alternations extracted to top level")
  with Task with CacheModule with GrammarModule with GrammarOutputModule {

  override def execute(): Unit = {
    val extracted = AlternationExtraction.process(grammar)
    val serialized = grammarPP(extracted)
    Files.write(Files.createFile(Path.of(outputPath)), serialized.getBytes(StandardCharsets.UTF_8))
  }
}

/*final class MutateGrammarTask extends Command("mutate-grammar", "Mutate grammar and generate discriminating derivation trees")
  with Task with GrammarMutationModule with RandomnessModule with CloseOffControlModule with RegexModule with CacheModule with OutputModule with GrammarModule with GrammarOutputModule {
  /*
    \item[Repetition$^\prime$] Given any subrule, if it is a repetition then widen the allowed number of repetitions by 1 either on the lower bound or upper bound of repetition.
      To do so the repetition is alternated with a new non-terminal whose rule only allows the new number of repetitions.
      If the subrule is anything else, alternate it either with the empty terminal or with a new non-terminal enclosed in a repetition of twice or more, and whose rule is the same as the starting subrule.
      This version of \textbf{Repetition} is more general than the original.
    \item[Substitution] Given any subrule, alternate it with a new non-terminal whose rule is any subrule of any rule.
      This is more general than \textbf{Introduce choice}.
    \item[Insertion] Given a subrule, concatenate it before or after a new non-terminal in an option operator, new non-terminal whose rule is any subrule of any rule.
      This is more general than \textbf{Concatenation}.
    \item[Alternation mixing] Given an alternation, if all choices are concatenations and share a subrule, replace the alternation with an alternation of new non-terminals, covering all combinations of: the part of the alternation before the shared subrule, the shared subrule, the part of the alternation after the shared subrule.
      This is a new mutation which emulates breaking an alternation before and after a common part, a frequent parser extension to improve leniency.
  */

  private def mutateGrammar(): (GrammarRepr, List[DerivationRule]) = {
    val mutation = random.nextInt(4)
    val derivations = {
      // import org.jgrapht.alg.connectivity.ConnectivityInspector
      val reachDerivations = new ConnectivityInspector(reach.grammarGraph).connectedSetOf(grammar.root).asScala.toSeq
      if (mutation == 3) reachDerivations.filter{_.isIntanceOf[Alternation]}
      else if (mutation == 2) reachDerivations.filter{!_.isIntanceOf[Reference]} + grammar.root
      else reachDerivations
    }
    val size = derivations.size
    val target = random.nextInt(size + (if (mutation == 2) 1 else 0))
    val oldderivation, newderivation, path = mutation match {
      case 0 => make_or_widen_repetition(derivations(target))
      case 1 => substitute(derivations(target))
      case 2 => if (target == size) insert(grammar.root, true) else insert(derivations(target), false)
      case 3 => mix(derivations(target))
    }
    GrammarRepr(grammar.start, grammar.ignore, grammar.rules.transform(_.replace(oldderivarion, newderivation)))
  }

  private def updateSubruleN(rule: DerivationRule, index: Int)(implicit tf: DerivationRule => (DerivationRule, List[DerivationRule])): Either[Int, (DerivationRule, List[DerivationRule])] =
    if (index == 0) Right(tf(rule))
    else rule match {
      case Concatenation(elements, id) => {
        var acc: Either[Int, (DerivationRule, DerivationRule)] = Left(index - 1)
        var i = 0
        while (acc.isLeft && i < elements.size) {
          acc = updateSubruleN(elements(i), acc.left.get)
          i += 1
        }
        acc.map(x => (Concatenation(elements.toArray.updated(i - 1, x._1).toSeq, id), x._2))
      }
      case Alternation(alts, id) => {
        var acc: Either[Int, (DerivationRule, DerivationRule)] = Left(index - 1)
        var i = 0
        while (acc.isLeft && i < alts.size) {
          acc = updateSubruleN(alts(i), acc.left.get)
          i += 1
        }
        acc.map(x => (Alternation(alts.toArray.updated(i - 1, x._1).toSeq, id), x._2))
      }
      case Quantification(subject, min, max, id) => updateSubruleN(subject, index - 1).map(x => (Quantification(x._1, min, max, id), x._2))
      case _ => Left(index - 1)
    }

  override def execute(): Unit = {
    val newGrammars = (1 to mutationCount).map(_ => mutateGrammar)
    for (((g, p), i) <- newGrammars.zipWithIndex) {
      Files.write(Files.createFile(Path.of(i.toString + outputPath)), prettyPrinter(g).getBytes(StandardCharsets.UTF_8))
      val trees = new GoalBasedTreeGenerator(shortestTreeGenerator, random)(g, new KPathThroughPath(k.toInt, p)(g, random, new NewReachability(g))).generateForest()
      val pp = new DTreePrettyPrinter(g, shortestTreeGenerator)
      for ((tree, i) <- trees.zipWithIndex) {
        val input = pp(tree)
        val path = Files.write(Files.createTempFile(outputDir, f"${i}%06d_", suffix), input.getBytes(StandardCharsets.UTF_8))
      }
    }
  }
}
*/

final class GenerateForestationTask extends Command(name = "forestation", description = "Generate a forest of forests spanning a k-path coverage saturation range")
  with Task with ForestationGenerationModule with OutputModule with TreeOutputModule with RandomnessModule with GrammarModule with CacheModule with RegexModule with HeuristicModule with CloseOffControlModule {
  private val logger = getLogger

  override def execute(): Unit = {
    logger.info(s"Using random seed $randomSeed")
    logger.info(s"Writing generated forests to $outputDir")

    val forests = forestationGenerator.map(_.generateForest())
    for ((forest, j) <- forests.zipWithIndex) {
      val dir = Files.createDirectory(outputDir.resolve(f"forest$j%06d"))
      logger.debug(s"Creating forest $j")
      val reporter = new KPathReporter(Files.createFile(outputDir.resolve(f"forest$j%06d.csv")).toFile, k)(grammar, random, reachability)
      for ((tree, i) <- forest.zipWithIndex) {
        reporter.processTree(i + 1, tree)
        val input = treePP(tree)
        Files.write(Files.createTempFile(dir, f"file${i + 1}%06d_${tree.size()}%d_", suffix), input.getBytes(StandardCharsets.UTF_8))
      }
    }
  }
}

final class CacheGrammarTask extends Command("cache-grammar", "Put a grammar into the cache for faster loading in the future")
  with Task with GrammarModule with CacheModule {
  override def execute(): Unit = {
    // ignore the grammarCache from the CacheModule because it might be the EmptyGrammarCache
    Files.createDirectories(grammarCacheDir.toPath)
    val cache = new ObjectStreamGrammarCache(grammarCacheDir)
    for (gf <- grammarFiles)
      cache.storeGrammar(grammarLoader.loadGrammar(gf), grammarHash(gf))
  }
}
