require 'sequel'
Sequel.extension :migration
Sequel.extension :pg_hstore

DB ||= Sequel.connect(ENV["DATABASE_URL"])

class HealthReading

  def self.migration
    Sequel.migration do
      change do
        puts "HealthCache Migration Running..."
        
        run "CREATE EXTENSION hstore" 

        create_table(:health_readings) do
          primary_key :id
          String :repo
          DateTime :repo_created_at
          
          DateTime :health_reading_at
          Integer :health_reading_for_year
          Integer :health_reading_for_week

          String :overall_health
          Float :overall_health_score

          HStore :health_attributes
        end
      end
    end
  end

  def self.run_migration_up
    migration.apply(DB, :up)
  end

  def self.drop_table
    DB.drop_table(:health_readings)
  end

  def self.dataset
    DB[:health_readings]
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
