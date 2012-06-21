require 'rubygems'
require 'net/http'
require 'json'
require 'open-uri'
require 'base64'
require 'yaml'

class Jira

  attr_accessor :user, :password, :data
  CONFIG = YAML.load_file("jira.yml")

  def initialize(options={})
    @host = CONFIG['host']
    @port = CONFIG['port']
    @base_path = CONFIG['base_path']
    @user = options[:user] || CONFIG['user']
    @password = options[:password] || CONFIG['password']
    @fields = options[:fields] || CONFIG['default_fields'] || '*all'
    
    @data = nil # cached results from last query
  end

  # @todo test method
  def get_issues issue_keys
    path = @base_path + "issue/"
    arr = []

    for issue in issue_keys
      req = Net::HTTP::Get.new(path + issue)
      req.content_type = "application/json"
      req.basic_auth @user, @password
      http = Net::HTTP.new(@host, @port)
      # http.use_ssl = true
      response = http.start do |http|
        http.request(req)
      end

      if response.code =~ /20[0-9]{1}/
        data = JSON.parse(response.body)
        puts "Retrieved issue #{data['key']}"
        puts JSON.pretty_generate(data)
        arr << data
      else
        raise StandardError, "Unsuccessful response code " + response.code + " when retrieving issue " + issue
      end    
    end
    arr
  end
  
  # @todo test method  
  def get_users
    path = @base_path + "user/search"

    req = Net::HTTP::Get.new(path)
    req.content_type = "application/json"
    req.basic_auth @user, @password
    http = Net::HTTP.new(@host, @port)
    # http.use_ssl = true
    response = http.start do |http|
      http.request(req)
    end

    if response.code =~ /20[0-9]{1}/
      data = JSON.parse(response.body)
      puts "Retrieved issue #{data['key']}"
      puts JSON.pretty_generate(data)
      arr << data
    else
      raise StandardError, "Unsuccessful response code " + response.code + " when retrieving users"
    end    
  end

  # Post records
  # @todo test method  
  def post (data)
    path = @base_path + "issue/"

    puts "Sending: "
    puts data

    req = Net::HTTP::Post.new(path)
    req.content_type = "application/json"
    req.basic_auth @user, @password
    http = Net::HTTP.new(@host, @port)
    # http.use_ssl = true
    response = http.start do |http|
      req.body = data
      http.request(req)
    end

    data = JSON.parse(response.body)
    if response.code =~ /20[0-9]{1}/
      puts "Created issue"
      puts JSON.pretty_generate(response.body)
    else
      raise StandardError, "Unsuccessful response code " + response.code + " sending data " + JSON.pretty_generate(data)
    end    
  end
  
  # JQL Search
  # Resource: /rest/api/2/search?jql&startAt&maxResults&fields&expand
  # @example jira.search("resolved > startOfDay()")
  def search(jql, options={})
    max_results = options[:max_results] || 5

    url = url("search?jql=#{URI::encode(jql)}&fields=#{@fields.join(',')}&maxResults=#{max_results}")

    response = open(url,
        "Content-Type" => "application/json",
        "Authorization" => Base64.encode64("#{@user}:#{@password}")) { |f|
      JSON.parse(f.read)
    }

    @data = response
  end
  
  # @param search result JSON
  # @return sum of time spent on all issues
  def total_time_spent(data=nil)
    data ||= @data
    timeSpentSeconds = 0
    data['issues'].each do |issue|
      timeSpentSeconds += Float(issue.get_value ['fields', 'timetracking', 'timeSpentSeconds'] || 0)
    end

    timeSpentSeconds
  end
  
  # @return sum of story points on all issues
  def total_story_points(data=nil)
    data ||= @data
    storyPoints = 0
    data['issues'].each do |issue|
      storyPoints += Float(issue.get_value(['fields', 'customfield_10002']) || 0)
    end

    storyPoints
  end
  
  private

  def url(path)
    "http://#{@host}#{@base_path}#{path}"
  end
    
end

class Hash
    # Safely retrieves value for a deeply nested key.
    # @note Doesn't handle arrays
    # @param Array of keys
    # @return value found by following the nested keys. nil when a key is not found
    def get_value keys
    value = nil
    key = (keys.respond_to? :shift) ? keys.shift : nil

    if key.nil? || keys.nil? # no keys specified, so return nothing
      value = nil 
    elsif keys.empty? # no more keys, so return this value
      value = self[key] if self.has_key? key
    elsif self.has_key? key # more keys, so drill down
      value = self[key].get_value(keys)
    end

    return value
  end
end