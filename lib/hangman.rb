
class Hangman
  require 'byebug'

  attr_reader :guesser, :referee, :board

  def initialize(players = {})
    @guesser = players[:guesser]
    @referee = players[:referee]
  end

  def setup
    length = referee.pick_secret_word
    guesser.register_secret_length(length)
    @board = Array.new(length) { "_" }
    display_board
  end

  def take_turn
    guessed_letter = guesser.guess(board)
    correct_indices = referee.check_guess(guessed_letter)
    update_board(guessed_letter, correct_indices)
    guesser.handle_response(guessed_letter, correct_indices)
    display_board
  end

  def play
    setup
    take_turn until won?
    puts "Congratulations - you guessed the secret word!"
  end

  def won?
    board.none? { |letter| letter == "_" }
  end

  def update_board(letter, indices)
    indices.each { |el| @board[el] = letter }
  end

  def display_board
    puts "Secret word: #{board.join("")}"
  end
end

class HumanPlayer
  attr_accessor :dictionary, :secret_word, :guessed_letters

  def initialize
    @guessed_letters = []
  end

  def pick_secret_word
    puts "What is the length of your secret word? Input a number"
    length = gets.chomp
    length.to_i
  end

  def check_guess(letter)
    puts letter
    puts "Where does your letter appear? e.g. 1, 2, 5"
    puts "Otherwise, if the letter is not in your word simply type 'n'"
    indices = []
    input = gets.chomp
    if input == "n"
      return indices
    else
      indices = input.split(", ").map(&:to_i)
      indices.map! { |num| num - 1 }
    end

    indices
  end

  def register_secret_length(length)
    puts "The secret word has length #{length}"
  end

  def guess(board)
    puts "Please guess a letter"
    guess = gets.chomp
    process_guess(guess, board)
  end

  def process_guess(guess, board)
    unless @guessed_letters.include?(guess)
      @guessed_letters << guess
      return guess
    else
      puts "Letter already guessed, please choose a different letter"
      guess(board)
    end
  end

  def handle_response(letter, indices)
  end
end

class ComputerPlayer
  attr_accessor :dictionary, :secret_word

  def self.read_dictionary
    File.readlines("dictionary.txt").map(&:chomp)
  end

  def initialize(dictionary = File.readlines("dictionary.txt").map(&:chomp))
    @dictionary = dictionary
  end

  def pick_secret_word
    @secret_word = dictionary.sample
    @secret_word.delete!("\n")
    @secret_word.length
  end

  def check_guess(letter)
    indices = []
    @secret_word.each_char.with_index do |el, index|
      indices << index if el == letter
    end

    indices
  end

  def register_secret_length(length)
    @candidate_words = @dictionary.select { |word| word.length ==
                                                          length }
  end

  def guess(board)
    letters = ("a".."z").to_a
    letter_count = Hash.new(0)
    candidate_words.each do |word|
      word.each_char { |char| letter_count[char] += 1 unless
                                        board.include?(char)}
    end
    highest_count = letter_count.values.sort[-1]
    letter_count.each do |letter, count|
      if count == highest_count
        return letter
      end
    end
  end

  def handle_response(letter, indices)

    if indices.length == 0
      candidate_words.reject! { |word| word.include?(letter) }
    else
      candidate_words.reject! do |word|
        indices.any? { |i| word[i] != letter}
      end
      candidate_words.reject! do |word|
       chars = word.chars
       chars.each_index.any? do |i|
         chars[i] == letter && !indices.include?(i)
       end
      end
    end
  end

  def candidate_words
    @candidate_words
  end
end

if __FILE__ == $PROGRAM_NAME
  dictionary = ComputerPlayer.read_dictionary
  players = {
    referee: HumanPlayer.new,
    guesser: ComputerPlayer.new
  }
  game = Hangman.new(players)
  game.play
end
