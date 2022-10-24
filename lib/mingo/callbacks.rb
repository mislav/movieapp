class Mingo
  module Callbacks
    def self.included(base)
      base.extend ActiveModel::Callbacks
      base.send :define_model_callbacks, :create, :save, :update, :destroy
    end

    def save(*args)
      run_callbacks(persisted? ? :update : :create) do
        run_callbacks(:save) do
          super
        end
      end
    end

    def destroy
      run_callbacks(:destroy) do
        super
      end
    end
  end
end
