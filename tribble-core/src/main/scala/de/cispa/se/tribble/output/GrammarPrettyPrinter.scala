package de.cispa.se.tribble
package output

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
    grammar.rules.iterator.map { case (name, rule) => s"$name: " + apply(rule) + ";\n" }.mkString
  override def apply(rule: DerivationRule): String = rule match {
    case Reference(name, _) => name
    case Concatenation(elements, _) => "(" + elements.map(apply).mkString(" ") + ")"
    case Alternation(alts, _) => "(" + alts.map(apply).mkString(" | ") + ")"
    case Quantification(subject, min, max, _) =>
      apply(subject) + ((min, max) match {
        case (0, 1) => "?"
        case (0, Int.MaxValue) => "*"
        case (1, Int.MaxValue) => "+"
        case _ => s"{$min,$max}"
      })
    case Literal(value, _) =>
      "'" + value.flatMap {
        case '\n' => "\\n"
        case '\r' => "\\r"
        case '\t' => "\\t"
        case '\b' => "\\b"
        case '\f' => "\\f"
        case '\\' => "\\\\"
        case '\'' => "\\'"
        case c => c.toString
      } + "'"
    case Regex(value, _) => "/" + value + "/"
  }
}
