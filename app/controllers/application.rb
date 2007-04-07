# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

  def authorize_web
    @user = User.find_by_token(session[:token])
  end

  def require_user
    redirect_to :controller => 'user', :action => 'login' unless @user
  end

  def authorize(realm='Web Password', errormessage="Could't authenticate you") 
    username, passwd = get_auth_data # parse from headers
    # authenticate per-scheme
    if username.nil?
      @user = nil # no authentication provided - perhaps first connect (client should retry after 401)
    elsif username == 'token' 
      @user = User.authenticate_token(passwd) # preferred - random token for user from db, passed in basic auth
    else
      @user = User.authenticate(username, passwd) # basic auth
    end
    
    # handle authenticate pass/fail
    if @user
      # user exists and password is correct ... horray! 
      if @user.methods.include? 'lastlogin'         # note last login 
        @session['lastlogin'] = user.lastlogin 
        @user.last.login = Time.now 
        @user.save() 
        @session["User.id"] = @user.id 
      end             
    else 
      # no auth, the user does not exist or the password was wrong
      response.headers["Status"] = "Unauthorized" 
      response.headers["WWW-Authenticate"] = "Basic realm=\"#{realm}\"" 
      render_text(errormessage, 401) # :unauthorized
    end 
  end 

  def get_xml_doc
    doc = XML::Document.new
    doc.encoding = 'UTF-8' 
    root = XML::Node.new 'osm'
    root['version'] = API_VERSION
    root['generator'] = 'OpenStreetMap server'
    doc.root = root
    return doc
  end

  # extract authorisation credentials from headers, returns user = nil if none
  private 
  def get_auth_data 
    if request.env.has_key? 'X-HTTP_AUTHORIZATION'          # where mod_rewrite might have put it 
      authdata = request.env['X-HTTP_AUTHORIZATION'].to_s.split 
    elsif request.env.has_key? 'HTTP_AUTHORIZATION'         # regular location
      authdata = request.env['HTTP_AUTHORIZATION'].to_s.split
    end 
    # only basic authentication supported
    if authdata and authdata[0] == 'Basic' 
      user, pass = Base64.decode64(authdata[1]).split(':')[0..1] 
    end 
    return [user, pass] 
  end 

end
