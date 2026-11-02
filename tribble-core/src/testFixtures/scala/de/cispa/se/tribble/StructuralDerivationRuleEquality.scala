package de.cispa.se.tribble

import org.scalactic.Equality

/**
  * This mixin provides an equality for DerivationRules
  * which ignores the ids of concatenations, alternations, and quantifications.
  */
trait StructuralDerivationRuleEquality {

  implicit protected object structuralEq extends Equality[DerivationRule] {
    def equalOnOption(a: Option[DerivationRule], b: Option[DerivationRule]) = (a, b) match {
      case (None, None) => true
      case (Some(aa), Some(bb)) => areEqual(aa, bb)
      case _ => false
    }

    override def areEqual(a: DerivationRule, b: Any): Boolean = a match {
      case Concatenation(elements, _) => b match {
        case Concatenation(other, _) =>
          elements.size == other.size && elements.zip(other).forall(tuple => areEqual(tuple._1, tuple._2))
        case _ => false
      }

      case a: Alternation => b match {
        case b: Alternation =>
          a.alternatives.size == b.alternatives.size && a.alternatives.zip(b.alternatives).forall(tuple => areEqual(tuple._1, tuple._2))
        case _ => false
      }

      case Quantification(subject, min, max, _) => b match {
        case Quantification(other, `min`, `max`, _) => areEqual(subject, other)
        case _ => false
      }

      case LocalIgnore(subject, lsep, ignore, rsep, _) => b match {
        case LocalIgnore(subjother, lother, ignoreother, rother, _) =>
          areEqual(subject, subjother) && equalOnOption(lsep, lother) && equalOnOption(ignore, ignoreother) && equalOnOption(rsep, rother)
        case _ => false
      }

      case _ => a == b
    }
  }

}
