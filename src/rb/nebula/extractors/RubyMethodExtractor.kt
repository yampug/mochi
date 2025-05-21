package rb.nebula.extractors

object RubyMethodExtractor {

    fun extractReactables(rubyCode: String): String? {
        return extractMethodContent("reactables", rubyCode, false)
    }

    fun extractCssContent(rubyCode: String): String? {
        return extractMethodContent("css", rubyCode, false)
    }

    fun extractHtmlContent(rubyCode: String): String? {
        return extractMethodContent("html", rubyCode, true)
    }

    fun extractMethodContent(methodName: String, rubyCode: String, removeNL: Boolean): String? {
        val defHtmlIndex = rubyCode.indexOf("def $methodName")
        val endAfterDefHtml = rubyCode.substring(rubyCode.indexOf("def $methodName") + 3).indexOf("end")

        val htmlMethod = rubyCode.substring(defHtmlIndex, defHtmlIndex + 3 + endAfterDefHtml)
        val firstNL = htmlMethod.indexOf("\n")
        var htmlMethodBody = htmlMethod.substring(firstNL)
            .trim()
            // remove tabs
            .replace("\t", "")
            // remove double spaces
            .replace("  ", " ")
        if (removeNL) {
            htmlMethodBody = htmlMethodBody.replace("\n", "")
        }

        if (htmlMethodBody.startsWith("%Q{") && htmlMethodBody.endsWith("}")) {
            return htmlMethodBody.substring(3, htmlMethodBody.length - 1).trim()
        } else if (htmlMethodBody.startsWith("%q{") && htmlMethodBody.endsWith("}")) {
            return htmlMethodBody.substring(3, htmlMethodBody.length - 1).trim()
        } else if (htmlMethodBody.startsWith("\"") && htmlMethodBody.endsWith("\"")) {
            return htmlMethodBody.substring(1, htmlMethodBody.length - 1).trim()
        } else if (htmlMethodBody.startsWith("'") && htmlMethodBody.endsWith("'")) {
            return htmlMethodBody.substring(1, htmlMethodBody.length - 1).trim()
        }
        return htmlMethodBody
    }
}
