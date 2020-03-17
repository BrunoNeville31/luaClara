class CreatePhotos < ActiveRecord::Migration[5.1]
  def change
    create_table :photos do |t|
      t.binary :photo
      t.string :code_image

      t.timestamps
    end
  end
end
