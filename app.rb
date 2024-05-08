require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/flash'
require './model.rb'

enable:sessions

include Model

MAX_LOGIN_ATTEMPTS = 3
COOLDOWN_PERIOD = 60

#check if user is admin
helpers do
    def admin
        return session[:role] == 1
    end
end

#checks if user is logged in
before('/p/*') do
    p "These are protected_methods"
     if session[:id] ==  nil
      redirect('/')
    end
end

#attemts to log in user
#
# @param [string]:username, username of user
# @param [string]:password, password of user
#
# @see Model#get_user_from_username
# @see Model#check_password
post('/login') do
    username = params[:username]
    password = params[:password]

    failed_login_attempts = session["#{username}_failed_login_attempts"] || 0
    last_failed_login_time = session["#{username}_last_failed_login_time"] || Time.now - COOLDOWN_PERIOD - 1

    if failed_login_attempts >= MAX_LOGIN_ATTEMPTS && Time.now - last_failed_login_time < COOLDOWN_PERIOD
        flash[:notice] = "You have exceeded the maximum number of login attempts. Please wait #{COOLDOWN_PERIOD} seconds before trying again."
        redirect('/')
    elsif get_user_from_username(username).empty?
        flash[:notice] = "No user with that username."
        redirect('/')
    else
        result = get_user_from_username(username).first
        pwdigest = result["pwdigest"]
        id = result["id"]
        role = result["role"]

        if check_password(pwdigest, password)
            session["#{username}_failed_login_attempts"] = 0

            session[:id] = id
            session[:role] = role
            if role == 1
                redirect("/p/items_admin")
            else
                redirect('/p/home')
            end
        else
        
            session["#{username}_failed_login_attempts"] = failed_login_attempts + 1
            session["#{username}_last_failed_login_time"] = Time.now

            if failed_login_attempts + 1 >= MAX_LOGIN_ATTEMPTS
                flash[:notice] = "You have exceeded the maximum number of login attempts. Please wait #{COOLDOWN_PERIOD} seconds before trying again."
            else
                flash[:notice] = "Wrong password. You have #{MAX_LOGIN_ATTEMPTS - (failed_login_attempts + 1)} attempts remaining."
            end
            redirect('/')
        end
    end
end

# Attemts to register a user
#
# @param [string]:username, username of user
# @param [string]:password, password of user
# @param [string]:password_confirm, password_confirm of user
#
# @see Model#get_usernames
# @see Model#register_user
post('/register')do

    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    role = 0

    if username == "" || password == "" || password_confirm == ""
        flash[:notice] = "rutorna måste vara ifyllda"
    elsif get_usernames.include?([username])
        flash[:notice] = "already existing username"
    elsif (password == password_confirm)
        register_user(username,password,role)
        redirect('/')
    else
        flash[:notice] = "passwords did not match"
    end
    redirect('/showregister')
end

#Display register page
get('/showregister')do
    slim(:register)
end

#Display login page
get('/')do 
    slim(:login)
end

#display home page when loged in
#
#@see Model#show:home
get('/p/home')do
    user_id = session[:id]

    arr = show_home(user_id)

    brand = arr[0]
    item = arr[1]
    user = arr[2]

    slim(:"/home",locals:{brands_result:brand,items_result:item,user_result:user})
end

#dispay user shoppin cart
#
#@see Model#show_user_shoppingcart
get('/p/shopping_cart')do

    id = session[:id].to_i
    items = show_user_shoppingcart(id)

    p items

    slim(:"shopping_cart/index",locals:{items_result:items})

end

#Attempts adding item to shopping cart
#
# @param [integer]:id, the id of item
#
# @see Model#add_to_shoppingcart
post('/p/shopping_cart/add')do

    item_id = params[:item_id].to_i
    user_id = session[:id].to_i

    add_to_shoppingcart(item_id,user_id)

    redirect('/p/home')

end

#Attempts deleting item from shopping car
#
# @param [integer]:relation_id, id of the relation
# 
# @see Model#get_user_id_from_relation_id
# @see Model#delete_from_shoppingcart
post('/p/shopping_cart/delete')do

    relation_id = params[:relation_id].to_i
    user_id = session[:id].to_i
    result = get_user_id_from_relation_id(relation_id)
    connected_user_id = result["user_id"]

    if connected_user_id == user_id
        delete_from_shoppingcart(relation_id)
    else 
        redirect("/p/error")
    end
    redirect('/p/shopping_cart')

end

#displays all items
#
#see Model#show_items_admin
get('/p/items_admin') do

    unless admin
        redirect("/p/error")
    end

    result = show_items_admin()

    slim(:"admin/index",locals:{items_result:result})

