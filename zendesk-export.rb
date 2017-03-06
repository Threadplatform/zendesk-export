require 'sinatra'
require 'zendesk_api'
require 'csv'
require 'pony'

get '/' do
  erb :index
end

post '/create' do
	user = params[:user]
	api_key = params[:apiKey]
	filename = "tickets#{Time.now.to_i}.csv"
	'Your csv is being generated. Please wait.'
	Thread.new do
		create_csv(filename, user, api_key)
	end
	redirect back
end

def create_csv(filename, user, api_key)
	client = ZendeskAPI::Client.new do |config|
	  config.url = "https://thread-help.zendesk.com/api/v2" # e.g. https://mydesk.zendesk.com/api/v2
	  config.username = user
	  config.token = api_key
	end
	CSV.open("/tmp/#{filename}", "w") do |csv|
	  csv << ['id', 'Status', 'Subject', 'Requester', 'Request date', 'Assignee', 'Tags']
	  client.tickets.fetch!
	  client.tickets.all do |ticket|
	  	csv << [ticket.id, ticket.status, ticket.subject, ticket.requester.name, ticket.created_at, ticket.assignee.name, ticket.tags.map(&:id).join(" ")]
	  end
	end
   Pony.mail(
        :to => user,
        :from => 'Admin <techadmin@thread.org>',
        :subject => "Your csv #{filename}",
        :html_body => "Your csv is attached.",
        :attachments => {"#{filename}" => File.read("/tmp/#{filename}")},
        :via => :smtp, 
        :via_options => {
          :address        => 'smtp.gmail.com',
          :port           => '25',
          :enable_starttls_auto => true,
          :user_name      => 'techadmin@thread.org',
          :password       => ENV['SMTP_PASSWORD'],
          :authentication => :plain,
          }
      )
end