gem 'activesupport', ">= 2.3.2"
require 'active_support'

module ActiveSupport::Inflector
  def transliterate(string)
    string.dup
  end
end

module ViewHelpers
  def application_name
    "Announce It"
  end
  
  def application_domain
    "announceitapp.com"
  end
  
  # Calculate the appropriate years for copyright
  def copyright_years
    start_year = 2009
    end_year = Date.today.year
    if start_year == end_year
      "#{start_year}"
    else
      "#{start_year}&#8211;#{end_year}"
    end
  end
  
  def errors_on?(symbol)
    @errors || false
  end
  
  # Returns a Gravatar URL associated with the email parameter.
  # See: http://douglasfshearer.com/blog/gravatar-for-ruby-and-ruby-on-rails
  def gravatar_url(email, options={})
    # Default to highest rating. Rating can be one of G, PG, R X.
    options[:rating] ||= "G"
    
    # Default size of the image.
    options[:size] ||= "32px"
    
    # Default image url to be used when no gravatar is found
    # or when an image exceeds the rating parameter.
    options[:default] ||= "http://localhost:4000/images/avatar_32x32.png"
    
    # Build the Gravatar url.
    url = 'http://www.gravatar.com/avatar.php?'
    url << "gravatar_id=#{Digest::MD5.new.update(email)}" 
    url << "&rating=#{options[:rating]}" if options[:rating]
    url << "&size=#{options[:size]}" if options[:size]
    url << "&default=#{options[:default]}" if options[:default]
    url
  end
  
  def name_and_email(name, email)
    email = %{<span class="email">#{mail_to h(email)}</span>}
    if name.blank?
      email
    else
      %{<span class="name">#{h name}</span> (#{email})}
    end
  end
  
  def remote_graph(dom_id, options = {}, html_options = {})
    html_options.merge!({:id => dom_id})
    javascript_tag(swf_object(dom_id, options)).concat(content_tag("div", nil, html_options))
  end
  
  def swf_object(dom_id, options = {})
    default_options = {:width => 300, :height => 150}
    options = default_options.merge(options)
    remote = options[:url] ? ", {'data-file':'#{url_for(options[:url])}'}" : ''
    "swfobject.embedSWF('/open-flash-chart.swf', '#{dom_id}', '#{options[:width]}', '#{options[:height]}', '9.0.0', 'expressInstall.swf'#{remote});"
  end
  
  def subscriber_fixture(name, email = nil, attributes = {})
    email ||= ActiveSupport::Inflector.parameterize(name, '.') + "@gmail.com"
    fixture(attributes.merge(:name => name, :email => email), SubscriberFixtureMethods)
  end
  
  module EscapeHelper
    HTML_ESCAPE = { '&' => '&amp;',  '>' => '&gt;',   '<' => '&lt;', '"' => '&quot;' }
    JSON_ESCAPE = { '&' => '\u0026', '>' => '\u003E', '<' => '\u003C' }
    
    # A utility method for escaping HTML tag characters.
    # This method is also aliased as <tt>h</tt>.
    #
    # In your ERb templates, use this method to escape any unsafe content. For example:
    #   <%=h @person.name %>
    #
    # ==== Example:
    #   puts html_escape("is a > 0 & a < 10?")
    #   # => is a &gt; 0 &amp; a &lt; 10?
    def html_escape(s)
      s.to_s.gsub(/[&"><]/) { |special| HTML_ESCAPE[special] }
    end
    alias h html_escape
    
    # A utility method for escaping HTML entities in JSON strings.
    # This method is also aliased as <tt>j</tt>.
    #
    # In your ERb templates, use this method to escape any HTML entities:
    #   <%=j @person.to_json %>
    #
    # ==== Example:
    #   puts json_escape("is a > 0 & a < 10?")
    #   # => is a \u003E 0 \u0026 a \u003C 10?
    def json_escape(s)
      s.to_s.gsub(/[&"><]/) { |special| JSON_ESCAPE[special] }
    end
    
    alias j json_escape
  end
  include EscapeHelper
  
  module FixtureHelper
    @@fixture_count = 0
    
    class HashStruct
      def metaclass
        class << self; self; end
      end
      
      def initialize(hash={})
        merge(hash, true)
      end
      
      def merge(hash, force=false)
        hash.each do |(k,v)|
          metaclass.send(:define_method, "#{k}") { instance_variable_get("@#{k}") } if force or !respond_to?("#{k}")
          metaclass.send(:define_method, "#{k}=") { |value| instance_variable_set("@#{k}", value) } if force or !respond_to?("#{k}=")
          send("#{k}=", v)
        end
      end
    end
    
    def fixture(hash={}, extensions=Module.new)
      defaults = {:id => (@@fixture_count += 1)}
      f = HashStruct.new(defaults.merge(hash))
      f.extend(extensions)
      f.initialize_fixture if f.respond_to? :initialize_fixture
      f
    end
  end
  include FixtureHelper
  
  module FlashHelper
    def flash
      @flash ||= {}
    end
  end
  include FlashHelper
  
  module ParamsHelper
    def params
      @params ||= begin
        q = request.query.dup
        q.each { |(k,v)| q[k.to_s.intern] = v }
        q
      end
    end
  end
  include ParamsHelper
  
  module TagHelper
    def content_tag(name, content, html_options={})
      %{<#{name}#{html_attributes(html_options)}>#{content}</#{name}>}
    end
    
    def tag(name, html_options={})
      %{<#{name}#{html_attributes(html_options)} />}
    end
    
    def image_tag(src, html_options = {})
      tag(:img, html_options.merge({:src=>src}))
    end
    
    def javascript_tag(content = nil, html_options = {})
      content_tag(:script, javascript_cdata_section(content), html_options.merge(:type => "text/javascript"))
    end
    
    def link_to(name, href, html_options = {})
      html_options = html_options.stringify_keys
      confirm = html_options.delete("confirm")
      onclick = "if (!confirm('#{html_escape(confirm)}')) return false;" if confirm
      content_tag(:a, name, html_options.merge(:href => href, :onclick=>onclick))
    end
    
    def link_to_function(name, *args, &block)
      html_options = {}
      html_options = args.pop if args.last.is_a? Hash
      function = args[0] || ''
      onclick = "#{"#{html_options[:onclick]}; " if html_options[:onclick]}#{function}; return false;"
      href = html_options[:href] || '#'
      content_tag(:a, name, html_options.merge(:href => href, :onclick => onclick))
    end
    
    def mail_to(email_address, name = nil, html_options = {})
      html_options = html_options.stringify_keys
      encode = html_options.delete("encode").to_s
      cc, bcc, subject, body = html_options.delete("cc"), html_options.delete("bcc"), html_options.delete("subject"), html_options.delete("body")
      
      string = ''
      extras = ''
      extras << "cc=#{CGI.escape(cc).gsub("+", "%20")}&" unless cc.nil?
      extras << "bcc=#{CGI.escape(bcc).gsub("+", "%20")}&" unless bcc.nil?
      extras << "body=#{CGI.escape(body).gsub("+", "%20")}&" unless body.nil?
      extras << "subject=#{CGI.escape(subject).gsub("+", "%20")}&" unless subject.nil?
      extras = "?" << extras.gsub!(/&?$/,"") unless extras.empty?
      
      email_address = email_address.to_s
      
      email_address_obfuscated = email_address.dup
      email_address_obfuscated.gsub!(/@/, html_options.delete("replace_at")) if html_options.has_key?("replace_at")
      email_address_obfuscated.gsub!(/\./, html_options.delete("replace_dot")) if html_options.has_key?("replace_dot")
      
      if encode == "javascript"
        "document.write('#{content_tag("a", name || email_address_obfuscated, html_options.merge({ "href" => "mailto:"+email_address+extras }))}');".each_byte do |c|
          string << sprintf("%%%x", c)
        end
        "<script type=\"#{Mime::JS}\">eval(decodeURIComponent('#{string}'))</script>"
      elsif encode == "hex"
        email_address_encoded = ''
        email_address_obfuscated.each_byte do |c|
          email_address_encoded << sprintf("&#%d;", c)
        end
        
        protocol = 'mailto:'
        protocol.each_byte { |c| string << sprintf("&#%d;", c) }
        
        email_address.each_byte do |c|
          char = c.chr
          string << (char =~ /\w/ ? sprintf("%%%x", c) : char)
        end
        content_tag "a", name || email_address_encoded, html_options.merge({ "href" => "#{string}#{extras}" })
      else
        content_tag "a", name || email_address_obfuscated, html_options.merge({ "href" => "mailto:#{email_address}#{extras}" })
      end
    end
    
    private
    
      def cdata_section(content)
        "<![CDATA[#{content}]]>"
      end
      
      def javascript_cdata_section(content) #:nodoc:
        "\n//#{cdata_section("\n#{content}\n//")}\n"
      end
      
      def html_attributes(options)
        unless options.blank?
          attrs = []
          options.each_pair do |key, value|
            if value == true
              attrs << %(#{key}="#{key}") if value
            else
              attrs << %(#{key}="#{value}") unless value.nil?
            end
          end
          " #{attrs.sort * ' '}" unless attrs.empty?
        end
      end
  end
  include TagHelper
  
  module SubscriberFixtureMethods
    def name?
      !!@name
    end
  end
end