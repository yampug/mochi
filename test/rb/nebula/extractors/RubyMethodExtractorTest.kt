package app.acrylic.rb.nebula.extractors

import org.junit.Test
import rb.nebula.extractors.RubyMethodExtractor.extractCssContent
import rb.nebula.extractors.RubyMethodExtractor.extractHtmlContent
import kotlin.test.assertEquals

class RubyMethodExtractorTest {

    val fullComponentRubyCode = """
            class Counter

              @cmp_name = "my-counter"
              @count
              @modifications

              def initialize
                @count = 0
                @modifications = 0

                puts Text::Soundex.soundex('Knuth')

              end

              def reactables
                ["count", "modifications"]
              end

              def html
                %Q{
                  <div class="wrapper">
                    <h1>Count123: {count}</h1>
                    <h2>Modifications: {modifications}</h2>
                    <button on:click={increment}>Increment</button>
                    <button on:click={decrement}>Decrement</button>
                  </div>
                }
              end

              def css
                %Q{
                  .wrapper {
                    background: red;
                    width: 200px;
                    padding: 10px;
                    margin-bottom: 5px;
                    border-radius: 14px;
                  }
                }
              end

              def increment
                @count = @count + 1
                @modifications = @modifications + 1
              end

              def decrement
                @count = @count - 1
                @modifications = @modifications + 1
              end

              def mounted
                puts "Counter mounted"
              end

              def unmounted
                puts "Counter unmounted"
              end
            end
        """.trimIndent()

    @Test
    fun testNonInterpolated() {
        val rubyCode = """
            class NonInterpolated
              def html
                %q{
                  <div>
                    This is some non-interpolated content.
                    No #{ruby_code} here.
                  </div>
                }
              end
            end
        """.trimIndent()


        val htmlContent = extractHtmlContent(rubyCode)
        val expectedHtml = "<div>    This is some non-interpolated content.    No #{ruby_code} here.   </div>"
        assertEquals(expectedHtml, htmlContent)
    }

    @Test
    fun testDoubleQuote() {
        val rubyCode = """
            class AnotherComponent
              def html
                "<p>This is HTML from a double-quoted string.</p>"
              end
            end
        """.trimIndent()

        val htmlContent = extractHtmlContent(rubyCode)
        val expectedHtml = "<p>This is HTML from a double-quoted string.</p>"
        assertEquals(expectedHtml, htmlContent)
    }

    @Test
    fun testSingleQuote() {
        val rubyCode = """
            class YetAnotherComponent
              def html
                '<p>This is HTML from a single-quoted string.</p>'
              end
            end
        """.trimIndent()


        val htmlContent = extractHtmlContent(rubyCode)
        val expectedHtml = "<p>This is HTML from a single-quoted string.</p>"
        assertEquals(expectedHtml, htmlContent)
    }

    @Test
    fun testComponent() {
        val htmlContent = extractHtmlContent(fullComponentRubyCode)
        val expectedHtml = "<div class=\"wrapper\">    <h1>Count123: {count}</h1>    <h2>Modifications: {modifications}</h2>    <button on:click={increment}>Increment</button>    <button on:click={decrement}>Decrement</button>   </div>"
        assertEquals(expectedHtml, htmlContent)
    }

    @Test
    fun testComponentCss() {
        val cssContent = extractCssContent(fullComponentRubyCode)
        val expectedCss = ".wrapper {\n" +
                "    background: red;\n" +
                "    width: 200px;\n" +
                "    padding: 10px;\n" +
                "    margin-bottom: 5px;\n" +
                "    border-radius: 14px;\n" +
                "   }"
        assertEquals(expectedCss, cssContent)
    }
}
