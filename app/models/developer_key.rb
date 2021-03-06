#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class DeveloperKey < ActiveRecord::Base
  belongs_to :user
  belongs_to :account
  has_many :page_views
  has_many :access_tokens

  attr_accessible :api_key, :name
  
  before_create :generate_api_key
  
  def generate_api_key(overwrite=false)
    self.api_key = AutoHandle.generate(nil, 64) if overwrite || !self.api_key
  end
  
  def self.default
    get_special_key("User-Generated")
  end
  
  def self.get_special_key(default_key_name)
    @special_keys ||= {}

    if Rails.env.test?
      # TODO: we have to do this because tests run in transactions. maybe it'd
      # be good to create some sort of of memoize_if_safe method, that only
      # memoizes when we're caching classes and not in test mode? I dunno. But
      # this stinks.
      return @special_keys[default_key_name] = DeveloperKey.find_or_create_by_name(default_key_name)
    end

    key = @special_keys[default_key_name]
    return key if key
    if (key_id = Setting.get("#{default_key_name}_developer_key_id", nil)) && key_id.present?
      key = DeveloperKey.find_by_id(key_id)
    end
    return @special_keys[default_key_name] = key if key
    key = DeveloperKey.create!(:name => default_key_name)
    Setting.set("#{default_key_name}_developer_key_id", key.id)
    return @special_keys[default_key_name] = key
  end
end
