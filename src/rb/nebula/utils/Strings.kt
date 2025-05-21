package rb.nebula.utils

class Strings {
    companion object {
        fun camelToSnake(str: String): String? {
            var tmp = str
            val regex = "([a-z])([A-Z]+)"
            val replacement = "$1_$2"
            tmp = tmp.replace(regex.toRegex(), replacement).toLowerCase()
            return tmp
        }
    }
}