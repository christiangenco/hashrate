require 'json'
require 'pry'

# consolidate the json to just the dates the difficulty changed
data = JSON.parse(File.read('difficulties.json'))
@difficulties = []
data.values.first.each{|value|
  if @difficulties.empty? || @difficulties.last["y"] != value["y"]
    @difficulties << value
  end
}

# [{"x"=>1231006505, "y"=>1.0},
#  {"x"=>1231092905, "y"=>0.0},
#  {"x"=>1231524905, "y"=>1.0},
#  {"x"=>1262196905, "y"=>1.1828995343128408},
#  {"x"=>1263320105, "y"=>1.3050621315915245},
#  {"x"=>1264443305, "y"=>1.3442249707710294},
#  {"x"=>1265393705, "y"=>1.818648536145414},
#  {"x"=>1266257705, "y"=>2.527738215072359},
#  {"x"=>1267035305, "y"=>3.781179252033766},
#  {"x"=>1268072105, "y"=>4.531081750070693},
#  {"x"=>1269281705, "y"=>4.56516291033707},
#  {"x"=>1270145705, "y"=>6.085476906000794},
#  {"x"=>1271096105, "y"=>7.819796993353832},
#  {"x"=>1271960105, "y"=>11.464315805514119},
#  {"x"=>1272996905, "y"=>12.849183147823783}

def difficulty_index(time)
  i = -1
  t = 0
  while t <= time
    i += 1
    t = @difficulties[i]["x"]
  end

  i-1
end

def difficulty(time)
  @difficulties[difficulty_index(time)]
end

# p difficulty(1262196905+1) == {"x"=>1262196905, "y"=>1.1828995343128408}

# returns a set of points between, and including, start and stop
# filling in the values at start and stop so that you could sum the
# differences between the x values and it would == stop-start
def difficulties_between(start, stop)
  # puts "> difficulties_between(#{start}, #{stop})"

  start_i = difficulty_index(start)
  stop_i  = difficulty_index(stop)

  # print "start_i: "
  # p start_i
  # print "stop_i: "
  # p stop_i

  difficulties = @difficulties[start_i..stop_i]

  return [] if difficulties.empty?

  # clone the last entry with the `stop` x-value
  difficulties << {"x" => stop, "y" => difficulties.last["y"]}

  # bump up the first entry to `start`
  difficulties.first["x"] = start

  difficulties
end

# difficulties_between(1231524905+1, 1231524905+86400) == [{"x"=>1231524906, "y"=>1.0}, {"x"=>1231611305, "y"=>1.0}]

# difficulties_between(1231524905+1, 1262196905 + 1) == [{"x"=>1231524906, "y"=>1.0}, {"x"=>1262196905, "y"=>1.1828995343128408}, {"x"=>1262196906, "y"=>1.1828995343128408}]

exit

# returns the weighted average difficulty between start and stop
def average_difficulty(start, stop)
  difficulties = difficulties_between(start, stop)
  difficulty_time = 0

  puts "difficulties"
  p difficulties

  # jiggle the intervals with start, stop so we just create a sum
  difficulties.first["x"] = start
  difficulties << {
    "x" => stop,
    "y" => difficulties.last["y"]
  }

  0.upto(difficulties.size-2){|i|
    difficulty = difficulties[i]
    time = difficulties[i+1]["x"] - difficulty["x"]

    difficulty_time += difficulty["y"] * time
  }

  # multiply this by hashes and BTC_PER_BLOCK to get BTC earned
  # units are (block * seconds)/hash
  1.0/(difficulty_time * 2**32)
end

puts "======"
# p difficulty_time(1231006505+1, 1263320105-1)


# input: timespan, Hashes
# result: BTC earned
# uses constant 25BTC reward
BTC_PER_BLOCK = 25
def earning(start, stop, hashrate)
  # difficulty_time(start, stop) * hashrate * BTC_PER_BLOCK
end

# GH = 1e9
# MH = 1e6
p earning(1231524905, 1231524905+86400, 1 * 1e6)

# should be 502.9142, I think?

binding.pry

# Time.at(seconds_since_epoc_integer).to_datetime