# frozen_string_literal: true

require 'openssl'
require 'terminal-table'

class Numeric
  def sign
    if positive?
      'Lose'
    elsif zero?
      'Draw'
    else
      'Win'
    end
  end
end

class JanKen
  attr_reader :moves, :comp_move, :key, :hmac, :user_move, :help_table

  def initialize(moves)
    @moves = moves
    @comp_move = moves.sample
    @key = OpenSSL::Random.random_bytes(32)
    @hmac = OpenSSL::HMAC.hexdigest('sha256', key, comp_move)
    @help_table = generate_table(moves)
  end

  def run # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    loop do
      print_menu
      print 'Enter your move: '
      user_choice = $stdin.gets.chomp
      case user_choice
      when '0'
        puts 'Exiting game!!'
        break
      when '?'
        puts generate_table(moves)
      else
        n = user_choice.to_i
        unless n.between?(1, moves.length)
          puts 'Enter correct number.'
          next
        end

        @user_move = moves[n - 1]
        print_result
        break
      end
    end
  end

  def generate_table(moves)
    headings = ['v Moves v'] + moves
    rows = []
    moves.each_with_index do |move, i|
      rows << [move] + moves.each_with_index.map { |_, j| calculate_result(i, j) }
    end
    Terminal::Table.new do |t|
      t.rows = rows
      t.headings = headings
      t.style = { all_separators: true }
    end
  end

  def print_menu
    puts "HMAC: #{@hmac}"
    puts 'Available moves:'
    @moves.each_with_index do |move, i|
      puts "#{i + 1} - #{move}"
    end
    puts '0 - exit'
    puts '? - help'
  end

  def calculate_result(comp_move_i, user_move_i)
    total = @moves.length
    middle = total >> 1
    ((comp_move_i - user_move_i + middle + total) % total - middle).sign
  end

  def print_result
    puts "Your move: #{@user_move}\nComputer move: #{@comp_move}"
    case calculate_result(@moves.index(@comp_move), @moves.index(@user_move))
    when 'Win'
      puts 'You Win!!!'
    when 'Draw'
      puts 'Draw!!!'
    when 'Lose'
      puts 'Lose!!!'
    end
    puts "HMAC key: #{@key.unpack1('H*')}"
  end
end

def print_help(message)
  puts 'Help:'
  puts "\tSuggestion: #{message}"
  puts "\truby janken.rb <Odd number of moves>"
end

moves = ARGV

if moves.empty?
  print_help 'Try with move names as command line arguments.'
  exit 1
end

if moves.length != moves.uniq.length
  print_help 'Try without duplicate.'
  exit 1
end

if moves.length.even?
  print_help 'Try with odd number of moves.'
  exit 2
end

game = JanKen.new(moves)
game.run
