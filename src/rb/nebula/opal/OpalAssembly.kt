package rb.nebula.opal

import org.apache.commons.io.FileUtils
import rb.nebula.parsing.RubyParser.Companion.extractMethodBody
import rb.nebula.utils.BashUtils
import rb.nebula.utils.RubyDef
import java.io.File

class OpalAssembly {

    fun assemble(moduleName: String, defs: List<RubyDef>, minified: Boolean = true): String {
        val output = generateRubyClass(moduleName, defs)

        val workDir = File("tmp_nb")
        if (!workDir.exists()) {
            workDir.mkdirs()
        }
        val outFile = File(workDir, "$moduleName.rb")
        println("Writing '$moduleName' to $outFile for Opal Assembly")
        FileUtils.writeStringToFile(outFile, output.toString(), Charsets.UTF_8)
        // TODO find a better way to find opal on the system like OPAL_HOME env variable
        BashUtils().bash("/Users/bob/.rvm/gems/opal/bin/opal -cO ${outFile.absolutePath} -o tmp_nb/$moduleName.js --no-source-map")
        var rubyJsCode = FileUtils.readFileToString(File("tmp_nb/$moduleName.js"), Charsets.UTF_8)

        if (minified) {
            BashUtils().bash("uglifyjs -o /Users/bob/repos/nebula/tmp_nb/$moduleName.min.js --compress -- /Users/bob/repos/nebula/tmp_nb/$moduleName.js")
            rubyJsCode = FileUtils.readFileToString(File("tmp_nb/$moduleName.min.js"), Charsets.UTF_8)
        }
        val result = StringBuilder()
        result.append(rubyJsCode)
        result.appendLine("let instance = new Opal.${moduleName}();")
        result.appendLine("instance.\$mounted();")
        return result.toString()
    }

    private fun generateRubyClass(className: String, defs: List<RubyDef>): StringBuilder {
        val output = StringBuilder()

        output.appendLine("class $className")

        output.appendLine("@count = 0")

        for (def in defs) {
            if (def.name == "css" || def.name == "html") {
                continue
            }

            output.appendLine("")
            for (defLine in def.body) {
                output.appendLine(defLine)
            }
            output.appendLine("")
        }
        output.appendLine("end")

        return output
    }
}

fun main(args: Array<String>) {

    val str = FileUtils.readFileToString(File("ruby/lib/HelloWorld.rb"), Charsets.UTF_8)
    val definitions = extractMethodBody(str, "HelloWorld")
    println(definitions)
    val rubyJsCode = OpalAssembly().assemble("HelloWorld", definitions)
    println(rubyJsCode)
}
