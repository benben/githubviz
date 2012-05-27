class CreateRequest < ActiveRecord::Migration
  def self.up
    create_table :requests do |t|
      t.string :type
      t.text :content
      t.timestamps
    end
  end

  def self.down
    drop_table :requests
  end
end

