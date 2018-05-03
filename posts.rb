module Posts
    def self.stand_post
        db = SQLite3::Database.new("db/fitness.db")
		public_posts = db.execute("SELECT title, content, id FROM posts WHERE status=?","public")
		comments = db.execute("SELECT content, post_id, user_id, user_name FROM comments WHERE post_id=(SELECT id FROM posts WHERE status='public')")
        public_posts = public_posts.reverse
        return [public_posts, comments]
    end
end