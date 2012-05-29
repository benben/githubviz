class CreateRequest < ActiveRecord::Migration
  def self.up
    create_table :requests do |t|
      t.string :name
      t.string :content_type
      t.text :content
      t.timestamps
    end
  end

  def self.down
    drop_table :requests
  end
end

