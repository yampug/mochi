class SpecDataLoader
  def self.load(rel_path : String) : String
    return File.read("./spec_data/#{rel_path}")
  end
end
