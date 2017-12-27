class SessionsController < ApplicationController

  def new
    session[:user_id] = nil
    User.current = nil
    render :layout => "touch"
  end
  def create
    state = User.authenticate(params['login'],params['password'])

    if state
      user = User.find_by_username(params['login'])
      session[:user_id] = user.id
      User.current = user
      flash[:errors] = nil
      redirect_to '/sessions/add_location' and return
    else
      flash[:errors] = t("messages.invalid_credentials")
      redirect_to "/sessions/new"
    end
  end

  def add_location
    render :layout => 'touch'
  end

  def workstation_location

    location = Location.find(params[:location]) rescue nil
    location ||= Location.find_by_name(params[:location]) rescue nil

    if location.blank?
      flash[:error] = "Invalid workstation location"
      redirect_to '/sessions/add_location' and return
    else
      session[:location] = location.id
      redirect_to root_path
    end

  end

  def destroy
    session[:location] = nil
    session[:user_id] = nil
    User.current = nil
    redirect_to "/sessions/new"
  end
end
