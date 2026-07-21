class CreateSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :settings do |t|
      t.string :key, null: false
      t.text :value
      t.string :value_type, null: false, default: "string"
      t.string :description

      t.timestamps
    end
    add_index :settings, :key, unique: true
  end
end
