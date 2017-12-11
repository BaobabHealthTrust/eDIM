class UserController < ApplicationController
  def index
    @users = User.where("retired = ?", false)
  end

  def new
    @user = User.new
    @targeturl = "/users"
    render :layout => "touch"
  end

  def create

    @user = User.new({:username => params[:user][:username], :password => params[:user][:password],:role =>params[:user][:user_role],
                      :first_name => params[:user][:first_name], :middle_name => params[:user][:middle_name],
                      :fathers_name => params[:user][:fathers_name], :mothers_name => params[:user][:mothers_name]})

    if @user.save
      redirect_to "/user" and return
    else
      render 'new', :layout => "touch"
    end

  end

  def show
    @user = User.find(params[:id])
    @targeturl = "/users"
    render :layout => "menu"
  end

  def edit

    if request.post?

      user = User.find(params[:user_id])
      case params[:section]
        when "language_preference"
          user.language = params[:user][:language_preference]
          if user.save
            flash[:success] = "User language preference successfully updated"
          else
            flash[:errors] = "Failed to update user language preference"
          end
        when "password"
          user.update_attributes(:password => params[:user][:plain_password], :salt => nil)

          if user.save
            flash[:success] = "User password successfully updated"
          else
            flash[:errors] = t("messages.invalid_credentials")
          end
        when "role"
          user.update_attributes(:role => params[:user][:user_role])
          if user.save
            flash[:success] = "User role was successfully updated"
          else
            flash[:errors] = "Failed to update user role"
          end
      end
      redirect_to "/main/settings" and return
    else
      @user = User.find(params[:id])
      @edit_section = params[:section]
      render :layout =>  "touch"
    end

  end

  def destroy
    user = User.find(params[:id])
    user.update_attributes(retired: true)
    redirect_to "/user" and return
  end


  def logout

  end

  def username_availability
    user = User.find_by_username(params[:search_str])
    render :text => user.blank? ? '' : 'N/A' and return
  end

  def query
    results = []

    users = User.page((params[:page].to_i rescue 1)).per((params[:size].to_i rescue 20)).each

    users.each do |user|

      record = {
          "username" => "#{user.username}",
          "name" => "#{user.fullname}",
          "roles" => "#{user.role}",
          "active" => (user.active rescue false),
          "id" => user.id
      }

      results << record

    end

    render :text => results.to_json

  end

  def users_names
    coordinators = User.where("retired = ? AND role in (?)", false, ["administrator","Pharmacist"]) rescue []
    names = coordinators.map do |v|
      "<li value='#{v.user_id}'>#{v.fullname.html_safe}</li>"
    end
    render :text => names.join('') and return
  end

  private

  def user_params
    params.require(:user).permit(:username,:first_name, :middle_name, :role, :fathers_name, :mothers_name,:password)
  end
end
