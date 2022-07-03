#!/usr/bin/env ruby 
require 'watir-webdriver'
require 'uri'
require 'net/https'
require 'nokogiri'

class Watiring
  def self.stdout(text)
    printf "%s \n" %[ text ]
  end

  def self.init(browser, url)
    case browser
      when "firefox"
        @browser = Watir::Browser.new :ff
        eurl = URI.encode(url)
        @browser.goto "#{eurl}"        
    end
  end

  def self.close(timeout = 5)
    sleep timeout
    @browser.close
    printf "bye!\n"
  end

  def self.browse(url, link)
    eurl = URI.encode(url)
    @browser.goto "#{eurl}"
    @browser.windows.last.use
    @browser.link(:text, "#{link}").click(:command, :shift)
    @browser.goto "#{eurl}"
    Watiring.stdout("#{eurl}")
  end

  def self.input(name, value)
    @browser.text_field(name: "#{name}").set("#{value}")     
  end

  def self.click(button)
    @browser.button(:value => "#{button}").click
  end

  def self.googleimages(browser,query, url = "https://www.google.co.za/search?q=#{query}&source=lnms&tbm=isch&sa=X")
    Watiring.browse(url, "All")
  end

  def self.tumblr(browser,query, url = "https://www.tumblr.com/search/#{query}")
    Watiring.browse(url, "Trending")
  end

  def self.facebook(browser,query,url = "https://www.facebook.com/search/all/?q=#{query}")
    Watiring.browse(url, "People")
  end

  def self.get(url,timeout = 60)
    uri                     = URI.parse(url)
    http                    = Net::HTTP.new(uri.host, uri.port,)
    http.use_ssl            = (uri.scheme == "https")
    http.verify_mode        = OpenSSL::SSL::VERIFY_NONE  
    http.read_timeout       = timeout           
    request                 = Net::HTTP::Get.new(uri.request_uri)        
    #request.basic_auth(username,pass)

    begin
      response                = http.request(request)
      if response.code == "200"
        result = 1
        rcode  = response.code + " passed"
      elsif response.code == "302"
        result = 1
        rcode  = response.code + " passed"
      else
        result = 0
        rcode  = response.code + " failed"
      end
      rescue Timeout::Error
        result = 0
        rcode  = "Timeout::Error"
      rescue Errno::ETIMEDOUT
        result = 0
        rcode  = "Errno::ETIMEDOUT"
      rescue Errno::EHOSTUNREACH
        result = 0
        rcode  = "Errno::EHOSTUNREACH"
      rescue Errno::ECONNREFUSED
        result = 0
        rcode  = "Errno::ECONNREFUSED"
      rescue SocketError => e
        result = 0
        rcode  = "SocketError"
    end

    return response.body
  end  
end

## MAIN

@nodes = [ 
  { user: 'root', ip: '192.168.2.100', stop: 'killall -9 java &>/dev/null &', start: '/opt/jboss1/jboss-eap-6.2/bin/master.sh start &>/dev/null &'}, # DOMAIN CONTROLLER
  { user: 'root', ip: '192.168.2.101', stop: 'killall -9 java &>/dev/null &', start: '/opt/jboss1/jboss-eap-6.2/bin/slave.sh start &>/dev/null &'},  # SLAVE
  { user: 'root', ip: '192.168.2.102', stop: 'killall -9 java &>/dev/null &', start: '/opt/jboss1/jboss-eap-6.2/bin/slave.sh start &>/dev/null &'},  # SLAVE
]

@browser             = "firefox"
@jboss_vip_cluster   = "http://jboss-cluster.systemerror.co.za/clusterjsp/HaJsp.jsp"
@button              = "RELOAD PAGE"
@repeat              = 12
@wait                = 30

printf "[waitr] creating a session...#{@jboss_vip_cluster}...\n"

Watiring.init(@browser,@jboss_vip_cluster)
# add sample session data
  Watiring.input("dataName","username")
  Watiring.input("dataValue","jaym")
  @active_nodeip      = (Nokogiri::HTML((Watiring.get(@jboss_vip_cluster,@wait)))).css('li')[3].text.split(/\:/)[1].to_s.strip
# loop refresh to @wait  
  for index in 1..@repeat   
    
    printf "[waitr] active node is: %s and will be terminated....\n" % [@active_nodeip]  

    @kill_node          = @nodes.select {|node| node[:ip] == @active_nodeip }[0]
    @kill_node_user     = @kill_node[:user]
    @kill_node_stopcmd  = @kill_node[:stop]
    @kill_node_startcmd = @kill_node[:start]
    @kill_node_stop     = "ssh -f #{@kill_node_user}@#{@active_nodeip} '#{@kill_node_stopcmd}'"
    @kill_node_start    = "ssh -f #{@kill_node_user}@#{@active_nodeip} '#{@kill_node_startcmd}'"

    printf "[waitr] refreshing page...#{index}/#{@repeat} times...every #{@wait} seconds..."
    printf "\n[waitr] ungracefully stopping %s with %s and starting with %s\n" % [@active_nodeip, @kill_node_stopcmd, @kill_node_startcmd ]
    stop = IO.popen(@kill_node_stop).read
    printf "[waitr] reloading page...\n"
    Watiring.click("RELOAD PAGE")
    printf "[waitr] starting %s before next run and wait %s seconds...\n" % [@active_nodeip, @wait]
    @active_nodeip      = (Nokogiri::HTML((Watiring.get(@jboss_vip_cluster,@wait)))).css('li')[3].text.split(/\:/)[1].to_s.strip
    printf "[waitr] cluster session has failed over to %s\n" % [@active_nodeip]
    start = IO.popen(@kill_node_start).read
    sleep @wait

  end
Watiring.close(10)
