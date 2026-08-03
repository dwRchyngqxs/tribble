package de.cispa.se.tribble
package generation

import dk.brics.automaton.{Automaton, State, Transition}

import scala.collection.JavaConverters.iterableAsScalaIterable
import scala.annotation.tailrec
import scala.util.Random

private[tribble] class RegexGenerator(random: Random, minLength: Int) {

  @tailrec
  private def generateString(state: State)(implicit builder: StringBuilder): Unit = {
    val transitions = state.getTransitions
    // carry on if we are not in an accepting state or there is still input to generate to reach minLength
    if (!state.isAccept || !transitions.isEmpty && !(builder.length >= minLength && random.nextBoolean())) {
      var total = 0
      for (t <- iterableAsScalaIterable(transitions)) total += t.getMax - t.getMin + 1
      val (res, dest) = selectTransition(random.nextInt(total))(iterableAsScalaIterable(transitions).iterator)
      builder.append(res)
      generateString(dest)
    }
  }

  @tailrec
  private def selectTransition(n: Int)(implicit it: Iterator[Transition]): (Char, State) = {
    val t = it.next
    val m = n + t.getMin
    if (m > t.getMax) selectTransition(m - t.getMax - 1)
    else (m.asInstanceOf[Char], t.getDest)
  }

  private[tribble] def generateIntoBuilder(automaton: Automaton, builder: StringBuilder): StringBuilder = {
    generateString(automaton.getInitialState)(builder)
    builder
  }

}
