class UserController < ApplicationController
  def index
    @users = User.where("retired = ?", false)
  end

  def new
    @user = User.new
    @targeturl = "/user"
    render :layout => "touch"
  end

  def create

    existing_user = User.where(username: params[:user][:username]) rescue nil

    if !existing_user.blank?
      flash[:notice] = 'Username already in use'
      redirect_to "/user/new" and return
    end
    if (params[:password] != params[:confirm_password])
      flash[:notice] = 'Password Mismatch'
      redirect_to :action => 'new' and return
    end

    person = Person.create()
    person.names.create(given_name: params[:user][:given_name], family_name: params[:user][:family_name])

    @user = User.create(username: params[:user][:username], password: params[:password],
                        creator: params[:creator], person_id: person.id)

    @user.user_roles.create(role: Role.find_by_role( params[:user_role][:role_id]).role)

    if @user.errors.blank?
      flash[:notice] = 'User was successfully created.'
    else
      flash[:notice] = 'Oops! User was not created!.'
      redirect_to "/user/new" and return
    end
    redirect_to "/user"

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

  def roles
    role_conditions = ["role LIKE (?)", "%#{params[:value]}%"]
    roles = Role.where( role_conditions)
    roles = roles.map do |r|
      "<li value='#{r.role}'>#{r.role.gsub('_',' ').capitalize}</li>"
    end
    render :text => roles.join('') and return
  end

  private

  def user_params
    params.require(:user).permit(:username,:first_name, :middle_name, :role, :fathers_name, :mothers_name,:password)
  end
end
