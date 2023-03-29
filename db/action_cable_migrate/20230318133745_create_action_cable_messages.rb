class CreateActionCableMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.string :channel
      t.blob   :message
    end
  end
end
