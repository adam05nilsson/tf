require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/flash'
require './model.rb'

enable:sessions

#KLAR
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
                redirect("/items_admin")
            else
                redirect('/home')
            end
        else
            flash[:notice] = "wrong password"
            redirect('/')
        end
    end
    # login(username,password)
end

#KLAR
post('/register')do

    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]

    if get_usernames.include?([username])
        flash[:notice] = "already existing username"
        redirect('/showregister')
    elsif (password == password_confirm)
        register_user(username,password)
        redirect('/')
    else
        flash[:notice] = "passwords did not match"
        redirect('/showregister')
    end
end

#KLAR
get('/showregister')do
    slim(:register)
end

#KLAR
get('/')do 
    slim(:login)
end

get('/home')do
    user_id = session[:id]
    db = SQLite3::Database.new('db/webshop.db')
    db.results_as_hash = true
    brand = db.execute("SELECT * FROM brand")
    item = db.execute("SELECT * FROM items")
    user = db.execute("SELECT username FROM user Where id =?",user_id).first
    slim(:"/home",locals:{brands_result:brand,items_result:item,user_result:user})
end

#KLAR
get('/shopping_cart')do

    id = session[:id].to_i
    items = show_user_shoppingcart(id)

    slim(:"shopping_cart/index",locals:{items_result:items})

end

#KLAR
post('/shopping_cart/add')do

    item_id = params[:item_id].to_i
    user_id = session[:id].to_i

    add_to_shoppingcart(item_id,user_id)

    redirect('/home')

end


post('/shopping_cart/delete')do

    item_id = params[:item_id].to_i
    user_id = session[:id].to_i
  
    delete_from_shoppingcart(item_id,user_id)

    redirect('/shopping_cart')

end

#KLAR
get('/items_admin') do

    unless admin
        redirect("/error")
    end

    result = show_items_admin()

    slim(:"items/index",locals:{items_result:result})

end

#KLAR
post('/items_admin/delete')do

    item_id = params[:item_id].to_i

    delete_from_items_admin(item_id)

    redirect('/items_admin')

end

#KLAR
post('/items_admin/new')do

    new_model_id = params[:new_model_id].to_i
    new_brand_id = params[:new_brand_id].to_i
    new_name = params[:new_name]
    new_price = params[:new_price]

    create_item(new_model_id,new_brand_id,new_name,new_price)

end

#lägg till rickroll
get("/error")do
   slim(:cheater)
end

