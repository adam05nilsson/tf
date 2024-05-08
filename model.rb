module Model

    # Finds database
    #
    # @return [hash] The database
    def get_database()
        db = SQLite3::Database.new('db/webshop.db')
        db.results_as_hash = true
        return db
    end

    # Finds user information from username
    #
    # @return [hash] User info
    def get_user_from_username(username)
        db = get_database()
        result = db.execute("SELECT pwdigest, id, role FROM user WHERE username = ?",username)
        return result
    end

    # Chekcs passwords
    #
    # @return [boolean] If passwords match
    def check_password(pwdigest,password)
        db = get_database()
        return  BCrypt::Password.new(pwdigest) == password
    end

    # Finds users
    #
    # @return [hash] Users info
    def get_all_user_info()
        db = get_database()
    
        result = db.execute("SELECT pwdigest, id, role, username FROM user")

        return result

    end

    # Find usernames
    #
    # @return [array] Array with usernames
    def get_usernames()
        db = SQLite3::Database.new('db/webshop.db')
        result = db.execute("SELECT username FROM user")
        return result
    end

    # Attempts to register user
    def register_user(username,password,role)
        db = get_database()
        password_digest = BCrypt::Password.create(password)
        db.execute("INSERT INTO user (username,pwdigest,role) VALUES (?,?,?)",username,password_digest,role)
    end

    # Finds Users selected items
    #
    # @return [hash] chosen items
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

    # Attempts to add item to shoppingcart
    def add_to_shoppingcart(item_id,user_id)
        db = get_database()
        db.execute("INSERT INTO user_items_rel (user_id, items_id) VALUES (?,?)",user_id,item_id)
    end

    # Attempts to delete item from shoppingcart
    def delete_from_shoppingcart(relation_id)
        db = get_database
        db.execute("DELETE FROM user_items_rel WHERE id =?",relation_id)
    end

    # Finds all items
    #
    # return [hash] with all items
    def show_items_admin()
        db = get_database()
        result = db.execute ("SELECT items.*, brand.name AS brand_name, model.name AS model_name
        FROM items
        INNER JOIN brand ON items.brand_id = brand.id
        INNER JOIN model ON items.model_id = model.id")
    end
 
    # Attemptst to create item
    def create_item(new_model_id,new_brand_id,new_name,new_price)
        db = get_database()
        db.execute("INSERT INTO items (name, price, model_id, brand_id ) VALUES (?,?,?,?)",new_name,new_price,new_model_id,new_brand_id)
    end

    # Attempts to delete item
    def delete_from_items_admin(item_id)

        db = get_database()
        db.execute("DELETE FROM items WHERE id = ?", item_id)
        db.execute("DELETE FROM user_items_rel WHERE items_id = ?", item_id)

    end

    #Finds information to display on home page
    #
    # return [array] Array with user, brand and item
    def show_home(user_id)

        db = get_database()

        brand = db.execute("SELECT * FROM brand")
        item = db.execute("SELECT * FROM items")
        user = db.execute("SELECT username FROM user Where id =?",user_id).first

        arr = [brand,item,user]

        return arr
    end

    #attempts to delete user
    def delete_user(user_id)

        db = get_database()

        db.execute("DELETE FROM user WHERE id = ?", user_id)

    end

    #attempts to delte user items
    def delete_all_user_items(user_id)
        db = get_database()
        db.execute("DELETE FROM user_items_rel WHERE user_id =? ",user_id)
    end

    #attempts to update user's username
    def update_user_username(user_id,username)
        db = get_database()
        db.execute("UPdate user SET username =? WHERE id =? ",username,user_id)

    end

    #Finds user password
    #
    # return [hash] user password
    def get_password_from_id(user_id)
        db = get_database()
        return db.execute("SELECT pwdigest FROM user WHERE id = ?",user_id).first
    end

    #attempts to update user's password
    def update_user_password(user_id,password)
        db = get_database()
        password_digest = BCrypt::Password.create(password)
        db.execute("UPdate user SET pwdigest =? WHERE id =? ",password_digest,user_id)

    end

    #Finds user id connected to relation
    #
    # return [hash] user id
    def get_user_id_from_relation_id(relation_id)
    db = get_database()
    return db.execute("SELECT user_id FROM user_items_rel WHERE id = ?",relation_id).first
    end

end