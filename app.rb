require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable:sessions


get('/')do
    slim(:home)
end

post('/login')do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/webshop.db')
    db.results_as_hash = true
    

    #lägg till så att man kollar att användarnmanet finns annars skriv "no existing username"

    result = db.execute("SELECT * FROM user WHERE username = ?",username).first

    p result
    
    pwdigest = result["pwdigest"]


    if BCrypt::Password.new(pwdigest) == password
        redirect('/')
    else
        "FEl LöSEN"
    end
end

get('/showlogin')do 
slim(:login)
end


post('/register')do

    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]

    if (password == password_confirm)

        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new('db/webshop.db')
        db.execute("INSERT INTO user (username,pwdigest,role) VALUES (?,?,0)",username,password_digest)
        redirect('/')
    else
        "lösenorden matchade inte"
    end
end


get('/showregister')do
slim(:register)
end

get('/items_admin') do
    db = SQLite3::Database.new('db/webshop.db')
    db.results_as_hash = true
    result = db.execute("SELECT items.*, brand.name AS brand_name, model.name AS model_name
    FROM items
    INNER JOIN brand ON items.brand_id = brand.id
    INNER JOIN model ON items.model_id = model.id")
    p result
    slim(:"items/index",locals:{items_result:result})
end

post('/items_admin/delete')do
    item_id = params[:item_id].to_i
    db = SQLite3::Database.new('db/webshop.db')
    db.execute("DELETE FROM items WHERE id = ?",item_id)
    redirect('/items_admin')

end

post('/items_admin/new')do
    new_model_id = params[:new_model_id].to_i
    new_brand_id = params[:new_brand_id].to_i
    new_name = params[:new_name]
    new_price = params[:new_price]
    p new_model_id
    p new_brand_id
    p new_name
    p new_price
    db = SQLite3::Database.new('db/webshop.db')
    db.execute("INSERT INTO items (name, price, model_id, brand_id ) VALUES (?,?,?,?)",new_name,new_price,new_model_id,new_brand_id)
    redirect('/items_admin')
end
