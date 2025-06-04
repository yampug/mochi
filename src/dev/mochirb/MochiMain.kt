package dev.mochirb

import com.google.gson.Gson
import org.apache.commons.io.FileUtils
import dev.mochirb.extractors.BindExtractor
import dev.mochirb.extractors.RubyMethodExtractor
import dev.mochirb.parsing.RubyParser
import dev.mochirb.parsing.RubyParser.Companion.extractModuleName
import dev.mochirb.parsing.RubyVariable
import dev.mochirb.utils.BashUtils
import dev.mochirb.webcomponents.WebComp
import dev.mochirb.webcomponents.WebCompGenerator
import java.io.File
import java.nio.charset.Charset
import java.nio.file.Files
import java.nio.file.Paths
import java.time.Instant
import java.util.*
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import javax.script.ScriptEngine
import javax.script.ScriptEngineManager
import javax.script.ScriptException
import kotlin.io.path.ExperimentalPathApi
import kotlin.io.path.name

class MochiMain {

    private val version = "Mochi 0.0.1"

    @OptIn(ExperimentalPathApi::class)
    fun transpileDirectory(inputDirectory: String, outputDirectory: String) {
        val rootDirectory = Paths.get(inputDirectory)

        val files = mutableMapOf<String, File>()
        Files.walk(rootDirectory).use { paths ->
            paths
                .filter(Files::isRegularFile)
                .filter { file -> file.name.endsWith(".mo.rb") }
                .forEach { f ->
                    files[f.toFile().path.substring(inputDirectory.length + 1)] = f.toFile()
                }
        }
        println(files)
        val executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors())



        var i = 0
        val components = mutableListOf<MochiComp>()
        for (file in files) {
//            if (i == 0) {
                // pre-heat jruby otherwise all initial files will suffer boot-up time and be slow
            println("File $file")
            val component = transpile(file.value.absolutePath, outputDirectory, file.key, inputDirectory)
            if (component != null) {
                components.add(component)

            }
//            output.appendLine(transpiled)
            println("------------------------------------------------------------------------------------------")
            i++
        }

        // compile ruby to js
        val rubyCode = getAllRubyCode(components)
        val totalJsCode = StringBuilder()
        for (component in components) {
            totalJsCode.appendLine(component.webComponent.jsCode)
        }

        val workDir = File("mo_build")
        if (!workDir.exists()) {
            workDir.mkdirs()
        } else {
            // empty directory
            for (file in workDir.listFiles()) {
                file.deleteRecursively()
            }
        }
        val totalRubyOutFile = File(workDir, "total_ruby.rb")
        FileUtils.writeStringToFile(totalRubyOutFile, rubyCode.toString(), Charsets.UTF_8)

        BashUtils().bash("/Users/bob/.rvm/gems/opal/bin/opal -cO ${totalRubyOutFile.absolutePath} -o mo_build/total_ruby.js --no-source-map")
        var compiledRubyJsCode = FileUtils.readFileToString(File("mo_build/total_ruby.js"), Charsets.UTF_8)

//        println(compiledRubyJsCode)

        val output = StringBuilder()
        output.appendLine(compiledRubyJsCode)
        output.appendLine(totalJsCode)
        val outputFile = File("$outputDirectory/components.js")
//        println("Writing out ${outputFile.absolutePath} (transpilation took ${Duration.between(start, end).toMillis()}ms)")
        FileUtils.writeStringToFile(outputFile, output.toString(), Charsets.UTF_8)

