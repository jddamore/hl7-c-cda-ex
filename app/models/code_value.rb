class CodeValue < ActiveRecord::Base
  scope :by_code_table, lambda { |table_name| where code_table: table_name }
  scope :by_table_and_code, lambda { |table_name, code| where(code_table: table_name, code: code) }

  def self.table_code_list(table_name)
    self.by_code_table(table_name).collect { |row| row.code}
  end
end