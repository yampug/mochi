enum RubyEndableStatement
    CLASS
    MODULE
    DEF
    IF
    UNLESS
    CASE
    WHILE
    UNTIL
    FOR
    BEGIN
  
    def id : String
      case self
        when CLASS  then "class"
        when MODULE then "module"
        when DEF    then "def"
        when IF     then "if"
        when UNLESS then "unless"
        when CASE   then "case"
        when WHILE  then "while"
        when UNTIL  then "until"
        when FOR    then "for"
        when BEGIN  then "begin"
        else ""
      end
    end
  
    def self.get_endable(input : String) : RubyEndableStatement?
      self.values.each do |statement_type|
        if current_id = statement_type.id
          if input.starts_with?(current_id)
            return statement_type
          end
        end
      end
      nil
    end
  end
  