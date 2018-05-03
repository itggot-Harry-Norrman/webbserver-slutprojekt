module Users
    def self.user(user_id)
        db = SQLite3::Database.new("db/fitness.db")
        status = "public"
        if user_id
            posts = db.execute("SELECT title, content, user_id, id FROM posts WHERE status='public'")
            friend_requests = db.execute("SELECT name, id FROM users WHERE id=(SELECT adding_id FROM relations WHERE added_id=? AND status=0)", user_id)
            priv_posts = db.execute("SELECT title, content, user_id, id FROM posts WHERE status='private'")
            priv_arr = []
            priv_posts.each do |priv_post|
                if db.execute("SELECT status FROM relations WHERE adding_id=? AND added_id=?", [user_id, priv_post[2]])[0] == [1] or db.execute("SELECT status FROM relations WHERE adding_id=? AND added_id=? ", [priv_post[2], user_id])[0] == [1] or priv_post[2] == user_id
                    priv_arr << priv_post
                end
            end
            user_info = db.execute("SELECT name, id FROM users WHERE id=?", user_id)
            friends1 = db.execute("SELECT id,name FROM users WHERE id in (SELECT added_id FROM relations WHERE status='1' AND adding_id=?)", user_id)
            friends2 = db.execute("SELECT id,name FROM users WHERE id in (SELECT adding_id FROM relations WHERE status='1' AND added_id=?)", user_id)
            friends = []
            friends << friends1 << friends2
            friends = friends.flatten
            friend_test = []
            friend_index = 0
            while friend_index < friends.length - 1
                friend_n_i = []
                friend_n_i << friends[friend_index]
                friend_n_i << friends[friend_index + 1]
                friend_test << friend_n_i
                friend_index += 2
            end
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
            id_and_stat = []
            friend_ids.each do |friend_id|
                show_stat_friends = db.execute("SELECT id, show_stat FROM users WHERE id=?", friend_id)
                id_and_stat << show_stat_friends
            end
            # session[:friend_ids] = friend_ids
            comments = db.execute("SELECT content, post_id, user_id, user_name FROM comments")
            priv_arr = priv_arr.reverse
            posts = posts.reverse
            schedule = db.execute("SELECT id, excercise, reps, sets, day FROM scheme WHERE user_id=?", user_id)
            stats = db.execute("SELECT * FROM statistics WHERE user_id IN (?)", user_id)
            friend_stats = []
            id_and_stat.each do |ins|
                    friend_stat = db.execute("SELECT lift_id, weight, user_id FROM statistics WHERE user_id=? AND lift_id=?", [ins[0][0], ins[0][1]])
                    if friend_stat == []
                        friend_stats << [[ins[0][1], "1kg", ins[0][0]]]
                    else
                    friend_stats << friend_stat
                    end
            end
            lift_id = ["Squat", "Overhead Press", "Push Press", "Deadlift", "Sumo Deadlift", "Chin-up", "Pull-up", "Pendlay Row", "Bench Press", "Incline Bench Press", "Dip"]
            change=[]
            friend_stats.each do |all_stats|
                change_a = []
                start_stat = all_stats[0]
                change_a << lift_id[start_stat[0]]
                change_a << start_stat[2]
                end_stat = all_stats.last
                start_stat = start_stat[1].split(//).map {|x| x[/\d+/]}.compact.join("").to_i
                end_stat = end_stat[1].split(//).map {|x| x[/\d+/]}.compact.join("").to_i
                change_v = (end_stat/start_stat.to_f)
                change_v = ((change_v*100) - 100)
                if change_v.abs == change_v
                    change_v = "+" + change_v.to_s + "%"
                else
                    change_v = change_v.to_s + "%"
                end
                change_a << change_v
                change << change_a
            end
            user_information = [friend_requests, posts, priv_arr, friend_test, user_info, comments, schedule, change, friend_ids]
            return user_information
        else
            return 0
        end
    end
    def self.search(user_id, searched)
            db = SQLite3::Database.new("db/fitness.db")
            comments = db.execute("SELECT content, post_id, user_id, user_name FROM comments")
            schedule = db.execute("SELECT id, excercise, reps, sets, day FROM scheme WHERE user_id=?", user_id)
            stats = db.execute("SELECT * FROM statistics WHERE user_id IN (?)", user_id)
            search_arr = db.execute("SELECT name, id FROM users WHERE name LIKE ?", ["%"+searched+"%"])
            return [comments, schedule, stats, search_arr]
    end
    def self.info(user_id)
        db = SQLite3::Database.new("db/fitness.db")
        user_info = db.execute("SELECT name, id FROM users WHERE id=?", user_id)
        scheme = db.execute("SELECT excercise, reps, sets, day, id FROM scheme WHERE user_id=?", user_id)
        stats = db.execute("SELECT id, date, lift, weight FROM statistics WHERE user_id=?", user_id)
        return [user_info, scheme, stats]
    end
end