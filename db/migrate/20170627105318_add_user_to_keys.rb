class AddUserToKeys < ActiveRecord::Migration[5.0]
  def change
    add_reference :keys, :user, foreign_key: true
  end
end
