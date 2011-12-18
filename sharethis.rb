require 'sinatra'
require 'sqlite3'
require 'htmlentities'

URL = 'http://localhost:4567/share/' # URL to the index
ROBOTS = 'noindex,nofollow'

helpers do
	def is_numeric?(i)
		i.to_i.to_s == i || i.to_f.to_s == i
	end
	
	def htmlentities(paste)
		HTMLEntities.new.encode(paste, :named)
	end
	
	def mount(inner)
		"<html>\n<head>\n<meta name=\"robots\" content=\"#{ROBOTS}\" />\n</head>\n<body>\n#{inner}\n</body>\n</html>"
	end
end

class ShareThis
	attr_accessor :db
	
	def initialize
		@db = SQLite3::Database.new('sharethis.db')
		init_db
	end
	
	def init_db
		@db.execute('CREATE TABLE IF NOT EXISTS pastebin (id INTEGER PRIMARY KEY, paste TEXT)')
	end
	
	def get(id)
		@db.execute("SELECT paste FROM pastebin WHERE id='#{id}'")[0][0]
	end
	
	def get_all
		@db.execute("SELECT * FROM pastebin")
	end
	
	def count
		@db.get_first_value('SELECT COUNT(*) FROM pastebin')
	end
	
	def save(paste)
		@db.execute("INSERT INTO pastebin(paste) VALUES('#{paste}')")
		count
	end
	
	def delete(id)
		@db.execute("DELETE FROM pastebin WHERE id='#{id}'")
	end
end

class String
	def cut(limit)
		self.match(%r{^(.{0,#{limit}})})[1]
	end
end

get '/share/?' do
	mount("<p>cat FILENAME | curl -F 'paste=<-' #{URL}</p>")
end

post '/share/' do
	ShareThis.new.save(htmlentities(params[:paste]))
end

get '/share/list' do
	pastes = ShareThis.new.get_all
	list = ''
	pastes.each do |paste|
		list += "<a href=\"#{paste[0]}\">#{paste[0]}</a> <em>#{paste[1].cut(100)}[...]</em><br />\n"
	end
	mount(list)
end

get '/share/:id' do
	id = params[:id]
	mount('Not found') if !is_numeric?(id)
	paste = ShareThis.new.get(id)
	!paste ? mount('<p>Not found</p>') : mount("<pre>#{paste}</pre>")
end
