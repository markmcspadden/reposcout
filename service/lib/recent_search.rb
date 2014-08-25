require 'sequel'
Sequel.extension :migration

DB ||= Sequel.connect(ENV["DATABASE_URL"])

class RecentSearch

  def self.migration
    Sequel.migration do
      change do
        puts "RecentSearch Migration Running..."

        create_table(:recent_searches) do
          primary_key :id
          String :repo
          DateTime :created_at
        end
      end
    end
  end

  def self.run_migration_up
    migration.apply(DB, :up)
  end

  def self.drop_table
    DB.drop_table(:recent_searches)
  end

  def self.dataset
    DB[:recent_searches]
  end

end



# begin
#   # Check for DB
#   items.first
#   puts "Items dataset exists"

# rescue # TODO: Be more specific about which error to catch
#   puts "Rescued"

#   puts migration.apply(DB, :up)
# end

# puts items

# # Populate the table
# items.insert(:name => 'abc', :price => rand * 100)
# items.insert(:name => 'def', :price => rand * 100)
# items.insert(:name => 'ghi', :price => rand * 100)

# # Print out the number of records
# puts "Item count: #{items.count}"

# # Print out the average price
# puts "The average price is: #{items.avg(:price)}"

# puts items.where(:name => 'def').first[:price]
