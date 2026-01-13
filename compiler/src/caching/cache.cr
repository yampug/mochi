require "file_utils"
require "dir"
require "./warthogdb"

class Cache

  CACHE_DIR = "#{Path.home}/.cache/mochi"

  @db : WarthogDB

  def initialize
    init_cache_dir
    @db = WarthogDB.open(CACHE_DIR)
  end

  def init_cache_dir
    if Dir.exists?(CACHE_DIR)
    else
      Dir.mkdir(CACHE_DIR)
    end
  end

  def has(key : String) : Bool
    if @db[key]?
      return true
    else
      return false
    end
  end

  def get(key : String) : String
    return @db[key]
  end

  def put(key : String, value : String)
    @db[key] = value
  end

  def close
    @db.close
  end

end
