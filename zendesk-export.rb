require 'sinatra/base'
require 'rack-flash'
require 'zendesk_api'
require 'csv'
require 'pony'
require 'dotenv/load'

class ZendeskExport < Sinatra::Base
  enable :sessions
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
		  csv << ['id', 'Status', 'Subject', 'Requester', 'Request date', 'Assignee', 'Tags']
		  client.tickets.fetch!
		  client.tickets.all do |ticket|
		  	csv << [ticket.id, ticket.status, ticket.subject, ticket.requester.name, ticket.created_at, ticket.assignee.name, ticket.tags.map(&:id).join(" ")]
		  end
		end
		csv
	end

	def send_csv(filename, user)
	   Pony.mail(
	        :to => user,
	        :from => "Admin <#{ENV['SMTP_USER']}>",
	        :subject => "Your csv #{filename}",
	        :html_body => "Your csv is attached.",
	        :attachments => {"#{filename}" => File.read("/tmp/#{filename}")},
	        :via => :smtp, 
	        :via_options => {
	          :address        => ENV['SMPT_ADDRESS'],
	          :port           => '25',
	          :enable_starttls_auto => true,
	          :user_name      => 'techadmin@thread.org',
	          :password       => ENV['SMTP_PASSWORD'],
	          :authentication => :plain,
	          }
	      )
	end
end