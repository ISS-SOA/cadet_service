require_relative 'spec_helper'
require_relative 'support/story_helpers'
require 'json'

describe 'CadetService Stories' do
  include StoryHelpers

  describe 'Getting the root of the service' do
    it 'should return ok' do
      get '/'
      last_response.must_be :ok?
    end
  end

  describe 'Getting single user information' do
    it 'should return their badges' do
      get '/api/v2/cadet/soumya.ray.json'
      last_response.must_be :ok?
    end

    it 'should return 404 for unknown user' do
      get "/api/v2/cadet/#{random_str(20)}.json"
      last_response.must_be :not_found?
    end
  end

  describe 'Checking multiple users' do
    before do
      Tutorial.delete_all
    end

    it 'should find missing badges' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = {
        description: 'Check valid users and badges',
        usernames: ['soumya.ray', 'chenlizhan'],
        badges: ['Object-Oriented Programming II']
      }

      # Check redirect URL from post request
      post '/api/v2/tutorials', body.to_json, header
      last_response.must_be :redirect?
      next_location = last_response.location
      next_location.must_match /api\/v2\/tutorials\/\d+/

      # Check if request parameters are stored in ActiveRecord data store
      tut_id = next_location.scan(/tutorials\/(\d+)/).flatten[0].to_i
      saved_tutorial = Tutorial.find(tut_id)
      JSON.parse(saved_tutorial[:usernames]).must_equal body[:usernames]
      JSON.parse(saved_tutorial[:badges]).must_include body[:badges][0]

      # Check if redirect works
      follow_redirect!
      last_request.url.must_match /api\/v2\/tutorials\/\d+/
    end

    it 'should return 404 for unknown users' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = {
        description: 'Check invalid users and invalid badges',
        usernames: [random_str(15), random_str(15)],
        badges: [random_str(30)]
      }

      post '/api/v2/tutorials', body.to_json, header

      last_response.must_be :redirect?
      follow_redirect!
      last_response.must_be :not_found?
    end

    it 'should return 400 for bad JSON formatting' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = random_str(50)

      post '/api/v2/tutorials', body, header
      last_response.must_be :bad_request?
    end


    it 'should be able to delete a previous query' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = {
        description: 'Check valid users and badges',
        usernames: ['soumya.ray', 'chenlizhan'],
        badges: ['Object-Oriented Programming II']
      }

      # Check redirect URL from post request
      post '/api/v2/tutorials', body.to_json, header
      last_response.must_be :redirect?
      next_location = last_response.location
      next_location.must_match /api\/v2\/tutorials\/\d+/

      # Check if request parameters are stored in ActiveRecord data store
      tut_id = next_location.scan(/tutorials\/(\d+)/).flatten[0].to_i
      delete "/api/v2/tutorials/#{tut_id}"
      last_response.must_be :ok?
    end


    it 'should report error if deleting an unknown entry' do
      delete "/api/v2/tutorials/55555"
      last_response.must_be :not_found?
    end
  end
end
