require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song


  def self.table_name #finds the table name
    self.to_s.downcase.pluralize
  end

  def self.column_names #returns an array of col names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
  end

  self.column_names.each do |col_name| #metaprograms the attr_accessors
    attr_accessor col_name.to_sym
  end

  def initialize(options={}) #initialize doesnt explicitly name the arguments
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert #allows us to use class method inside a instance method  
    self.class.table_name
  end

  def values_for_insert 
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ") #have to structure it like SQL
  end

  def col_names_for_insert #removes the id column, then joins them the way you would when writing INSERT statements
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



