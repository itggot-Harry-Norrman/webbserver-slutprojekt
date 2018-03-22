class App < Sinatra::Base

	get '/' do
		slim(:index, locals:{msg: session[:msg]})
	end
	get '/register_site' do
		slim(:register)
	end

	post '/register' do 
		db = SQLite3::Database.new("db/fitness.db")
		username = params[:username]
		password = BCrypt::Password.create( params[:password] )
		password2 = BCrypt::Password.create( params[:password2] )
		if username == "" || password == "" || password == ""
			session[:msg] = "Please enter a username and password."
		elsif params[:password] != params[:password2]
			session[:msg] = "Passwords don't match"
		elsif db.execute("SELECT name FROM users WHERE name=?", username) != []
			session[:msg] = "Username already exists"
		else
			db.execute("INSERT INTO users ('name', 'password') VALUES (?,?)", [username, password])
		end
		redirect('/')
	end

	post '/login' do
		db = SQLite3::Database.new("db/fitness.db")
		username = params[:username]
		password = params[:password]
		if username == "" || password == ""
			session[:msg] = "Please enter a username and a password."
			redirect('/')
		else
			db_password = db.execute("SELECT password FROM users WHERE name=?", username)
			if db_password == []
				session[:msg] = "Username doesn't exist"
				redirect('/')
			else
				db_password = db_password[0][0]
				password_digest =  db_password
				password_digest = BCrypt::Password.new( password_digest )
				if password_digest == password
					user_id = db.execute("SELECT id FROM users WHERE name=?", username)
					user_id = user_id[0][0]
					session[:user_id] = user_id
					redirect('/user')
				else
					session[:user_id] = nil
					session[:msg] = "Wrong password or username"
					redirect('/')
				end
			end
		end
	end

	# get '/user' do
	# 	db = SQLite3::Database.new("db/fitness.db")
	# 	if session[:user_id]
	# 		posts = db.execute("SELECT title, content FROM posts WHERE status=public")
	# 	slim(:user)
	# end

	# get '/search' do
	# 	db = SQLite3::Database.new("db/fitness.db")
	# 	searched = params[:search_inp]
	# 	search_arr = db.execute("SELECT name FROM users WHERE name LIKE(?)", searched)
	# 	slim(:search, locals:{search_arr:search_arr})
	# end

end           
