package rb.nebula.parsing

enum class RubyEndableStatement(val id: String) {
    CLASS("class"),
    MODULE("module"),
    DEF("def"),
    IF("if"),
    UNLESS("unless"),
    CASE("case"),
    WHILE("while"),
    UNTIL("until"),
    FOR("for"),
    BEGIN("begin"),
    ;

    companion object {
        fun getEndable(input: String): RubyEndableStatement? {
            for (value in values()) {
                if (input.startsWith(value.id)) {
                    return value
                }
            }
            return null
        }
    }
}