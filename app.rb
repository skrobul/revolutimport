require 'sinatra'
require_relative 'lib/revolut2ynab'

get '/' do
  erb :index
end

post '/convert' do
  file = params[:statement][:tempfile]
  filename = params[:statement][:filename]
  dst_filename = filename.sub(/\.csv/i, '.ynab.csv')
  revolut_statement = Revolut::Statement.new(file)

  content_type 'application/octet-stream'
  headers['Content-Disposition'] = "attachment;filename=#{dst_filename}"
  Revolut::YNABStatement
    .from_revolut(revolut_statement)
    .to_csv
end
