package de.cispa.se.tribble
package input

import java.io.File
import java.nio.file.Files
import org.scalatest.BeforeAndAfter

class GrammarCacheSpec extends TestSpecification with SharedModelAssembler with BeforeAndAfter {
  val cacheDir = new File("../build/tmp/test-data/grammar-cache-test")

  before {
    cacheDir.mkdir()
  }

  after {
    cacheDir.listFiles().foreach(f => Files.delete(f.toPath))
    Files.delete(cacheDir.toPath)
  }

  "The GrammarCache" should "be able to pickle and unpickle grammars" in {
    val cache = new ObjectStreamGrammarCache(cacheDir)

    val grammars = Table("path",
      "URL",
      "Clojure",
      "CSS3",
      "CSV",
      "Iso8601",
      "Json",
      "Kotlin",
      "Regex",
    )

    val loader = new GrammarLoader(ParseGrammar, EmptyGrammarCache)

    forAll(grammars) { name =>
      val grammar: Map[NonTerminal, DerivationRule] = loader.loadGrammar(new File(s"tribble-core/src/test/resources/typesafe/$name.scala"))

      cache.storeGrammar(grammar, name)
      val loaded: Option[Map[NonTerminal, DerivationRule]] = cache.loadGrammar(name)

      loaded match {
        case Some(loadedGrammar) =>
          loadedGrammar shouldEqual grammar
        case None =>
          fail(s"Could not load grammar $name")
      }
    }
  }

}
