package dev.mochirb.extractors

import org.jsoup.Jsoup

class BindExtractor {

    fun extract(html: String): BindResult {
        val doc = Jsoup.parse(html)

        val bindings = mutableMapOf<String, String>()
        for (element in doc.allElements) {
            for (attribute in element.attributes().asList()) {
                if (attribute.key.startsWith("bind:")) {
                    println("removing ${attribute.key}")
                    element.removeAttr(attribute.key)
                    element.attributes().remove(attribute.key)
                    element.attributes().add(attribute.key.substring(5), attribute.value)
                    bindings.put(attribute.value.substring(1, attribute.value.length - 1), attribute.key.substring(5))
                }
            }
        }
        val cleanedHtml = doc.outerHtml()
        val bodyOpenIndex = cleanedHtml.indexOf("<body>")
        val bodyEnd = cleanedHtml.indexOf("</body>")
        val cleanedHtmlNoSkeleton = cleanedHtml.substring(bodyOpenIndex + 6, bodyEnd).trim()

        return BindResult(html = cleanedHtmlNoSkeleton, bindings = bindings)
    }

    companion object {
        data class BindResult(
            val html: String,
            val bindings: Map<String, String>
        )
    }
}

fun main() {
    val html = "      <div class=\"wrapper\">\n" +
            "        <h1>Count123: {count}</h1>\n" +
            "        <h2>Modifications: {modifications}</h2>\n" +
            "        <button on:click={increment}>Increment</button>\n" +
            "        <button on:click={decrement}>Decrement</button>\n" +
            "        <plus-five bind:pfcount=\"{count}\"></plus-five>\n" +
            "      </div>"
    println(BindExtractor().extract(html))
}
