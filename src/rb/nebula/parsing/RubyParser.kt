package rb.nebula.parsing

import org.jruby.embed.LocalContextScope
import org.jruby.embed.ScriptingContainer
import rb.nebula.utils.RubyDef


class RubyParser {

    companion object {
        fun parse(rubyFile: String): RubyComponent? {
            return TODO("")
        }

        fun extractModuleName(rubyFile: String): String {
            // TODO implement more robust extraction similar to getDefName
            var result = ""
            rubyFile.split("\n").forEach { it ->
                if (it.contains("class ")) {
                    val split = it.trim().split(" ")
                    result = split[1]
                }
            }
            return result
        }

        fun getDefName(line: String): String? {
            val defIndex = line.indexOf("def")

            val nameStartPos = defIndex + 4
            if (defIndex >= 0 && line.length > nameStartPos) {
                val indexOfParen = line.indexOf("(")
                if (indexOfParen >= 0) {
                    return line.substring(nameStartPos, indexOfParen)
                } else {
                    return line.substring(nameStartPos)
                }
            }
            return null
        }

        fun extractMethodBody(rubyFile: String, className: String): List<RubyDef> {
            val result = mutableListOf<RubyDef>()
            var inMethod = false
            var defName: String? = null
            var parameters: List<String> = mutableListOf()
            var linesSinceDef = mutableListOf<String>()
            var endStatCounter = 0
            var endIndexAtDef = -1

            rubyFile.split("\n").forEach {
                val trim = it.trim()

                val endable = RubyEndableStatement.getEndable(trim)
                if (endable == RubyEndableStatement.DEF) {
                    inMethod = true
                    defName = getDefName(trim)
                    parameters = getParameters(trim)
                    endIndexAtDef = endStatCounter
                } else if (endable != null) {
                    endStatCounter += 1
                }

                // println("Line:'$trim', endable:$endable, endIgnoreCounter:$endStatCounter, endIndexAtDef: $endIndexAtDef, inMethod:$inMethod, defName: $defName")
                if (inMethod) {
                    linesSinceDef.add(it)
                }
                if (trim.startsWith("end")) {
                    if (endStatCounter != endIndexAtDef) {
                        // endable statement within method closed
                        endStatCounter -= 1
                        // println("end ignored")
                    } else {
                        // method finished
                        // println("method '$defName' finished")

                        val tmp = RubyDef(
                            defName,
                            "/todo",
                            className,
                            linesSinceDef,
                            parameters
                        )
                        result.add(tmp)

                        defName = null
                        endIndexAtDef = -1
                        linesSinceDef = mutableListOf()
                        inMethod = false

                    }
                }
            }
            return result
        }

        private fun getParameters(trim: String): List<String> {
            val parOpen = trim.indexOf("(")
            var parClosed = trim.indexOf(")")
            if (parOpen < parClosed && parClosed > 0) {
                val params = trim.substring(parOpen + 1, parClosed)
                println("params:'${params}'")
                val result = mutableListOf<String>()
                for (param in params.split(",")) {
                    result.add(param.trim())
                }
                return result
            }
            return listOf()
        }

        fun removeEmptyLines(lines: List<String>): List<String> {
            val nonEmptyLines = mutableListOf<String>()
            for (tmp in lines) {
                if (tmp.trim().length > 0) {
                    nonEmptyLines.add(tmp)
                }
            }
            return nonEmptyLines
        }

        fun removeIndentation(lines: List<String>): List<String> {
            if (lines.isEmpty()) return lines

            val nonEmptyLines = removeEmptyLines(lines)
            if (nonEmptyLines.isEmpty()) return lines

            val first = nonEmptyLines.first()

            var indentChar = ' ' // assume space by default
            if (first.startsWith("\t")) {
                // tabs
                indentChar = '\t'
            }

            var prefix = ""
            var i = 0
            for (c in first.iterator()) {
                if (c != indentChar) {
                    prefix = first.substring(0, i)
                    break
                }
                i++
            }
            //println("prefix:'$prefix'")
            return lines.map { line ->
                line.removePrefix(prefix)
            }
        }
    }
}

fun main() {
//    val rubyFile = FileUtils.readFileToString(File("ruby/lib/Counter.rb"), Charset.defaultCharset())
//
//    val manager = ScriptEngineManager()
//    val engine = manager.getEngineByName("jruby")

    try {
//        engine.eval("$rubyFile\n\ncounter=Class.new { include Counter }.new\ncounter")
        val ruby = ScriptingContainer(LocalContextScope.SINGLETHREAD)

        val moduleDefinition = "module Counter; count = 0; end"
        ruby.runScriptlet(moduleDefinition)

        val getInstanceScript = "Class.new { include Counter }.new"
        val counterInstance = ruby.runScriptlet(getInstanceScript)

        println("counterInstance:$counterInstance")
//        val counterBinding = ruby.callMethod(counterInstance, "instance_eval", "binding")
//
//        println(counterBinding)
//        val getLocalVarsScript = "local_variables - instance_variables.map(&:to_sym)"
//        val localVars = ruby.callMethod(counterBinding, "eval", getLocalVarsScript) as List<String>
//        val rubyResult: Any = ruby.callMethod(counterInstance, "class_variables.map { |var| [var, Counter.class_variable_get(var)] }.to_h")
//        const hw = new Opal.HelloWorld();
//        hw.$logic();
        val rubyResult: Any = ruby.runScriptlet("Class.new { include Counter }.class_variables.map { |var| [var, Counter.class_variable_get(var)] }.to_h")
        println(rubyResult)
        val output = StringBuilder()
//        output.appendLine("<script>")
        if (rubyResult is Map<*, *>) {
            for ((key, value) in rubyResult) {
                val variableName = key.toString()
                val variableValue = value!!
                println("Variable: $variableName, Value: $variableValue")
//                output.appendLine("let ${variableName.substring(1)} = $variableValue;")
            }
        }
//        val javaStringList: List<String> = ArrayList(localVars)

//        println(javaStringList)
    } catch (e: Exception) {
        e.printStackTrace()
    }

}