end

# Attemts to delete item
#
# @param [Interger]:item_id, id of item
#
# see Model#delete_from_items_admin
post('/p/items_admin/delete')do

    unless admin
        redirect("/p/error")
    end


    item_id = params[:item_id].to_i

    delete_from_items_admin(item_id)

    redirect('/p/items_admin')

end

# Attemts to create new item
#
# @param [interger]:new_model_id, id of model of item
# @param [interger]:new_brand_id, id of brad of item
# @param [string]:new_name, name of itemm
# @param [string]:new_price, price of item¨
#
# @see Model#create_item
post('/p/items_admin/new')do

    unless admin
        redirect("/p/error")
    end


    new_model_id = params[:new_model_id].to_i
    new_brand_id = params[:new_brand_id].to_i
    new_name = params[:new_name]
    new_price = params[:new_price]

    if new_name == "" ||  new_price == ""
        flash[:notice] = "rutorna måste vara ifyllda"
    else
        create_item(new_model_id,new_brand_id,new_name,new_price)
    end

    redirect('/p/items_admin')
end

# Display error site
get("/p/error")do
   slim(:cheater)
end

# display list of users
#
# @see Model#get_all_user_info
get('/p/user_list_admin')do

    unless admin
        redirect("/p/error")
    end

    result = get_all_user_info()

    slim(:"admin/user_list",locals:{user_result:result})

end

# Attemots to delete user
#
# @param [interger]:user_id, id of user
#
# @see Model#delete_all_user_items
# @see Model#delete_user
post('/p/user_list_admin/delete')do

    unless admin
        redirect("/p/error")
    end

    user_id = params[:user_id]

    delete_all_user_items(user_id)
    delete_user(user_id)

    redirect('/p/user_list_admin')

end

# Attemots to add user
#
# @param [string]:username, username of user
# @param [string]:password, password of user
# @param [string]:password_confrim, password_confirm of user
# @param [interger]:role, role of user
#
# @see Model#register_user
post('/p/user_list_admin/add')do

    unless admin
        redirect("/p/error")
    end

    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    role = params[:role].to_i

    if username == "" || password == "" || password_confirm == ""
        flash[:notice] = "rutorna måste vara ifyllda"

    elsif get_usernames.include?([username])
        flash[:notice] = "already existing username"
        redirect('/p/user_list_admin')
    elsif (password == password_confirm)
        register_user(username,password,role)
        redirect('/p/user_list_admin')
    else
        flash[:notice] = "passwords did not match"
        redirect('/p/user_list_admin')
    end
    redirect('/p/user_list_admin')

end

# Displays ability to change user info
get("/p/edit_user")do
    slim(:edit_user)
end

# Attempts to change username
#
# @param [string]:new_username, new username of user
# @param [string]:new_username_confirm, username confrim of new user
#
# @see Model#update_user_username
# @see model#get_usernames
post("/p/edit_user_username")do

    username = params[:new_username]
    username_confirm = params[:new_username_confirm]
    user_id = session[:id]
    
    if username == "" || username_confirm ==""
        flash[:notice] = "rutorna måste vara ifyllda"
    elsif get_usernames.include?([username])
        flash[:notice] = "upptaget användarnamn"
    elsif (username == username_confirm)
        update_user_username(user_id,username)
        flash[:notice] = "användarnam uppdaterat till #{username}"
    else
        flash[:notice] = "användarnamnen matchade inte"
    end
    redirect("/p/edit_user")
end

# Attempts to change password
#
# @param [string]:old_password, old password of user
# @param [string]:new_password, new_password user
# @param [string]:new_password_confirm, new_password_confirm for user
#
# @see Model#get_password_from_id
# @see model#check_password
# @see model#update_user_password
post("/p/edit_user_password")do

    result = get_password_from_id(session[:id])
    old_pwdigest = result["pwdigest"]
    old_password = params[:old_password]
    new_password = params[:new_password]
    new_password_confirm = params[:new_password_confirm]

    if old_password == ""|| new_password == ""||new_password_confirm == ""
        flash[:notice] = "rutorna måste vara ifyllda"
    elsif check_password(old_pwdigest,old_password)
        if new_password == new_password_confirm
            update_user_password(session[:id],new_password)
            flash[:notice] = "Lösenordet är nu bytt till #{new_password}"
        else
            flash[:notice] = "ditt nya lösenord matchade inte"
        end
    else
        flash[:notice] = "ditt gamla lösenord var fel"
    end

    redirect("/p/edit_user")
end



