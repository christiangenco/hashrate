require 'json'
# require 'pry'
require 'linefit'
require 'open-uri'

class Hashrate
  BTC_PER_BLOCK = 25
  MH = 1e6
  GH = 1e9
  TH = 1e12

  # input: timespan, Hashes
  # result: BTC earned
  # uses constant 25BTC reward
  def self.earning(start, stop, hashrate)
    # make sure this is loaded before doing anything else
    # (mmmm, spaghetti)
    self.get_difficulties

    # ensure start and stop are in the right format and order
    start, stop = [start, stop].map{|t|
      # convert datetime to time
      t = t.to_time if t.respond_to? :to_time

      # convert time to unix timestamp
      t.to_i
    }.sort

    difficulty = self.average_difficulty(start, stop)
    puts "difficulty: #{difficulty}"
    puts "time: #{(stop-start)}"

    # time to find one share between start and stop (in seconds)
    # with your hashrate
    time_for_one_share = (difficulty * 2**32 / hashrate)

    # number of shares we'll find in (stop-start) time
    expected_shares = (stop-start) / time_for_one_share

    # difficulty_time(start, stop) * hashrate * BTC_PER_BLOCK
    # btc_per_second = average_difficulty(start, stop) * BTC_PER_BLOCK / hashrate

    expected_shares * self::BTC_PER_BLOCK
  end

  private

  def self.get_difficulties
    # if the data hasn't been fetched
    # or the last time it was fetched is > 6 hours ago
    # re-download the data
    # (best used in Rails production mode when object
    # instances are persistant)

    if (defined?(@@data)).nil? || 
      (defined?(@@difficulties)).nil? ||
      (defined?(@@difficulties_updated)).nil? ||
      (Time.now.to_i - @@difficulties_updated) > 60 * 60 * 6

      url = "https://blockchain.info/charts/difficulty?showDataPoints=false&timespan=all&show_header=true&daysAverageString=1&scale=0&format=json&address="

      # consolidate the json to just the dates the difficulty changed
      # data = JSON.parse(File.read('difficulties.json'))
      @@data = JSON.parse(open(url).read)
      @@difficulties = []
      @@data.values.first.each{|value|
        if @@difficulties.empty? || @@difficulties.last["y"] != value["y"]
          @@difficulties << value
        end
      }

      # add 24 months in the future based on the last 12 months
      @@difficulties += extrapolate(24, 12)

      @@difficulties_updated = Time.now.to_i
    end

    @@difficulties
  end

  # the actual or expected (if in the future)
  # difficulty at the unix timestamp time
  def self.difficulty(time)
    self.get_difficulties[difficulty_index(time)]
  end

  # returns the weighted average difficulty between start and stop
  def self.average_difficulty(start, stop)
    # puts "> average_difficulty(#{start}, #{stop})"

    difficulties = self.difficulties_between(start, stop)
    
    # print "difficulties: "
    # p difficulties

    total = 0

    0.upto(difficulties.size-2){|i|
      difficulty = difficulties[i]
      time = difficulties[i+1]["x"] - difficulty["x"]

      total += difficulty["y"] * time
    }

    # return the average
    total / (stop - start)
  end


  def self.extrapolate(months_ahead=6, months_ago=12)
    # add in expected future values for the next 6 months
    # based on the last 12 months
    index = difficulty_index(Time.new.to_i - 60 * 60 * 24 * 30 * months_ago)
    past = @@difficulties[index..-1]
    x = past.map{|o| o["x"]}
    y = past.map{|o| Math.log2 o["y"]}

    lineFit = LineFit.new
    lineFit.setData(x,y)

    intercept, slope = lineFit.coefficients

    # def y(x)
    #   2 ** (@slope * x + @intercept)
    # end

    # {
    #   intercept: intercept,
    #   slope: slope,
    #   rSquared: lineFit.rSquared,
    #   meanSqError: lineFit.meanSqError
    # }

    # calculate average interval
    intervals = []
    0.upto(past.size-2){|i|
      intervals << past[i+1]["x"] - past[i]["x"]
    }
    average_interval = intervals.inject{|a,b| a+b}/intervals.size
    puts "average: #{average_interval}"

    difficulties = []

    t = past.last["x"]
    future_date = t + 60 * 60 * 24 * 30 * months_ahead
    while t < future_date
      difficulties << {
        "x" => t,
        "y" => 2 ** (slope * t + intercept) # y(t)
      }
      t += average_interval
    end

    difficulties
  end

  def self.difficulty_index(time)
    i = -1
    t = 0
    while t <= time
      i += 1
      t = @@difficulties[i]["x"]
    end

    i-1
  end

  # returns a set of points between, and including, start and stop
  # filling in the values at start and stop so that you could sum the
  # differences between the x values and it would == stop-start
  def self.difficulties_between(start, stop)
    # puts "> difficulties_between(#{start}, #{stop})"

    start_i = self.difficulty_index(start)
    stop_i  = self.difficulty_index(stop)

    # print "start_i: "
    # p start_i
    # print "stop_i: "
    # p stop_i

    difficulties = self.get_difficulties[start_i..stop_i]

    return [] if difficulties.empty?

    # clone the last entry with the `stop` x-value
    difficulties << {"x" => stop, "y" => difficulties.last["y"]}

    # bump up the first entry to `start`
    difficulties.first["x"] = start

    difficulties
  end
  
end


# binding.pry

# exit



# difficulties_between(1231524905+1, 1231524905+86400) == [{"x"=>1231524906, "y"=>1.0}, {"x"=>1231611305, "y"=>1.0}]

# difficulties_between(1231524905+1, 1262196905 + 1) == [{"x"=>1231524906, "y"=>1.0}, {"x"=>1262196905, "y"=>1.1828995343128408}, {"x"=>1262196906, "y"=>1.1828995343128408}]




# p average_difficulty(1231524905+1, 1231524905+86400) = 1.0

# p average_difficulty(1231524905+1, 1262196905 + 1) == 1.0000000059630783

# p average_difficulty(1231524905+1, 1263320105) == 1.0064611250566535




# double check here: http://www.bitcoinx.com/profit/
# difficulty: 1
# BTC/block: 25
# hash rate: 1 MH/s
# Coins per 24h at these conditions == 502.9142 BTC
# p earning(1231524905, 1231524905+86400, 1 * MH) == 502.9141902923584


# t = @difficulties[-2]["x"]

# t = 1287339305
# p Hashrate.earning(t - (60 * 60 * 24 * 30), t - 1, 1000 * Hashrate::GH)

# binding.pry



# should be 502.9142, I think?

# binding.pry

# Time.at(seconds_since_epoc_integer).to_datetime