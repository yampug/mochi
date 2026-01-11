require "./runtime"

module QuickJS
  class Sandbox < Runtime
    def initialize
      super
      # Restrict dangerous globals
      # Note: QuickJS by default is quite sandboxed (no file/net access unless explicitly added)
      # But standard objects like Date, Math are present.
      # If we wanted to remove *everything* we could, but usually "sandbox" means correct isolation.
      # The main thing is proper resource limits which are handled by runtime controls.
      
      # We can delete specific functionality if we want.
      # For now, a Sandbox is primarily a semantic distinction that allows for stricter defaults if needed.
    end
  end
end
