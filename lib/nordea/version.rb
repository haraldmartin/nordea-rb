module Nordea
  module Version
    MAJOR  = 0
    MINOR  = 3
    TINY   = 1

    STRING = [MAJOR, MINOR, TINY].join(".")
  end

  VERSION = Nordea::Version::STRING
end