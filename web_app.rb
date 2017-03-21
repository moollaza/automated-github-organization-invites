require 'dotenv/load'
require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'slim'
require 'octokit'

token = ENV['GITHUB_TOKEN']
team_id = ENV['TEAM_ID']

client = Octokit::Client.new(access_token: token)

def user_exists?(client, user)
  begin
    response = client.user(user)
  rescue Octokit::NotFound
    return false
  end
  return true
end

def is_team_member?(client, team_id, user)
  begin
    response = client.team_membership(team_id, user)
    return response.state
  rescue Octokit::NotFound
    return false
  end
end


# ROUTES #

get "/" do
  slim :index, :locals => { :profile => @profile }
end

post "/add" do
  username = params["username"]
  if user_exists?(client, username)
    membership = is_team_member?(client, team_id, username)
    if membership == "active"
      heading = "#{username} is already an active member of the team!"
      message = nil
    elsif membership == "pending"
      heading = "#{username}'s team membership is pending"
      message = "Please check your email for an invitation.<br>Follow the instructions to finish joining the team."
    else
      client.add_team_membership(client, team_id, username)
      heading = "Sweet! You're almost done..."
      message = 'Please check your email for an invitation.<br>Follow the instructions to finish joining the team.'
    end
  else
    heading = "Uh oh!"
    message = "User not found. Please check your spelling"
  end
  slim :result, :locals => { :heading => heading, :message => message }
end
