require_relative './auth.rb'
require_relative './users.rb'
require_relative './posts.rb'


class App < Sinatra::Base
	include Auth
	include Users
	include Posts
	
	enable :sessions
	stand = "You are not logged in"

	get '/' do
		posts = Posts::stand_post
		slim(:index, locals:{msg: session[:msg], public_posts:posts[0], comments:posts[1]})
	end
	get '/register_site' do
		slim(:register)
	end
	post '/register' do 
		result = Auth::register(params[:username], params[:password], params[:password2])
		result += -1 
		session[:msg] = ["Please enter a username and password.","Passwords don't match","Username already exists","Username is too long maximum length of username is 14 characters", "Your name contains special characters, only letters and numbers are allowed", "You are now registered"][result]
		# if result == 1
		# 	session[:msg] = "Please enter a username and password."
		# elsif result == 2
		# 	session[:msg] = "Passwords don't match"
		# elsif result == 3
		# 	session[:msg] = "Username already exists"
		# elsif result == 4
		# 	session[:msg] = "Username is too long maximum length of username is 14 characters"
		# else
		# end
		redirect("/")
	end

	post('/login') do
		username = params[:username]
		password = params[:password]
		result = Auth::login(username, password)
		if result == 2
			session[:msg] = "Please enter a username and a password."
			redirect('/')
		else
			if result == 3
				session[:msg] = "Username doesn't exist"
				redirect('/')
				else
					if result[0] == 1
					session[:user_id] = result[1]
					redirect("/user")
					else 
						session[:user_id] = nil
						session[:msg] = "Wrong password or username"
						redirect("/")
					end
				end
			end
	end
	get('/user') do
		results = Users::user(session[:user_id])
		if results != 0
			session[:friend_ids] = results[8]
			slim(:user, locals:{friend_requests:results[0], public_posts:results[1], priv_posts:results[2], friends:results[3], user_info:results[4], comments:results[5], schedule:results[6], change:results[7]})
		else
			session[:msg] = stand
			redirect("/")
		end
	end

	post '/search/user' do
		if params[:search_inp][/[a-zA-Z0-9]+/] == params[:search_inp]
			redirect('/search/'+params[:search_inp])
		else
			redirect('/user')
		end
	end

	get '/search/:search_inp' do
		results = Users::user(session[:user_id])
		search = Users::search(session[:user_id], params[:search_inp])
		if results != 0
		session[:friend_ids] = results[8]
		slim(:search, locals:{search_arr:search[3], friends:results[3], user_info:results[4], schedule:search[3], searched:params[:search_inp], change:results[7], friend_requests:results[0]})
		else
			session[:msg] = stand
			redirect("/")
		end
	end

	post '/add_post' do
		db = SQLite3::Database.new("db/fitness.db")
		if session[:user_id] and params[:text_content] != "" and params[:title] != ""
			title = params[:title]
			name = db.execute("SELECT name FROM users WHERE id=?", session[:user_id])
			content = params[:text_content] + "-#{name[0][0]}"
			status = params[:status]
			id = session[:user_id]
			if status == nil
				status  = "private"
			end
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
			if db.execute("SELECT added_id, adding_id FROM relations WHERE added_id = ? AND adding_id = ?",[added_id, adding_id]) != [[added_id,adding_id]] and added_id != adding_id
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
		if session[:user_id]
			results = Users::info(session[:user_id])
			slim(:info, locals:{user_info:results[0], scheme:results[1], stats:results[2]}) 	
		else
			session[:msg] = stand
			redirect("/")
		end
	end
	post '/comment_private' do
		db = SQLite3::Database.new("db/fitness.db")
		if session[:user_id]
			#fixa injections via privata comments
			test_id = db.execute("SELECT id FROM users WHERE id=(SELECT user_id FROM posts WHERE id=?)", params[:post_id])[0][0]
			if db.execute("SELECT name FROM users WHERE id=?", session[:user_id])[0][0] == params[:name] or session[:friend_ids].include?(test_id) == true
			name = db.execute("SELECT name FROM users WHERE id=?", session[:user_id])
			db.execute("INSERT INTO comments(content, post_id, user_id, user_name) VALUES(?,?,?,?)", [params[:comment], params[:post_id], session[:user_id], name])
			redirect('/user')
			else
				session[:msg] = "Unauthorized action detected"
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
		if session[:user_id] and params[:excercise] != ""
			if params[:excercise].size < 18
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
		else
			if params[:link]
				redirect('/user')
			else
				redirect('/user/info')
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
				date = packed_date[0][0..9]
				weight = params[:weight].to_s + "kg"
				lift_id = ["Squat", "Overhead Press", "Push Press", "Deadlift", "Sumo Deadlift", "Chin-up", "Pull-up", "Pendlay Row", "Bench Press", "Incline Bench Press", "Dip"]	
				lift_index = lift_id.index(params[:lift])
				db.execute("INSERT INTO statistics(date, lift, lift_id, weight, user_id) VALUES(?,?,?,?,?)", [date, params[:lift], lift_index.to_i, weight, session[:user_id]])
				redirect('/user/info')
			else
				session[:msg] = stand
				redirect('/')
		end
	end
	post '/display_stat' do
		db = SQLite3::Database.new("db/fitness.db")
		if session[:user_id]
			lift_id = ["Squat", "Overhead Press", "Push Press", "Deadlift", "Sumo Deadlift", "Chin-up", "Pull-up", "Pendlay Row", "Bench Press", "Incline Bench Press", "Dip"]
			show_stat_id = lift_id.index(params[:lift])
			db.execute("UPDATE users SET show_stat=? WHERE id=?", [show_stat_id, session[:user_id]])
			redirect('/user/info')
		else
			session[:msg] = stand
			redirect('/')
		end
	end
	post '/remove_stat' do
		db = SQLite3::Database.new("db/fitness.db")
		if session[:user_id]
			db.execute("DELETE FROM statistics WHERE id=? AND user_id=?", params[:stat_id], session[:user_id])
			redirect('/user/info')
		else
			session[:msg] = stand
			redirect('/')
		end
	end
end           
