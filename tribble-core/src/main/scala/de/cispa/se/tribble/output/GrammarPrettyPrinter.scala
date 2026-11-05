package de.cispa.se.tribble
package output

object Precedence extends Enumeration {
  type Precedence = Value
  val PAlternation, PLocalIgnore, PConcatenation, PQuantifier, PAtom = Value
}

import Precedence._

trait GrammarPrettyPrinter {
  def apply(grammar: GrammarRepr): String
  def apply(rule: DerivationRule): String
}

class ScalaDSLPrettyPrinter(printID: Boolean = false, printProb: Boolean = false) extends GrammarPrettyPrinter {
  override def apply(grammar: GrammarRepr): String =
    "Grammar(\n" + grammar.rules.iterator.map {
      case (name, rule) => s"'$name := ${apply(rule)}"
    }.mkString(",\n") + "\n)\n"

  override def apply(rule: DerivationRule): String = {
    val sb = new StringBuilder
    apply(sb, rule)
    sb.toString
  }

  def apply(sb: StringBuilder, rule: DerivationRule): Unit = {
    rule match {
      case Reference(name, id) => {
        sb += '\''
        sb ++= name
        appendId(sb, id)
      }
      case Concatenation(elements, id) => {
        sb += '('
        apply(elements.head)
        for (e <- elements.tail) {
          sb ++= " ~ "
          apply(sb, e)
        }
        sb += ')'
        appendId(sb, id)
      }
      case Alternation(alts, id) => {
        sb += '('
        apply(alts.head)
        for (a <- alts.tail) {
          sb ++= " | "
          apply(sb, a)
        }
        sb += ')'
        appendId(sb, id)
      }
      case Quantification(subject, min, max, id) => {
        sb += '('
        apply(sb, subject)
        sb += ')'
        sb ++= ((min, max) match {
          case (0, 1) => ".?"
          case (0, Int.MaxValue) => ".rep"
          case (1, Int.MaxValue) => ".rep(1)"
          case _ => s".rep($min,$max)"
        })
        appendId(sb, id)
      }
      case LocalIgnore(subject, _, _, _, _) => apply(sb, subject)
      case Literal(value, id) => {
        sb ++= fastparse.internal.Util.literalize(value, unicode = true)
        appendId(sb, id)
      }
      case Regex(value, id) => {
        sb ++= fastparse.internal.Util.literalize(value, unicode = true)
        sb ++= ".regex"
        appendId(sb, id)
      }
    }
    if (printProb && !rule.probability.isNaN) {
      sb ++= " @@ "
      sb ++= rule.probability.toString
    }
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
      val x = alts.map(apply(_, PLocalIgnore)).mkString(" | ")
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
      if (prec > PQuantifier) s"($x$q)" else s"$x$q"
    }
    case LocalIgnore(subject, lsep, ignore, rsep, id) => {
      val ssubj = apply(subject, PConcatenation)
      val slsep = lsep match { case Some(value) => apply(value, PAtom) case None => "" }
      val signore = ignore match { case Some(value) => apply(value, PAtom) case None => "" }
      val srsep = rsep match { case Some(value) => apply(value, PAtom) case None => "" }
      val x = s"$ssubj <$slsep^$signore^$srsep>"
      if (prec > PLocalIgnore) s"($x)" else s"$x"
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
