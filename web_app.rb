require 'dotenv/load'
require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'slim'
require 'octokit'

token = ENV['GITHUB_TOKEN']
if token == nil
    abort("Please provide a GitHub Token!")
end

team_id = ENV['TEAM_ID']
if team_id == nil
    abort("Please provide a GitHub Team ID!")
end

client = Octokit::Client.new(access_token: token)

# Check user is real
def user_exists?(client, user)
    begin
        response = client.user(user)
        return true
    rescue Octokit::NotFound
        return false
    end
end

# Check if user is already a team member
def is_team_member?(client, team_id, user)
    begin
        response = client.team_membership(team_id, user)
        return response.state
    rescue Octokit::NotFound
        return false
    end
end

# Add user to team
def add_team_member?(client, team_id, user)
    begin
        response = client.add_team_membership(team_id, user)
        return response
    rescue Exception
        return false
    end
end


# ROUTES #

get '/' do
    slim :index, locals: { profile: @profile }
end


post '/add' do
    @username = params['username']
    # Check if user is real
    if user_exists?(client, @username)
        membership = is_team_member?(client, team_id, @username)

        # Already team member
        if membership == 'active'
            heading = "#{@username} is already an active member of the team!"
            message = nil

        # Invite already sent
        elsif membership == 'pending'
            heading = "#{@username}'s team membership is pending"
            message = 'Please check your email for an invitation.<br>Follow the instructions to finish joining the team.'

        # Not a team member
        else
            response = add_team_member?(client, team_id, @username)

            # Invitation failed
            if response == false
                heading = "Uh oh! We were unable to add #{@username} to the team!"
                message = 'Please contact open@duckduckgo.com to let us know.'
            # Invitation successfully sent
            elsif response.state == 'pending'
                heading = "Sweet! You're almost done..."
                message = 'Please check your email for an invitation.<br>Follow the instructions to finish joining the team.'
            end
        end
    else
        heading = 'Uh oh!'
        message = "User: '#{@username}' not found. Please check your spelling."
    end
    slim :result, locals: { heading: heading, message: message }
end
