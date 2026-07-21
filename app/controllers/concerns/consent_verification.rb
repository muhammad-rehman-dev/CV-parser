# Shared handling of the processing-consent checkbox (CV upload + profile save).
module ConsentVerification
  extend ActiveSupport::Concern

  private

  def consent_given?
    ActiveModel::Type::Boolean.new.cast(params[:consent])
  end
end
