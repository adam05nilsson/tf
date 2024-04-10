
helpers do
    def admin
        return session[:role] == 1
    end
end

def get_database()
    db = SQLite3::Database.new('db/webshop.db')
    db.results_as_hash = true
    return db
end

def get_user(username)
    db = get_database()
    result = db.execute("SELECT pwdigest, id, role FROM user WHERE username = ?",username)
    return result
end

def check_password(pwdigest,password)
    db = get_database()
    return  BCrypt::Password.new(pwdigest) == password
end

def get_usernames()
    db = SQLite3::Database.new('db/webshop.db')
    result = db.execute("SELECT username FROM user")
    return result
end

def register_user(username,password)
    db = SQLite3::Database.new('db/webshop.db')
    password_digest = BCrypt::Password.create(password)
    db.execute("INSERT INTO user (username,pwdigest,role) VALUES (?,?,0)",username,password_digest)
end

def show_user_shoppingcart(id)
    db = get_database()
    items = db.execute("SELECT user_items_rel.id, items.name, items.price, model.name AS model_name, brand.name AS brand_name, items_id
    FROM (((user_items_rel 
    INNER JOIN items ON user_items_rel.items_id = items.id)
    INNER JOIN model ON items.model_id = model.id)
    INNER JOIN brand ON items.brand_id = brand.id)
    WHERE user_id = #{id}
    ")
    return items
end 

def add_to_shoppingcart(item_id,user_id)
    db = get_database()
    db.execute("INSERT INTO user_items_rel (user_id, items_id) VALUES (?,?)",user_id,item_id)
end

def delete_from_shoppingcart(relation_id)
    db = get_database
    db.execute("DELETE FROM user_items_rel WHERE id =?",relation_id)
end

def show_items_admin()
    db = get_database()
    result = db.execute ("SELECT items.*, brand.name AS brand_name, model.name AS model_name
    FROM items
    INNER JOIN brand ON items.brand_id = brand.id
    INNER JOIN model ON items.model_id = model.id")
end

def create_item(new_model_id,new_brand_id,new_name,new_price)
    db = get_database()
    db.execute("INSERT INTO items (name, price, model_id, brand_id ) VALUES (?,?,?,?)",new_name,new_price,new_model_id,new_brand_id)
end

def delete_from_items_admin(item_id)

    db = get_database()
    db.execute("DELETE FROM items WHERE id = ?", item_id)
    db.execute("DELETE FROM user_items_rel WHERE items_id = ?", item_id)

end

def show_home(user_id)

    db = get_database

    brand = db.execute("SELECT * FROM brand")
    item = db.execute("SELECT * FROM items")
    user = db.execute("SELECT username FROM user Where id =?",user_id).first

    arr = [brand,item,user]

    return arr
end