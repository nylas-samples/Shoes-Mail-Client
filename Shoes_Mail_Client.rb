# Import dependecies
require 'dotenv/load'
require 'httparty'
require 'date'

# This class will hold the header needed to authenticate us
class Headers
	def get_headers()
			return @headers = { 
				"Content-Type" => "application/json",
				"Authorization"  => "Bearer  " + ENV["ACCESS_TOKEN"],
			}
	end
end

# This class will get our name from our Nylas account
class Account
	def initialize()
		@headers = Headers.new()
		# We're calling the Account Endpoint
		@account = HTTParty.get('https://api.nylas.com/account',
		                                        :headers => @headers.get_headers())
	end
	
	def get_name()
		return @account["name"]
	end
end

# This class will get a list of Labels so that we can send email to the trash
class Label
	def initialize()
		@labelsDict = Hash.new
		@headers = Headers.new()
		# We're calling the Labels Endpoint
		@labels = HTTParty.get('https://api.nylas.com/labels',
		                                     :headers => @headers.get_headers())
		for @label in @labels
			@labelsDict[@label["name"]] = @label["id"]
		end
	end
	
	def get_trash()
		return @labelsDict["trash"]
	end
end

# This class will make sure our emails look nice and tidy
class Clean_Email
	def initialize(message)
		@body = message.gsub(/\n/," ").gsub(/<style>.+<\/style>/," ").gsub(/<("[^"]*"|'[^']*'|[^'">])*>/," ").gsub(/&nbsp;/, " ")
	end
	
	def get_clean()
		return @body
	end
end

# This class will update our email status, either "Read" or "Delete"
class Update_Email
	def initialize(message, type, label="")
		@headers = Headers.new()
		if type == "read"
			@body = {
				"unread" => false,
			}
		else
			@body = {
				"label_ids" => [label],
			}			
		end
		# We're calling the Messages Endpoint
		@updated_email = HTTParty.put('https://api.nylas.com/messages/' + message, 
		                                                  :headers => @headers.get_headers(),
		                                                  :body => @body.to_json)
	end
end

# This class will send our emails or reply them
class Send_Email
	def initialize(recipient_name, recipient_email, subject, body, reply_id=nil)
		@headers = Headers.new()
		@body = {
			"subject" => subject,
			"body" => body,
			"to" => [{
				"name" => recipient_name,
				"email" => recipient_email
			}],
			"reply_to_message_id" =>  reply_id
		}
	end
	
	def send()
		# We're calling the Send Endpoint
		@email = HTTParty.post('https://api.nylas.com/send',:headers => @headers.get_headers(),
		                                      :body => @body.to_json)
	end
end

# This class will read our inbox and return the 5 most recent ones
class Emails
	def initialize()
		@headers = Headers.new()
	end
	
	def get_emails()
		# We're calling the Messages Endpoint
		@emails = HTTParty.get('https://api.nylas.com/messages?in=inbox&limit=5',
		                                      :headers => @headers.get_headers())
	end
	
	def return_emails()
		return @emails
	end
end

