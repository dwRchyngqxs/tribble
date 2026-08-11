package de.cispa.se.tribble
package input

import better.files._
import java.nio.charset.StandardCharsets

import fastparse.{P, ParserInput, parse}
import fastparse.Parsed.Failure

private[input] trait InputGrammarParser {
  def parseGrammar(grammarFile: File): Seq[Production] = {
    parse(ParserInput.fromString(grammarFile.lines(StandardCharsets.UTF_8) mkString "\n"), grammar(_)).fold(
      (label, index, extra) => throw new IllegalArgumentException(s"Error while parsing $label at position ${extra.input.prettyIndex(index)} (${Failure.formatTrailing(extra.input, index)})"),
      (rules, _) => rules
    )
  }

  def grammar[_: P]: P[Seq[Production]]
}
