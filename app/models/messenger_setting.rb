class MessengerSetting < ActiveRecord::Base
  belongs_to :project

  validates :messenger_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }

  def self.find_or_create(p_id)
    setting = MessengerSetting.find_by project_id: p_id
    unless setting
      setting = MessengerSetting.new
      setting.project_id = p_id
      setting.save!
    end

    setting
  end
end
