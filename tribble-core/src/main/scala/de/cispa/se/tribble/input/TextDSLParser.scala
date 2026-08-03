package de.cispa.se.tribble
package input

import fastparse._
import fastparse.ScalaWhitespace._

private[tribble] object TextDSLParser extends InputGrammarParser {
  private def escape[_: P]: P[String] = ("\\" ~~/ CharIn("'\\\\nrtbf")).!.map(StringContext.treatEscapes)

  private def terminal[_: P]: P[Literal] = "'" ~~/ (escape | CharsWhile(!"'\\".contains(_)).!).repX.map(_.mkString).map(Literal(_)) ~~/ "'"

  private def regexEscape[_: P]: P[String] = ("\\" ~~/ AnyChar).!.map {
    case "\\n" => "\n"
    case "\\r" => "\r"
    case "\\t" => "\t"
    case "\\b" => "\b"
    case "\\f" => "\f"
    case s => s
  }

  private def regex[_: P]: P[Regex] = ("/" ~~/ !"/" ~~/ (regexEscape | CharsWhile(!"/\\".contains(_)).!).repX ~~/ "/").map(_.mkString).map(Regex(_))

  private def reference[_: P]: P[Reference] = CharsWhile((('A' to 'Z') ++ ('a' to 'z') ++ ('0' to '9') ++ "_").contains(_)).!.map(Reference(_))

  private def num[_: P]: P[Int] = CharsWhileIn("0-9").!.map(_.toInt)

  private def repQuant[_: P]: P[(Int, Int)] = (num ~ &("}")).filter(_ > 1).map(n => (n, n))

  private def oneQuant[_: P]: P[(Int, Int)] = ("," ~/ num).map(n => (0, n)) | P(num ~ "," ~ &("}")).map(n => (n, Int.MaxValue))

  private def twoQuant[_: P]: P[(Int, Int)] = (num ~ "," ~/ num).filter { case (min, max) => min <= max && (max != 1 || min != 1) }

  private def braceQuant[_: P]: P[(Int, Int)] = "{" ~/ (repQuant | oneQuant | twoQuant) ~/ "}"

  private def kleeneQuant[_: P]: P[(Int, Int)] = P("?").map(_ => (0, 1)) | P("*").map(_ => (0, Int.MaxValue)) | P("+").map(_ => (1, Int.MaxValue))

  private def quantifier[_: P]: P[(Int, Int)] = braceQuant | kleeneQuant

  private def atom[_: P]: P[DerivationRule] = (("(" ~/ alternation ~/ ")" | regex | terminal | reference) ~/ quantifier.?).map {
    case (sym, None) => sym
    case (sym, Some((min, max))) => Quantification(sym, min, max)
  }

  private def prob[_: P]: P[Double] = "@@" ~/ CharsWhile("0123456789.xXabcdefABCDEFpP-".contains(_)).!.map(_.toDouble)

  private def concatenation[_: P]: P[DerivationRule] = (atom.rep(1).map { case Seq(e) => e case seq => Concatenation(seq) } ~/ prob.?).map {
    case (c, None) => c
    case (c, Some(p)) =>
      c.probability = p
      c
  }

  private def alternation[_: P]: P[DerivationRule] = concatenation.rep(min = 1, sep = "|"./).map(_.distinct).map { case Seq(e) => e case seq => Alternation(seq) }

  private def production[_: P]: P[Production] = (reference ~/ ":" ~/ alternation ~/ ";").map { case (Reference(name, _), rhs) => name -> rhs }

  override def grammar[_: P]: P[Seq[Production]] = Start ~/ production.rep(1) ~/ End
}
