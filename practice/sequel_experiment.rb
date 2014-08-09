require 'sequel'

Sequel.extension :migration

# DB = Sequel.sqlite # memory database

DB = Sequel.connect(ENV["DATABASE_URL"])

migration = Sequel.migration do
  change do
    puts "Migration Running..."
    create_table(:items) do
      primary_key :id
      String :name
      Float :price
    end
  end
end

items = DB[:items]

begin
  # Check for DB
  items.first
  puts "Items dataset exists"

rescue # TODO: Be more specific about which error to catch
  puts "Rescued"

  puts migration.apply(DB, :up)
end

puts items

# Populate the table
items.insert(:name => 'abc', :price => rand * 100)
items.insert(:name => 'def', :price => rand * 100)
items.insert(:name => 'ghi', :price => rand * 100)

# Print out the number of records
puts "Item count: #{items.count}"

# Print out the average price
puts "The average price is: #{items.avg(:price)}"

puts items.where(:name => 'def').first[:price]
