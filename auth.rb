module Auth
    def self.login(username, password)
        db = SQLite3::Database.new("db/fitness.db")
		if username == "" || password == ""
            return 2
		else
			db_password = db.execute("SELECT password FROM users WHERE name=?", username)
			if db_password == []
                return 3
			else
				db_password = db_password[0][0]
				password_digest =  db_password
				password_digest = BCrypt::Password.new( password_digest )
                if password_digest == password
                    user_id = db.execute("SELECT id FROM users WHERE name=?", username)
					user_id = user_id[0][0]
                    return [1, user_id]
				else
                    return 0
				end
			end
        end
	end
	def self.register(username, password, password2)
		db = SQLite3::Database.new("db/fitness.db")
		password_crypt = BCrypt::Password.create(password)
		password2_crypt = BCrypt::Password.create(password2)
		if username == "" || password == "" || password == ""
			return 1
		elsif password != password2
			return 2
		elsif db.execute("SELECT name FROM users WHERE name=?", username) != []
			return 3
		elsif username.size > 14
			return 4
		elsif username[/[a-zA-Z0-9]+/]  != username
			return 5
		else
			db.execute("INSERT INTO users ('name', 'password', 'show_stat') VALUES (?,?,?)", [username, password_crypt, 0])
			return 6
		end
		redirect('/')
	end
end