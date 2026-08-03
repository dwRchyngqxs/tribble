package de.cispa.se.tribble

import scala.util.Random

package object generation {
  private[tribble] case class Slot(decl: DerivationRule, pos: Int, parent: DNode)
  private[tribble] object Slot extends ((DerivationRule, Int, DNode) => Slot)

  def minimalElementsBy[A, B](list: Seq[A], f: A => B)(implicit cmp: Ordering[B]): Seq[A] = {
    if (list.isEmpty)
      throw new UnsupportedOperationException("empty.minimalElementsBy")
    val minElement = list.minBy(f)
    val minValue = f(minElement)
    list filter { x => cmp.equiv(f(x), minValue) }
  }
}
