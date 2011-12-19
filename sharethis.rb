require 'sinatra'
require 'sqlite3'
require 'htmlentities'
require 'coderay'

URL = 'http://localhost:4567/share/'

helpers do
	def is_numeric?(i)
		i.to_i.to_s == i || i.to_f.to_s == i
	end
	
	def htmlentities(paste)
		HTMLEntities.new.encode(paste, :named)
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
		@db.execute("SELECT paste FROM pastebin WHERE id='#{id}'")[0][0] || nil
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

class PasteNotFound < Exception
end

error PasteNotFound do
	@title = 'Error'
	@error = 'Paste not found.'
	haml :error
end

error do
	@title = 'Error'
	@error = env['sinatra.error'].message
	haml :error
end

not_found do
	@title = '404'
	@error = 'Error 404: Not found'
	status 404
	haml :error
end

get '/share/?' do
	haml :index
end

post '/share/' do
	ShareThis.new.save(htmlentities(params[:paste]))
end

get '/share/list' do
	@list = ShareThis.new.get_all
	haml :list
end

get '/share/lang' do
	# list of coderay's supported languages
end

get '/share/:id>>:lang' do
	id = params[:id]
	raise PasteNotFound if !is_numeric?(id)
	paste = ShareThis.new.get(id)
	raise PasteNotFound if !paste
	CodeRay.scan(paste, params[:lang].to_sym).page(:title => '')
end

get '/share/:id' do
	id = params[:id]
	raise PasteNotFound if !is_numeric?(id)
	paste = ShareThis.new.get(id)
	raise PasteNotFound if !paste
	CodeRay.scan(paste, :text).page(:title => '')
end
