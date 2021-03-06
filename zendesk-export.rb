require 'sinatra/base'
require 'rack-flash'
require 'zendesk_api'
require 'csv'
require 'pony'
require 'dotenv/load'

class ZendeskExport < Sinatra::Base
  configure :production, :development do
    enable :logging, :sessions
  end
  use Rack::Flash

	get '/' do
	  erb :index
	end

	post '/create' do
		user = params[:user]
		api_key = params[:apiKey]
		filename = "tickets#{Time.now.to_i}.csv"
		Thread.new do
			create_csv(filename, user, api_key)
			send_csv(filename, user)
		end
		flash[:notice] = "Your csv is being generated. Plase check your email shortly."
		redirect back
	end

	private

	def create_csv(filename, user, api_key)
		client = ZendeskAPI::Client.new do |config|
		  config.url = "https://#{ENV['ZENDESK_BASE']}.zendesk.com/api/v2" # e.g. https://mydesk.zendesk.com/api/v2
		  config.username = user
		  config.token = api_key
		end
		csv = CSV.open("/tmp/#{filename}", "w") do |csv|
		  csv << ['id', 'Status', 'Subject', 'Requester', 'Request date', 'Assignee', 'Tags', 'Type', 'Priority', 'To Email', 'Description']
		  client.tickets.fetch!
		  client.tickets.all! do |ticket|
		  	logger.info "ticket"
		  	assignee_name = ticket.assignee.name if ticket.assignee
		  	requester_name = ticket.requester.name if ticket.requester
		  	csv << [ticket.id, ticket.status, ticket.subject, requester_name, ticket.created_at, assignee_name, ticket.tags.map(&:id).join(" "), ticket.type, ticket.priority, ticket.via.source.to.address, ticket.description]
		  end
		end
	end

	def send_csv(filename, user)
	   mail = Pony.mail(
	        :to => user,
	        :from => "Admin <#{ENV['SMTP_USER']}>",
	        :subject => "Your csv #{filename}",
	        :html_body => "Your csv is attached.",
	        :attachments => {"#{filename}" => File.read("/tmp/#{filename}")},
	        :via => :smtp, 
	        :via_options => {
	          :address        => ENV['SMTP_ADDRESS'],
	          :port           => '25',
	          :enable_starttls_auto => true,
	          :user_name      => ENV['SMTP_USER'],
	          :password       => ENV['SMTP_PASSWORD'],
	          :authentication => :plain,
	          }
	      )
	end
end