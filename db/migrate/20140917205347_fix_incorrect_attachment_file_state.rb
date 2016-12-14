class FixIncorrectAttachmentFileState < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::FixIncorrectAttachmentFileState.send_later_if_production(:run)
  end

  def self.down
  end
end