# This class will control the flow of our application
class Pages < Shoes
	url '/',			    	:index
	url '/read/(\d+)',		:read
	url '/compose',		:compose
	url '/reply/(\d+)',		:reply

	# Class variables that we can access from anywhere on the application
	@@email_detail = Net::HTTP::Get 
	@@trash_label = Net::HTTP::Get
	@@counter = 0

	# Our main view...this is our inbox
	def index
		background lightblue
		@@counter = 0
		@name = Account.new()
		if !@account_name
			@account_name = @name.get_name.split(" ").first
		end
		# Greet the user
		title "Welcome to your Inbox, " + @account_name + "!", align: "center"
		@emails = Emails.new()
		@labels = Label.new()
		# Create the Refresh and Compose buttons
		stack do
			background red
			flow do
				button "Refresh" do
					visit "/"
				end
				button "Compose" do
					visit "/compose"
				end				
			end	
		end
		stack do
			para ""
		end		
		@@trash_label = @labels.get_trash()
		@emails.get_emails()
		@@email_detail = @emails.return_emails()
		for @email in @@email_detail
			stack do
				@datetime = Time.at(@email["date"]).to_datetime
				@date = @datetime.to_s.scan(/\d{4}-\d{2}-\d{2}/)
				@time = @datetime.to_s.scan(/\d{2}:\d{2}:\d{2}/)
				# Display emails: Subject, Sender, Date and Time. 
				# Also if unread, display it using a different color
				if @email["unread"] == true
					para " ", link(@email["subject"], :click=>"/read/#{@@counter}"), " | " , 
					                   @email["from"][0]["name"] , " | ", @date , " - ", 
					                   @time, :size => 20, :stroke => darkblue
				else
					para " ", link(@email["subject"], :click=>"/read/#{@@counter}"), " | " , 
					                   @email["from"][0]["name"] , " | ", @date , " - ", 
					                   @time, :size => 20
				end
				para ""
			end
				# Global counter to make sure we're opening the right email
				@@counter += 1
		end
	end

	# View to read an email
	def read(index)
		background lightblue	
		# Update email state so it goes from "unread" to "read"
		@update_email = Update_Email.new(@@email_detail[index.to_i]["id"],"read","")
		stack do
			background red
			flow do
				button "Back" do
					visit "/"
				end
				button "Reply" do
					visit "/reply/#{index}"
				end
				# When deleting an email, pass the "trash" label
				button "Delete" do
					@email = Update_Email.new(@@email_detail[index.to_i]["id"],
					                                            "delete",@@trash_label)
					visit "/"
				end				
			end	
		end
		stack do
			background lavender
			flow do
				para "Date: ", :size => 25
				@datetime = Time.at(@@email_detail[index.to_i]["date"]).to_datetime
				@date = @datetime.to_s.scan(/\d{4}-\d{2}-\d{2}/)
				@time = @datetime.to_s.scan(/\d{2}:\d{2}:\d{2}/)
				para @date[0] + " - " + @time[0], :size => 20
			end
		end		
		stack do
			background lightcyan
			flow do
				para "Sender: ", :size => 25
				para @@email_detail[index.to_i]["from"][0]["name"] + " / " + 
				        @@email_detail[index.to_i]["from"][0]["email"], :size => 20
			end
		end	
		stack do
			background lightskyblue
			flow do
				para "Subject: ", :size => 25
				para @@email_detail[index.to_i]["subject"], :size => 20
			end
		end
		stack do
			# Call the Clean_Email in order to get rid of extra HTML
			@clean_email = Clean_Email.new(@@email_detail[index.to_i]["body"])
			@conversation = @clean_email.get_clean()		
				para "Body: ", :size => 25
				para ""
				para @conversation, :size => 20
		end
	end
	
	# View to compose an email
	def compose()
		@recipient_name.text = ""
		@recipient_email.text = ""
		@subject.text = ""
		@body.text = ""
		background lightblue
		stack do
			background red
			flow do
				button "Back" do
					visit "/"
				end
				button "Send" do
					# Call the Messages Endpoint to send the email
					@email = Send_Email.new(@recipient_name.text,@recipient_email.text,@subject.text,@body.text)
					@email.send()
					visit "/"
				end	
			end	
		end
		stack do
			background lightcyan
			flow do
				para "Recipient's Name: ", :size => 25
				@recipient_name = edit_line :width => 400
			end
		end
		stack do
			background lightcyan
			flow do
				para "Recipient's Email: ", :size => 25
				@recipient_email = edit_line :width => 400
			end
		end		
		stack do
			background lightskyblue
			flow do
				para "Subject: ", :size => 25
				@subject = edit_line :width => 600
			end
		end	
		stack do
			flow do
				para "Body: ", :size => 25
				@body = edit_box :width => 800, :height => 240
			end
		end			
	end
	
	# View to reply an email
	def reply(index)
		@recipient_name.text = ""
		@recipient_email.text = ""
		@subject.text = ""
		@body.text = ""
		background lightblue
		stack do
			background red
			flow do
				button "Back" do
					visit "/"
				end
				button "Send" do
					# Call the Messages Endpoint to send the email
					# and using the reply_to_message_id
					@email = Send_Email.new(@recipient_name,@recipient_email,@subject.text,
					                                         @body.text,@@email_detail[index.to_i]["id"])
					@email.send()
					visit "/"
				end	
			end	
		end
		stack do
			background lightcyan
			flow do
				para "Recipient's Name: ", :size => 25
				para @@email_detail[index.to_i]["from"][0]["name"], :size => 20
				@recipient_name = @@email_detail[index.to_i]["from"][0]["name"]
			end
		end
		stack do
			background lightcyan
			flow do
				para "Recipient's Email: ", :size => 25
				para @@email_detail[index.to_i]["from"][0]["email"], :size => 20
				@recipient_email = @@email_detail[index.to_i]["from"][0]["email"]
			end
		end		
		stack do
			background lightskyblue
			flow do
				para "Subject: ", :size => 25
				@subject = edit_line :width => 600
				@subject.text = "Re: " + @@email_detail[index.to_i]["subject"]
			end
		end	
		stack do
			flow do
				# Body of reply message. 
				@clean_email = Clean_Email.new(@@email_detail[index.to_i]["body"])
				@conversation = @clean_email.get_clean()				
				@datetime = Time.at(@@email_detail[index.to_i]["date"]).to_datetime
				@date = @datetime.to_s.scan(/\d{4}-\d{2}-\d{2}/)
				@time = @datetime.to_s.scan(/\d{2}:\d{2}:\d{2}/)
				para "Body: ", :size => 25
				@body = edit_box :width => 800, :height => 240
				@body.text = "\n\n\nOn " + @date[0] + " at " + @time[0] + "  " + 
				                     @@email_detail[index.to_i]["from"][0]["email"]  + 
				                     " wrote: \n\n\n" + @conversation[0]["conversation"]
			end
		end	
	end
	
end

# We call our Shoes application, specifying the name, width, height and if it's resizable or not
Shoes.app title: "Shoes Email Client", width: 1000, height: 400, resizable: false
