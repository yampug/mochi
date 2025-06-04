package dev.mochirb.parsing

import dev.mochirb.utils.RubyDef

data class RubyComponent(
    val moduleName: String,
    val localVars: Map<String, String>,
    val definitions: List<RubyDef>,
    val filePath: String){
}
