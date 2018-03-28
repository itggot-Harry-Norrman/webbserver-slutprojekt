class App < Sinatra::Base
	enable :sessions

	stand = "You are not logged in"

	get '/' do
		db = SQLite3::Database.new("db/fitness.db")
		public_posts = db.execute("SELECT title, content FROM posts WHERE status=?","public")
		public_posts = public_posts.reverse
		slim(:index, locals:{msg: session[:msg], public_posts:public_posts})
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

	post('/login') do
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

	get('/user') do
		db = SQLite3::Database.new("db/fitness.db")
		status = "public"
		if session[:user_id]
			posts = db.execute("SELECT title, content FROM posts WHERE status='public'")
			friend_requests = db.execute("SELECT name, id FROM users WHERE id=(SELECT adding_id FROM relations WHERE added_id=? AND status=0)", session[:user_id])
			priv_posts = db.execute("SELECT title, content, user_id FROM posts WHERE status='private'")
			priv_arr = []
			priv_posts.each do |priv_post|
				if db.execute("SELECT status FROM relations WHERE adding_id=? AND added_id=? ", [session[:user_id], priv_post[2]])[0] == [1] or db.execute("SELECT status FROM relations WHERE adding_id=? AND added_id=? ", [priv_post[2], session[:user_id]])[0] == [1]
					priv_arr << priv_post
				end
			end
			friends1 = db.execute("SELECT name FROM users WHERE id=(SELECT adding_id FROM relations WHERE status='1' AND added_id=?)", session[:user_id])
			friends2 = db.execute("SELECT name FROM users WHERE id=(SELECT added_id FROM relations WHERE status='1' AND adding_id=?)", session[:user_id])
			friends = []
			friends << friends1 << friends2
			friends = friends.flatten
			priv_arr = priv_arr.reverse
			posts = posts.reverse
			slim(:user, locals:{friend_requests:friend_requests, public_posts:posts, priv_posts:priv_arr, friends:friends})
		else
			session[:msg] = stand
			redirect("/")
		end
	end

	post '/search/user' do
		redirect('/search/'+params['search_inp'])
	end

	get '/search/:search_inp' do
		db = SQLite3::Database.new("db/fitness.db")
		if session[:user_id]
		searched = params[:search_inp]
		search_arr = db.execute("SELECT name, id FROM users WHERE name LIKE ?", ["%"+searched+"%"])
		slim(:search, locals:{search_arr:search_arr})
		else
			session[:msg] = "You need to login to be able to search for users"
			redirect("/")
		end
	end

	post '/add_post' do
		db = SQLite3::Database.new("db/fitness.db")
		title = params[:title]
		content = params[:text_content]
		status = params[:status]
		id = session[:user_id]
		db.execute("INSERT INTO posts('title', 'content', 'status', 'user_id') VALUES (?,?,?,?)", [title, content, status, id])
		redirect("/user")
	end
	get '/search/' do
		redirect("/user")
	end
	post '/friend_request' do
		db = SQLite3::Database.new("db/fitness.db")
		if session[:user_id]
			request = 0
			added_id = params[:user_id].to_i
			adding_id = session[:user_id]
			if db.execute("SELECT added_id, adding_id FROM relations WHERE added_id = ? AND adding_id = ?",[added_id, adding_id]) != [[added_id,adding_id]]
				db.execute("INSERT INTO relations('added_id','adding_id','status') VALUES (?,?,?)", [added_id, adding_id, request])
				redirect("/user")
			else
				redirect("/user")
			end
		else
			session[:msg] = stand
			redirect("/")
		end
	end
	post '/accept_friend' do 
		db = SQLite3::Database.new("db/fitness.db")
		adding_id = params[:adding_id]
		if session[:user_id]
			db.execute("UPDATE relations SET status=1 WHERE adding_id=? AND added_id=?", [adding_id, session[:user_id]])
			redirect("/user")
		else
			redirect("/")
		end
	end
	post '/logout'do
		session[:user_id] = nil
		session[:msg] = nil
		redirect("/")
	end
end           
