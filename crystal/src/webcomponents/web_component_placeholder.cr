enum WebComponentPlaceholder
  OnClick
  OnChange

  def string_value : String
    case self
      in .on_click? then "__on_click_placeholder__"
      in .on_change? then "__on_change_placeholder__"
    end
  end
end
