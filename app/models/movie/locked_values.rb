require 'mingo_set_property'

module Movie::LockedValues
  extend ActiveSupport::Concern

  included do
    extend Mingo::SetProperty
    property :locked_values, :type => :set
  end

  def update_and_lock(attributes)
    for field, value in attributes
      set_and_lock(field, value)
    end
  end

  private

  def set_and_lock(field, value)
    self.send("#{field}=", value.presence)
    lock_value field unless value.blank?
  end

  def set_unless_locked(field, value)
    self.send("#{field}=", value) unless locked_value?(field)
  end

  def lock_value(field)
    locked_values << field.to_s
  end

  def unlock_value(field)
    locked_values.delete field.to_s
  end

  def locked_value?(field)
    locked_values.include? field.to_s
  end
end
