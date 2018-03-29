if ARGV.length < 2 then
  puts "usage: ruby web-interface.rb pool-address pool-port"
  exit
end

require_relative 'erws/erws'

$navBarElements = { 'Overview' => '/', 'Pattern Lookup' => '/lookup' }

def getPoolStatus
  return [500, 2]
end

class PathInterfacePage < ERWS::PathBase
  def initialize server
    super server
    @title = ""
  end
  
  def run args
    status = getPoolStatus
  
    page = "<html><head><title>NDGMP Web Interface - #{@title}</title>" 
    page += '<link rel="stylesheet" type="text/css" href="/style.css" /></head>'
    page += '<body background="/bg.png"><div id="body"><div id="top"><div id="topLogo"></div><div id="topStatus"><p>'
    page += "#{status[0]} GC/s</p><p>#{status[1]} miners</p></div></div>"
    page += '<div id="navBar"><div id="navBarElements">'
    $navBarElements.each do |title, path|
      if @title == title then page += '<b>' end
      page += '<a href="'
      page += path
      page += '">'
      page += @title
      page += '</a>'
      if @title == title then page += '</b>' end      
      page += ' | '
    end
    if $navBarElements.length > 0 then page[-3 .. -1] = '' end # clear off the pipe
    page += '</div><div id="contents"><h1>'
    page += @title
    page += '</h1>'
    page += actual_data
    page += '</div><div id="filler"></div></div></body></html>'
  end
  
  def actual_data
    return ''
  end
end

class PathOverviewPage < PathInterfacePage
  def initialize server
    super server
    @title = 'Overview'
  end
end

server = ERWS::Server.new
server.add_physical_path 'logo.png'
server.add_physical_path 'bg.png'
server.add_physical_path 'style.css'

overview = PathOverviewPage.new server

server.add_path '/', overview

server.run
