package de.cispa.se.tribble
package output

object Precedence extends Enumeration {
  type Precedence = Value
  val PAlternation, PConcatenation, PQuantifier, PAtom = Value
}

import Precedence._

trait GrammarPrettyPrinter {
  def apply(grammar: GrammarRepr): String
  def apply(rule: DerivationRule): String
}

class ScalaDSLPrettyPrinter(printID: Boolean = false, printProb: Boolean = false) extends GrammarPrettyPrinter {
  override def apply(grammar: GrammarRepr): String =
    "Grammar(\n" + grammar.rules.iterator.map { case (name, rule) => s"'$name := " + apply(rule) }.mkString(",\n") + "\n)\n"

  override def apply(rule: DerivationRule): String = {
    var builder = new StringBuilder
    rule match {
      case Reference(name, id) =>
        builder ++= s"'$name"
        appendId(builder, id)
      case Concatenation(elements, id) =>
        builder += '('
        builder ++= elements.map(apply).mkString(" ~ ")
        builder += ')'
        appendId(builder, id)
      case Alternation(alts, id) =>
        builder += '('
        builder ++= alts.map(apply).mkString(" | ")
        builder += ')'
        appendId(builder, id)
      case Quantification(subject, min, max, id) =>
        builder += '('
        builder ++= apply(subject)
        builder += ')'
        builder ++= ((min, max) match {
          case (0, 1) => ".?"
          case (0, Int.MaxValue) => ".rep"
          case (1, Int.MaxValue) => ".rep(1)"
          case _ => s".rep($min,$max)"
        })
	appendId(builder, id)
      case Literal(value, id) =>
        builder ++= fastparse.internal.Util.literalize(value, unicode = true)
        appendId(builder, id)
      case Regex(value, id) =>
        builder ++= fastparse.internal.Util.literalize(value, unicode = true)
        builder ++= ".regex"
        appendId(builder, id)
    }
    if (printProb && !rule.probability.isNaN) builder ++= s" @@ ${rule.probability}"
    builder.toString
  }

  private def appendId(builder: StringBuilder, id: Int): Unit = if (printID && id != 0) builder ++= s"/*@$id*/"
}

object TextDSLPrettyPrinter extends GrammarPrettyPrinter {
  override def apply(grammar: GrammarRepr): String =
    grammar.rules.iterator.map { case (name, rule) => s"$name: " + apply(rule, PAlternation) + ";\n" }.mkString

  override def apply(rule: DerivationRule): String = apply(rule, PAlternation)

  def apply(rule: DerivationRule, prec: Precedence = PAlternation): String = rule match {
    case Reference(name, _) => name
    case Concatenation(elements, _) => {
      val x = elements.map(apply(_, PQuantifier)).mkString(" ")
      if (prec > PConcatenation) s"($x)" else x
    }
    case Alternation(alts, _) => {
      val x = alts.map(apply(_, PConcatenation)).mkString(" | ")
      if (prec > PAlternation) s"($x)" else x
    }
    case Quantification(subject, min, max, _) => {
      val x = apply(subject, PAtom)
      val q = (min, max) match {
        case (0, 1) => "?"
        case (0, Int.MaxValue) => "*"
        case (1, Int.MaxValue) => "+"
        case _ => s"{$min,$max}"
      }
      if (prec > PQuantifier) s"($x)$q" else s"$x$q"
    }
    case Literal(value, _) => {
      val x = value.flatMap {
        case '\n' => "\\n"
        case '\r' => "\\r"
        case '\t' => "\\t"
        case '\b' => "\\b"
        case '\f' => "\\f"
        case '\\' => "\\\\"
        case '\'' => "\\'"
        case c => c.toString
      }
      s"'$x'"
    }
    case Regex(value, _) => {
      val x = value.flatMap {
        case '\n' => "\\n"
        case '\r' => "\\r"
        case '\t' => "\\t"
        case '\b' => "\\b"
        case '\f' => "\\f"
        case c => c.toString
      }
      s"/$x/"
    }
  }
}
