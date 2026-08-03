package de.cispa.se.tribble
package input

import java.io.File


/**
  * Tries to load the corresponding grammar from the cache, or failing to do so,
  * applies the given loading strategy to acquire the grammar from the given file.
  */
private[tribble] class GrammarLoader(loadingStrategy: LoadingStrategy, grammarCache: GrammarCache) {

  def loadGrammars(grammarFiles: Seq[File]): Map[NonTerminal, DerivationRule] =
    grammarFiles.map(loadGrammar).reduce{ (l, r) =>
      val duplicated = l.keySet & r.keySet
      if (duplicated.isEmpty) l ++ r
      else throw new IllegalArgumentException(s"Cannot redefine non terminals in different grammars: ${duplicated.mkString(", ")}")
    }

  def loadGrammar(grammarFile: File): Map[NonTerminal, DerivationRule] =
    grammarCache.loadGrammar(grammarFile.computeHash()) match {
      case Some(grammar) => grammar
      case None => loadingStrategy.load(grammarFile)
    }
}
