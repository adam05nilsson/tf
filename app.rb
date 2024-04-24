require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/flash'
require './model.rb'

enable:sessions

helpers do
    def admin
        return session[:role] == 1
    end
end

before('/p/*') do
    p "These are protected_methods"
     if session[:id] ==  nil
      redirect('/')
    end
end
   
post('/login')do

    username = params[:username]
    password = params[:password]

    if get_user(username).empty?
        flash[:notice] = "no user with that username"
        redirect('/')
    else
        result = get_user(username).first
        pwdigest = result["pwdigest"]
        id = result["id"]
        role = result["role"]

        if check_password(pwdigest,password)
            session[:id] = id
            session[:role] = role
            if role == 1
                redirect("/p/items_admin")
            else
                redirect('/p/home')
            end
        else
            flash[:notice] = "wrong password"
            redirect('/')
        end
    end
end

post('/register')do

    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    role = 0

    if get_usernames.include?([username])
        flash[:notice] = "already existing username"
        redirect('/showregister')
    elsif (password == password_confirm)
        register_user(username,password,role)
        redirect('/')
    else
        flash[:notice] = "passwords did not match"
        redirect('/showregister')
    end
end

get('/showregister')do
    slim(:register)
end

get('/')do 
    slim(:login)
end

get('/p/home')do
    user_id = session[:id]

    arr = show_home(user_id)

    brand = arr[0]
    item = arr[1]
    user = arr[2]

    slim(:"/home",locals:{brands_result:brand,items_result:item,user_result:user})
end

get('/p/shopping_cart')do

    id = session[:id].to_i
    items = show_user_shoppingcart(id)

    p items

    slim(:"shopping_cart/index",locals:{items_result:items})

end

post('/p/shopping_cart/add')do

    item_id = params[:item_id].to_i
    user_id = session[:id].to_i

    add_to_shoppingcart(item_id,user_id)

    redirect('/p/home')

end

post('/p/shopping_cart/delete')do

    relation_id = params[:relation_id].to_i
    user_id = session[:id].to_i

    p relation_id
  
    delete_from_shoppingcart(relation_id)

    redirect('/p/shopping_cart')

end

get('/p/items_admin') do

    unless admin
        redirect("/p/error")
    end

    result = show_items_admin()

    slim(:"admin/index",locals:{items_result:result})

end

post('/p/items_admin/delete')do

    unless admin
        redirect("/p/error")
    end


    item_id = params[:item_id].to_i

    delete_from_items_admin(item_id)

    redirect('/p/items_admin')

end

post('/p/items_admin/new')do

    unless admin
        redirect("/p/error")
    end


    new_model_id = params[:new_model_id].to_i
    new_brand_id = params[:new_brand_id].to_i
    new_name = params[:new_name]
    new_price = params[:new_price]

    create_item(new_model_id,new_brand_id,new_name,new_price)

    redirect('/p/items_admin')


end

get("/p/error")do
   slim(:cheater)
end

get('/p/user_list_admin')do

    unless admin
        redirect("/p/error")
    end

    result = get_all_user_info()

    slim(:"admin/user_list",locals:{user_result:result})

end

post('/p/user_list_admin/delete')do

    unless admin
        redirect("/p/error")
    end

    user_id = params[:user_id]

    delete_all_user_items(user_id)
    delete_user(user_id)

    redirect('/p/user_list_admin')

end

post('/p/user_list_admin/add')do

    unless admin
        redirect("/p/error")
    end

    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    role = params[:role].to_i

    if get_usernames.include?([username])
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

get("/p/edit_user")do


    slim()
end

post("logout")do
end



