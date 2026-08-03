package de.cispa.se.tribble.input

import java.io.{File, _}

import better.files._
import de.cispa.se.tribble.{NonTerminal, DerivationRule}

object GrammarSerializer {
  def serializeGrammar(rules: Map[NonTerminal, DerivationRule], file: File): Unit =
  // make sure we have the fully materialized object here and not just a lazy view
    using(new ObjectOutputStream(file.toScala.newOutputStream())) {
      _.writeObject(rules.view.force)
    }

  def deserializeGrammar(file: File): Map[NonTerminal, DerivationRule] =
    using(new ObjectInputStream(file.toScala.newInputStream)) {
      _.readObject().asInstanceOf[Map[NonTerminal, DerivationRule]]
    }
}
