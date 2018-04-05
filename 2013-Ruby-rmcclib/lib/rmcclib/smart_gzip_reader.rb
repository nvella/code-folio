module RMCCLib
  class SmartGzipReader < Zlib::GzipReader
    include JavaStreamIO
  end
end