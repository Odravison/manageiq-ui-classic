class PhysicalServerController < ApplicationController
  include Mixins::GenericListMixin
  include Mixins::GenericShowMixin

  before_action :check_privileges
  before_action :session_data
  after_action :cleanup_action
  after_action :set_session_data

  def self.table_name
    @table_name ||= "physical_servers"
  end

  def session_data
    @title  = _("Physical Servers")
    @layout = "physical_server"
    @lastaction = session[:physical_server_lastaction]
  end

  def collect_data(server_id)
    PhysicalServerService.new(server_id, self).all_data
  end

  def set_session_data
    session[:layout] = @layout
    session[:physical_server_lastaction] = @lastaction
  end

  def show_list
    # Disable the cache to prevent a caching problem that occurs when
    # pressing the browser's back arrow button to return to the show_list
    # page while on the Physical Server's show page. Disabling the cache
    # causes the page and its session variables to actually be reloaded.
    disable_client_cache

    process_show_list
  end

  # Handles buttons pressed on the toolbar
  def button
    # Get the list of servers to apply the action to
    servers = retrieve_servers

    # Apply the action (depending on the button pressed) to the servers
    apply_action_to_servers(servers)
  end

  private

  # Maps button actions to actual method names to be called and the
  # corresponding result status messages to be displayed
  ACTIONS = {"physical_server_power_on"         => [:power_on,         _("Power On")],
             "physical_server_power_off"        => [:power_off,        _("Power Off")],
             "physical_server_restart"          => [:restart,          _("Restart")],
             "physical_server_blink_loc_led"    => [:blink_loc_led,    _("Blink LED")],
             "physical_server_turn_on_loc_led"  => [:turn_on_loc_led,  _("Turn On LED")],
             "physical_server_turn_off_loc_led" => [:turn_off_loc_led, _("Turn Off LED")]}.freeze

  def textual_group_list
    [%i(properties), %i(relationships)]
  end
  helper_method :textual_group_list

  # Returns a list of servers to which the button action will be applied
  def retrieve_servers
    server_id = params[:id]
    servers = []

    # A list of servers
    if @lastaction == "show_list"
      #server_ids = find_checked_items
      #server_ids.each do |id|
        #servers.push(PhysicalServer.find_by('id' => id))
      #end
      Rbac.filtered(PhysicalServer.where(:id => find_checked_items))
      if server_ids.empty?
				msg = _("No server IDs found for the selected servers")
        render_flash(msg, :error)
      end
    # A single server
    elsif server_id.nil? || PhysicalServer.find_by('id' => server_id).nil?
			msg = _("No server ID found for the current server")
      render_flash(msg, :error)
    else
      servers.push(PhysicalServer.find_by('id' => server_id))
    end

    servers
  end

  # Applies the appropriate action to a list of servers depending
  # on the button pressed
  def apply_action_to_servers(servers)
    button_pressed = params[:pressed]

    # Apply the appropriate action to each server
    if ACTIONS.key?(button_pressed)
      method = ACTIONS[button_pressed][0]
      action_str = ACTIONS[button_pressed][1]
      servers.each do |server|
        server.send(method)
      end
      msg = _("Successfully initiated the #{action_str} action")
      render_flash(msg, :success)
    else
			msg = _("Unknown action: #{button_pressed}")
      render_flash(msg, :error)
    end
  end
end
