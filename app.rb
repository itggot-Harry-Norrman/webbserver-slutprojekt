class App < Sinatra::Base
	enable :sessions

	stand = "You are not logged in"

	get '/' do
		db = SQLite3::Database.new("db/fitness.db")
		public_posts = db.execute("SELECT title, content, id FROM posts WHERE status=?","public")
		p public_posts
		comments = db.execute("SELECT content, post_id, user_id, user_name FROM comments WHERE post_id=(SELECT id FROM posts WHERE status='public')")
		public_posts = public_posts.reverse
		slim(:index, locals:{msg: session[:msg], public_posts:public_posts, comments:comments})
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
		elsif username.size > 14
			session[:msg] = "Username is too long maximum length of username is 14 characters"
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
			posts = db.execute("SELECT title, content, user_id, id FROM posts WHERE status='public'")
			friend_requests = db.execute("SELECT name, id FROM users WHERE id=(SELECT adding_id FROM relations WHERE added_id=? AND status=0)", session[:user_id])
			priv_posts = db.execute("SELECT title, content, user_id, id FROM posts WHERE status='private'")
			priv_arr = []
			priv_posts.each do |priv_post|
				if db.execute("SELECT status FROM relations WHERE adding_id=? AND added_id=?", [session[:user_id], priv_post[2]])[0] == [1] or db.execute("SELECT status FROM relations WHERE adding_id=? AND added_id=? ", [priv_post[2], session[:user_id]])[0] == [1] or priv_post[2] == session[:user_id]
					priv_arr << priv_post
				end
			end
			user_info = db.execute("SELECT name, id FROM users WHERE id=?", session[:user_id])
			friends1 = db.execute("SELECT id,name FROM users WHERE id in (SELECT added_id FROM relations WHERE status='1' AND adding_id=?)", session[:user_id])
			friends2 = db.execute("SELECT id,name FROM users WHERE id in (SELECT adding_id FROM relations WHERE status='1' AND added_id=?)", session[:user_id])
			friends = []
			friends << friends1 << friends2
			friends = friends.flatten
			index_friends = 0
			friend_ids = []
			friend_names = []
			friends.each do |friend_inf|
				if index_friends/2 == index_friends.to_f/2
					friend_ids << friend_inf
					index_friends += 1
				else
					friend_names << friend_inf
					index_friends += 1
				end
			end
			session[:friend_ids] = friend_ids
			comments = db.execute("SELECT content, post_id, user_id, user_name FROM comments")
			priv_arr = priv_arr.reverse
			posts = posts.reverse
			schedule = db.execute("SELECT id, excercise, reps, sets, day FROM scheme WHERE user_id=?", session[:user_id])
			slim(:user, locals:{friend_requests:friend_requests, public_posts:posts, priv_posts:priv_arr, friends:friend_names, user_info:user_info, comments:comments, schedule:schedule})
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
		if session[:user_id]
			title = params[:title]
			content = params[:text_content]
			status = params[:status]
			id = session[:user_id]
			db.execute("INSERT INTO posts('title', 'content', 'status', 'user_id') VALUES (?,?,?,?)", [title, content, status, id])
			redirect("/user")
		else
			session[:msg] = stand
			redirect("/")
		end
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
			session[:msg] = stand
			redirect("/")
		end
	end
	post '/logout'do
		session[:user_id] = nil
		session[:msg] = nil
		redirect("/")
	end
	post '/remove_friend' do
		db = SQLite3::Database.new("db/fitness.db")
		delete_user = params[:remove]
		if session[:user_id]
				db.execute("DELETE FROM relations WHERE adding_id=(SELECT id FROM users WHERE name=?) AND added_id=?",[delete_user, session[:user_id]])
				db.execute("DELETE FROM relations WHERE added_id=(SELECT id FROM users WHERE name=?) AND adding_id=?",[delete_user, session[:user_id]])
				redirect("/user")
		else
			session[:msg] = stand
			redirect("/")
		end
	end
	get '/user/info' do
		db = SQLite3::Database.new("db/fitness.db")
		if session[:user_id]
			user_info = db.execute("SELECT id, name FROM users WHERE id=?", session[:user_id])
			scheme = db.execute("SELECT id, excercise, reps, sets, day FROM scheme WHERE user_id=?", session[:user_id])
			slim(:info, locals:{user_info:user_info, scheme:scheme})
		else
			redirect("/")
		end
	end
	post '/comment_private' do
		db = SQLite3::Database.new("db/fitness.db")
		if session[:user_id]
			#fixa injections via privata comments
			test_id = db.execute("SELECT id FROM users WHERE id=(SELECT user_id FROM posts WHERE id=?)", params[:post_id])[0][0]  
			if db.execute("SELECT name FROM users WHERE id=?", session[:user_id])[0][0] == params[:name] and session[:friend_ids].include?(test_id) == true  
			name = db.execute("SELECT name FROM users WHERE id=?", session[:user_id])
			db.execute("INSERT INTO comments(content, post_id, user_id, user_name) VALUES(?,?,?,?)", [params[:comment], params[:post_id], session[:user_id], name])
			redirect('/user')
			else
				session[:msg] == "Unauthorized action detected"
				redirect("/")
			end
		else
			session[:msg] = stand
			redirect('/')
		end
	end
	post '/comment_public' do
		db = SQLite3::Database.new("db/fitness.db")
		if session[:user_id]
			name = db.execute("SELECT name FROM users WHERE id=?", session[:user_id])
			db.execute("INSERT INTO comments(content, post_id, user_id, user_name) VALUES(?,?,?,?)", [params[:comment], params[:post_id], session[:user_id], name])
			redirect('/user')
		else
			session[:msg] = stand
			redirect('/')
		end
	end
	post '/excercise_add' do
		db = SQLite3::Database.new("db/fitness.db")
		if session[:user_id] 
			if params[:excercise].size < 14
			db.execute("INSERT INTO scheme(excercise, reps, sets, day, user_id) VALUES(?,?,?,?,?)", params[:excercise], params[:reps], params[:sets], params[:day], session[:user_id])
				if params[:link]
					redirect('/user')
				else
					redirect('/user/info')
				end
				redirect('/user')
			else
				session[:msg] = stand
				redirect('/')
			end
		end
	end
	post '/delete_excercise' do
		db = SQLite3::Database.new("db/fitness.db")
		if session[:user_id]
			db.execute("DELETE FROM scheme WHERE id=? AND user_id=?", [params[:excercise_id], session[:user_id]])
			redirect('/user')
		else
			session[:msg] = stand
			redirect('/')
		end
	end
	post '/add_stat' do
			db = SQLite3::Database.new("db/fitness.db")
			if session[:user_id]
				packed_date = Time.now
				packed_date = packed_date.to_s.split(" ")
				date = packed_date[0][5..9]
				weight = params[:weight].to_s + "kg"
				db.execute("INSERT INTO statistics(date, lift, weight, user_id) VALUES(?,?,?,?)", [date, params[:lift].capitalize, weight, session[:user_id]])
				redirect('/user/info')
			else
				session[:msg] = stand
				redirect('/')
		end
	end
end           
