# -*- encoding : utf-8 -*-
# See `http://alaveteli.org/docs/customising/themes/#customising-the-request-states`
# for more explanation of this file

module InfoRequestCustomStates

  def self.included(base)
    base.extend(ClassMethods)
  end

  # Work out what the situation of the request is. In addition to
  # values of self.described_state, in base Alaveteli can return
  # these (calculated) values:
  #   waiting_classification
  #   waiting_response_overdue
  #   waiting_response_very_overdue
  def theme_calculate_status
    if self.described_state == 'extension' 
      return 'extension'  if Time.zone.now.strftime("%Y-%m-%d") < self.calculate_date_extension_after.strftime("%Y-%m-%d")
      return 'waiting_response_very_overdue'
    end
    self.base_calculate_status
  end

  def calculate_date_extension_after
    Holiday.due_date_from(date_initial_request_last_sent_at,
                          EXTENSION_STATE_DAYS,
                          AlaveteliConfiguration.working_or_calendar_days)
  end

  # Mixin methods for InfoRequest
  module ClassMethods

    # Return the name of a custom status.
    # Example of how to add a custom status:
    # def theme_display_status(status)
    #     if status == 'transferred'
    #         _("Transferred.")
    #     else
    #         raise _("unknown status ") + status
    #     end
    # end
    def theme_display_status(status)
      if status == 'transferred'
        _("Transferred.")
      elsif status == 'extension'
        _("Extension")
      elsif status == 'extended'
        _("Extended")
      else
        raise _("unknown status ") + status
      end
    end

    # Return the list of custom statuses added by the theme.
    # Example of how to add a custom status:
    # def theme_extra_states
    #     return ['transferred']
    # end
    def theme_extra_states
      return ['transferred', 'extension', 'extended']
    end

  end
end

module RequestControllerCustomStates

  # `theme_describe_state` is called after the core describe_state code.
  # It should end by raising an error if the status is unknown.
  # Example of how to add a custom status:
  # def theme_describe_state(info_request)
  #   if info_request.calculate_status == 'transferred'
  #     flash[:notice] = _("Authority has transferred your request to a different public body.")
  #       redirect_to request_url(@info_request)
  #   else
  #     raise "unknown calculate_status " + info_request.calculate_status
  #   end
  # end
  def theme_describe_state(info_request)
    if info_request.calculate_status == 'extension'
      flash[:notice] = _("Request due date extended")
      redirect_to request_url(@info_request)
    else
      raise "unknown calculate_status " + info_request.calculate_status
    end
  end

end
