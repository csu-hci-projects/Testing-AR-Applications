require 'csv'
require 'pry'

results = CSV.read("./results/5walls.csv")

feasible_count = 0
total = 0
conditions = [
  ["SELECT Wall 1", "SELECT Corner 1"],
  ["SELECT Wall 1", "SELECT Corner 3"],
  ["SELECT Wall 2", "SELECT Corner 2"],
  ["SELECT Wall 2", "SELECT Corner 1"],
  ["SELECT Wall 2", "SELECT Corner 5"],
  ["SELECT Wall 3", "SELECT Corner 2"],
  ["SELECT Wall 3", "SELECT Corner 4"],
  ["SELECT Wall 4", "SELECT Corner 3"],
  ["SELECT Wall 4", "SELECT Corner 4"],
  ["SELECT Wall 4", "SELECT Corner 6"],
  ["SELECT Wall 5", "SELECT Corner 5"],
  ["SELECT Wall 5", "SELECT Corner 6"]
]

# write to file
CSV.open("./results/5walls-feasible.csv", "w") do |c|
    results.each do |row|
      total += 1
      row[11] = true
      # A=0, B=1, C=2, D=3, E=4, F=5, G=6, H=7, I=8, J=9
      # check if wall in J
      conditions.each do |cond|
         before = row.index(cond[0])
         after = row.index(cond[1])
         if before > after
             row[11] = false
         end
      end
      if row[11] == true
        feasible_count += 1
        c << row
      end
    end
end

puts feasible_count
puts total
