package de.cispa.se.tribble
package input

import java.io.{File => JFile}

import better.files._
import de.cispa.se.tribble.dsl.Grammar
import org.log4s.getLogger

import scala.reflect.runtime.currentMirror
import scala.tools.reflect.ToolBox

sealed trait LoadingStrategy {
  def load(file: JFile): Map[NonTerminal, DerivationRule]
}

/**
  * Parses the grammar as a textual representation. The default choice.
  */
case object ParseGrammar extends LoadingStrategy {
  private val logger = getLogger

  override def load(file: JFile): Map[NonTerminal, DerivationRule] = {
    logger.info(s"Parsing a grammar from $file")
    val scalaFile = file.toScala
    val parser: InputGrammarParser = if (scalaFile.extension.contains(".scala")) ScalaDSLParser else TextDSLParser
    ModelAssembler.makeMap(parser.parseGrammar(scalaFile))
  }
}

/**
  * Compiles the grammar written in scala DSL with the scala compiler.
  * Has a size limitation.
  * Not recommended.
  */
case object CompileGrammar extends LoadingStrategy {
  private val logger = getLogger

  override def load(file: JFile): Map[NonTerminal, DerivationRule] = {
    logger.info(s"Compiling a grammar from $file")
    val toolbox = currentMirror.mkToolBox()
    val code = file.toScala.lines mkString "\n"
    val preambula = "import de.cispa.se.tribble.dsl._;\n"
    val tree = toolbox.parse(preambula + code)
    val grammar = toolbox.eval(tree).asInstanceOf[Grammar]
    ModelAssembler.makeMap(grammar.productions)
  }
}

/**
  * Directly deserializes a binary grammar object into memory.
  */
case object UnmarshalGrammar extends LoadingStrategy {
  private val logger = getLogger

  override def load(file: JFile): Map[NonTerminal, DerivationRule] = {
    logger.info(s"Unmarshalling a grammar from $file")
    GrammarSerializer.deserializeGrammar(file)
  }
}
