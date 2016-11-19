require 'sinatra'
require 'json'
require 'securerandom'

get '/success.json' do
  response = {
    id: 1,
    uuid: SecureRandom.uuid
  }
  
  response.to_json
end

get '/error.json' do
  response = {
    title: 'Error',
    message: 'An error has occurred'
  }

  status 400
  body response.to_json
end
