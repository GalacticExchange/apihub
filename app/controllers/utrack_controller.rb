class UtrackController < ApplicationController


  def users

    if params[:filter] && params[:filter].contains?('with_usernames')
      puts "hey hi hello!"
    end




  end








end