        executor.shutdown()
        executor.awaitTermination(10, TimeUnit.MINUTES)
    }

    private fun getAllRubyCode(components: MutableList<MochiComp>): StringBuilder {
        val rubyCode = StringBuilder()
        for (mochiComp in components) {
            rubyCode.appendLine(mochiComp.rubyCode)
        }
        return rubyCode
    }

    fun StringBuilder.push(indent: Int, text: String) {
        repeat(indent) {
            append("\t")
        }
        appendLine(text)
    }

    data class MochiComp(
        val name: String,
        val rubyCode: String,
        val webComponent: WebComp,
        val html: String,
        val css: String
    )
    fun findSecondLastIndex(text: String, substringToFind: String): Int {
        // Find the index of the last occurrence of the substring
        val lastIndex = text.lastIndexOf(substringToFind)

        // If the substring was not found at all, or found only at the very beginning,
        // it's not possible to find a second last occurrence.
        if (lastIndex <= 0) { // <= 0 because if lastIndex is 0, searching from -1 makes no sense.
            return -1
        }

        // Search for the substring again, but starting the search from
        // the character just before the last found substring.
        // The startIndex in lastIndexOf is inclusive and the search goes backwards.
        return text.lastIndexOf(substringToFind, lastIndex - 1)
    }

    fun transpile(rbFile: String, outputDirectory: String, fileKey: String, inputDirectory: String): MochiComp? {
        val start = Instant.now()
        val rubyFile = FileUtils.readFileToString(File(rbFile), Charset.defaultCharset())

        val rubyFileNoImports = rubyFile.lines().filter { !it.startsWith("require") }.joinToString("\n")
//        val imports = rubyFile.lines()
//            .filter { it.startsWith("require") }
//            .map {
//                val pathIndex = it.indexOf("./")
//                val res = if (pathIndex > 0) {
//                    it.substring(pathIndex + 2)
//                } else {
//                    it.substring(8)
//                }
//                res.replace("\"", "")
//            }
//            .toSet()

        val modName = extractModuleName(rubyFile)
        println("modname:$modName")

        val methods = RubyParser.extractMethodBody(rubyFile, modName)
        println(methods)

        val manager = ScriptEngineManager()
        val engine = manager.getEngineByName("jruby")
        val output = StringBuilder()
        var amplifiedRubyCode = rubyFile

        var webComp: WebComp
        var html = ""
        var css = ""
        var reactables = ""
        try {
            println("Stage: config")
            css = RubyMethodExtractor.extractCssContent(rubyFile)!!// getCss(engine, rubyFileNoImports, modName)
            html = RubyMethodExtractor.extractHtmlContent(rubyFile)!!// getHtml(engine, rubyFileNoImports, modName)
            reactables = RubyMethodExtractor.extractReactables(rubyFile)!!//getReactables(engine, rubyFileNoImports, modName)

            val bindings = BindExtractor().extract(html)
            println("reactabgles:'$reactables'")
            val reactablesList = Gson().fromJson(reactables, Array<String>::class.java)
            println(Arrays.toString(reactablesList))
            for (codeLine in rubyFile.lines()) {
                output.appendLine(codeLine)
            }
            val variables = getVariables(engine, rubyFileNoImports, modName)

            println("variables:$variables")

            // add getters & setters to the ruby class
            for (reactable in reactablesList) {
                val varName = reactable
                val secondLastIndex = findSecondLastIndex(amplifiedRubyCode, "end")
                // add getter
                amplifiedRubyCode = amplifiedRubyCode.substring(
                    0,
                    secondLastIndex + 3
                ) + "\n\n\tdef get_${varName}\n\t\t@${varName}\n\tend\n" + amplifiedRubyCode.substring(
                    secondLastIndex + 3,
                    amplifiedRubyCode.length
                )
                // add setter
                amplifiedRubyCode = amplifiedRubyCode.substring(
                    0,
                    secondLastIndex + 3
                ) + "\n\n\tdef set_${varName}(value)\n\t\t@${varName} = value\n\tend\n" + amplifiedRubyCode.substring(
                    secondLastIndex + 3,
                    amplifiedRubyCode.length
                )
            }

            webComp = WebCompGenerator.generate(
                modName,
                variables.get("@cmp_name")!!.value!!,
                css,
                bindings.html,
                reactables,
                bindings.bindings
            )

            for (line in webComp.jsCode.lines()) {
                output.appendLine(line)
            }
//            println(output.toString())
//            println(amplifiedRubyCode)
            return MochiComp(
                name = modName,
                rubyCode = amplifiedRubyCode,
                webComponent = webComp,
                html = html,
                css = css
            )
        } catch (e: ScriptException) {
            e.printStackTrace()
        }
        return null
    }

    fun getCommentModifers(rubyFile: String?, key: Any?, value: Any?): Boolean {
        for (line in rubyFile!!.lines()) {
            var rbValue = value
//                    println(line)
            if (value == null) {
                rbValue = "nil"
            }
            val varDef = "$key = $rbValue"
//                    println("looking for '$varDef'")
            if (line.contains(varDef)) {
                val hashIndex = line.indexOf("#")
                if (hashIndex > 0) {
                    val comment = line.substring(hashIndex + 1).trim()
                    println("comment:'$comment'")
                    if (comment == "export") {
                        return true
                    }
                }
            }
        }
        return false
    }

    fun getVariables(engine: ScriptEngine, rubyFile: String?, modName: String): Map<String, RubyVariable> {
        val result = mutableMapOf<String, RubyVariable>()
        val rubyResult: Any = engine.eval("$rubyFile\n$modName.instance_variables.map { |var| [var, $modName.instance_variable_get(var)] }.to_h")

        val varNames = mutableSetOf<String>()
        if (rubyResult is Map<*, *>) {
            for ((key, value) in rubyResult) {
                val variableName = key.toString()
                val isExported = getCommentModifers(rubyFile, key, value)
                varNames.add(variableName)
                result[variableName] = RubyVariable(value?.toString() ?: "null", isExported)
            }
        }
        return result
    }

    private fun getReactables(engine: ScriptEngine, rubyFile: String?, modName: String) =
        engine.eval("$rubyFile\n$modName.new.reactables").toString()

    private fun getHtml(engine: ScriptEngine, rubyFile: String?, modName: String) =
        engine.eval("$rubyFile\n$modName.new.html").toString()

    private fun getCss(engine: ScriptEngine, rubyFile: String?, modName: String) =
        engine.eval("$rubyFile\n$modName.new.css").toString()

}

fun main(args: Array<String>) {
    MochiMain().transpileDirectory("./ruby/lib", "devground")
}



