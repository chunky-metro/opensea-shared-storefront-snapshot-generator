require 'sinatra'
require 'sinatra/reloader' if development?
require 'erubis'
require './lib/ethereum_spreadsheet.rb'


get '/' do
  erb :index
end

post '/generate' do
  first_token_id = params[:first_token_id]
  last_token_id = params[:last_token_id]

  if first_token_id.empty? || last_token_id.empty?
    @error = "Please fill in all fields."
    return erb :index
  end

  begin
    @spreadsheet = EthereumSpreadsheet.new(first_token_id, last_token_id)
    csv_content =  @spreadsheet.generate
    temp_file = Tempfile.new(['spreadsheet', '.csv'])
    temp_file.write(csv_content)
    temp_file.rewind  # Rewind the file pointer to the beginning
    send_file temp_file.path, :filename => "snapshot-#{Date.today.strftime('%m%d%Y')}.csv", :type => 'text/csv'
  rescue => e
    @error = "An error occurred: #{e.message}"
    erb :index
  end
end
