class CreateIdealProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :ideal_products do |t|
      t.string :codigo
      t.string :nome
      t.string :preco
      t.boolean :grade

      t.timestamps
    end
  end
end
