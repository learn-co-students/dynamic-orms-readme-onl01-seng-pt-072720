require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song


  def self.table_name
    self.to_s.downcase.pluralize   #takes the class (self) name and lowercases it and makes it plural to get the standard table name
  end

  def self.column_names
    DB[:conn].results_as_hash = true    #returns results from a SELECT statement as a hash with column names as keys instead of as the typical array.

    sql = "pragma table_info('#{table_name}')"      #Returns an array of hases that describes the table with lots of mostly useless data.

    table_info = DB[:conn].execute(sql)    #Creates a variable and sets it equal to the array of hashes returned by the PRAGMA statement above.
    column_names = []    #creates a variable and sets it equal to an empty array.
    table_info.each do |row|    #iterates over each hash in the array from the PRAGMA statement.
      column_names << row["name"]   #Populates the array created above with the values in the "name" key in each iteration through the hashes within the PRAGMA array.
    end
    column_names.compact   #compacts the array to remove any nil values.
  end

  self.column_names.each do |col_name|    #iterates over each value in the array populated above.
    attr_accessor col_name.to_sym         #converts each item in the array (the column name) into a symbol so it can be used as an attr_accessor.
  end

  def initialize(options={})            #This is an abstracted initialize method.
    options.each do |property, value|     #iterates over each item passed into the initialize method as key-value pair.
      self.send("#{property}=", value)    #send allows you to invoke a method by name and we passin the interpolated property(key) and then the value.
    end
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"   #abstract code for populating a table in a database.  Interpolates the returns from the methods below.
    DB[:conn].execute(sql)    #executes the sql statement above.
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]  #returns the last entered table item and assigns the PRIMARY KEY ID to the id attribute of the instance created.
  end

  def table_name_for_insert
    self.class.table_name      #table name is a class method so we must use self.class to call it since we are using table_names_for_insert within an instance.  Runs the method above to get the table name.
  end

  def values_for_insert
    values = []     #creates a new varable and sets it equal to an empty array.
    self.class.column_names.each do |col_name|    #Runs the class level method within the instance and iterates over each returned symbol from the method above.
      values << "'#{send(col_name)}'" unless send(col_name).nil?    #Populates the values array with the symbol unless the symbol is nil.
    end
    values.join(", ")   #seperates the elements in the values array out into a comma delimited format necessary to use in SQL.
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")    #Runs the class level method within the instance.  Removes the ID attribute because it needs to be handled by the database.
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"     #Abstract code to locate an objects name within any given table.
    DB[:conn].execute(sql)
  end

end
