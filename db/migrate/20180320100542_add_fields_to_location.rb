class AddFieldsToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :image_url, :string
    add_column :locations, :average_time, :float
    add_column :locations, :rating, :integer
  end
end
