require 'rubygems'
require 'sinatra'

set :sessions, true

helpers do 
  def calculate_total(cards)
    prev_ace = 0
    total = 0

    cards.each do |c|
      if c[1] == "Jack"
        total = total + 10
      elsif c[1] == "Queen"
        total = total + 10
      elsif c[1] == "King"
        total = total + 10
      elsif c[1] == "Ace"
        prev_ace += 1
      else
        total = total + c[1].to_i
      end
    end

    prev_ace.times do 
      if (total + 11) > 21
        total += 1
      else
        total += 11
      end
    end
  total
  end

  def image(card)
    suit = card[0]
    value = card[1]
    path = "#{suit.downcase}_#{value.downcase}"
    "<img src=/images/cards/#{path}.jpg class=card_image>"
  end

  def image_cover(cards)
    if @dealer_count == 1
      @dealer_count = @dealer_count + 1
      result = image(cards)
    else
      @dealer_count = @dealer_count + 1
      result = "<img src=/images/cards/cover.jpg class=card_image>"
    end
    result
  end

end

before do
  @hit_or_stay = true
  @dealer_hit = false
  @dealer_count = 0
end


get '/' do
  if session[:player_name]
    redirect :new_game
  else
    erb :new_player
  end
end

get '/new_player' do 
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Name required"
    halt erb :new_player
  end

  session[:player_name] = params[:player_name]
  redirect :new_game
end

get '/new_game' do
  suit = ["Hearts", "Clubs", "Spades", "Diamonds"]
  values = ['2','3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King', 'Ace']
  session[:deck] = suit.product(values).shuffle!
  session[:players_cards] = []
  session[:dealers_cards] = []
  session[:player_total] = 0
  session[:dealers_total] = 0

  2.times do 
    session[:players_cards] << session[:deck].pop
    session[:dealers_cards] << session[:deck].pop
  end

  session[:player_total] = calculate_total(session[:players_cards])
  session[:dealer_total] = calculate_total(session[:dealers_cards])

  if session[:hit]
    session[:players_cards] << session[:deck].pop
  end

  if session[:player_total] == 21
    @success = "Congratulations #{session[:player_name]} has hit blackjack!"
    @hit_or_stay = false
  end

  if session[:dealer_total] == 21
    @error = "#{session[:player_name]} lost, the dealer has hit blackjack"
    @hit_or_stay = false
  end

  erb :new_game
end

get '/new_game/hit' do
  session[:players_cards] << session[:deck].pop
  if calculate_total(session[:players_cards]) > 21
    @error = "#{session[:player_name]} has busted!"
    @hit_or_stay = false
  elsif calculate_total(session[:players_cards]) == 21
    @success = "#{session[:player_name]} hit blackjack!"
    @hit_or_stay = false
  end
    
  erb :new_game
end

get '/new_game/stay' do
  @dealer_hit = true
  @hit_or_stay = false
  @dealer_turn = true
  session[:player_total] = calculate_total(session[:players_cards])
  if session[:dealer_total] > session[:player_total]
    @error = "#{session[:player_name]} has lost, the dealer has #{session[:dealer_total]}"
  end
  erb :new_game
end

get '/dealer/hit' do
  @hit_or_stay = false
  @dealer_total = false
  @dealer_turn = true
  session[:player_total] = calculate_total(session[:players_cards])
  session[:dealers_cards] << session[:deck].pop
  session[:dealer_total] = calculate_total(session[:dealers_cards])
  if session[:dealer_total] <= session[:player_total]
    @dealer_hit = true
  elsif session[:dealer_total] > session[:player_total] && session[:dealer_total] <= 21
    @dealer_hit = false
    @error = "#{session[:player_name]} lost, dealer won with a score of #{session[:dealer_total]}"
  elsif session[:dealer_total] > 21
    @success = "Congratulations #{session[:player_name]} has won! Dealer busted with a score of #{session[:dealer_total]}"
    @dealer_hit = false
  end

  erb :new_game
end
