class BrowserIdentifier

  def self.is_chrome_based(vendor)
    return vendor === "Google Inc."
  end

  def self.is_safari(vendor)
    return vendor === "Apple Computer, Inc."
  end

  def self.is_orion(user_agent_data)
    if `#{user_agent_data}`
      return `#{user_agent_data}.brands[0].brand === "Orion"`
    end
    return false
  end

  def self.is_firefox(user_agent)
    return user_agent.include?("Firefox")
  end

  def self.identify
    user_agent = `window.clientInformation.userAgent`
    vendor = `window.clientInformation.vendor`
    user_agent_data = `window.clientInformation.userAgentData`

    if is_chrome_based(vendor)
      return "chrome_based"
    end

    if is_orion(user_agent_data)
      return "orion"
    end

    if is_safari(vendor)
      return "safari"
    end

    if is_firefox(user_agent)
      return "firefox"
    end

    return "unknown"
  end
end
