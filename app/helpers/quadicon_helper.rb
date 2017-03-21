module QuadiconHelper
  # Refactoring phase 1
  # * Add tests
  # * Move configuration up and out
  # * Try to reveal more intention in conditionals
  # * Extract smaller methods from large methods

  # Collect and normalize global, environment state

  # @settings and `settings` method
  # @listicon
  # @embedded
  # @showlinks
  # @policy_sim
  # @explorer
  # @view.db
  # @parent
  # @lastaction
  # session[:policies]
  # request.parameters[:controller]

  def quadicon_truncate_mode
    @settings.fetch_path(:display, :quad_truncate) || 'm'
  end

  def listicon_nil?
    @listicon.nil?
  end

  def quadicon_vm_attributes(item)
    vm_quad_link_attributes(item)
  end

  def quadicon_vm_attributes_present?(item)
    quadicon_vm_attributes(item) && !quadicon_vm_attributes(item).empty?
  end

  def quadicon_in_embedded_view?
    !!@embedded
  end

  def quadicon_show_link_ivar?
    !!@showlinks
  end

  def quadicon_hide_links?
    !quadicon_show_links?
  end

  def quadicon_show_links?
    !quadicon_in_embedded_view? || quadicon_show_link_ivar?
  end

  def quadicon_show_url?
    !@quadicon_no_url
  end

  def quadicon_policy_sim?
    !!@policy_sim
  end

  def quadicon_lastaction_is_policy_sim?
    @lastaction == "policy_sim"
  end

  def quadicon_in_explorer_view?
    !!@explorer
  end

  def quadicon_policies_are_set?
    !session[:policies].empty?
  end

  def quadicon_in_service_controller?
    request.parameters[:controller] == "service"
  end

  def quadicon_view_db_is_vm?
    @view.db == "Vm"
  end

  def quadicon_service_ctrlr_and_vm_view_db?
    quadicon_in_service_controller? && quadicon_view_db_is_vm?
  end

  def quadicon_render_for_policy_sim?
    quadicon_policy_sim? && quadicon_policies_are_set?
  end

  def quadicon_edit_key?(key)
    !!(@edit && @edit[key])
  end

  #
  # Ways of Building URLs
  # Collect here to see if any can be eliminated
  #

  # def quadicon_url_for_record(item)
  #   url_for_record(item)
  # end

  # Replaces url options where private controller method was called
  # Pretty sure this is unnecessary as list_row_id just returns a cid.
  #
  # Currently can't use `url_for_record` because it attempts to guess the
  # controller and guesses incorrectly for some situations.
  #
  def quadicon_url_to_xshow_from_cid(item, options = {})
    # Previously: {:action => 'x_show', :id => controller.send(:list_row_id, item)}
    {:action => 'x_show', :id => to_cid(item.id) || options[:x_show_id]}
  end

  # Currently only used once
  #
  def quadicon_url_with_parent_and_lastaction(item)
    url_for_only_path(
      :controller => @parent.class.base_class.to_s.underscore,
      :action     => @lastaction,
      :id         => @parent.id,
      :show       => item.id
    )
  end

  # Normalize default options

  def quadicon_default_inline_styles(height: 80)
    [
      "margin-left: auto",
      "margin-right: auto",
      "width: 75px",
      "height: #{height}px",
      "z-index: 0"
    ].join("; ")
  end

  def render_quadicon(item, options = {})
    return unless item

    tag_options = {
      :id => "quadicon_#{item.id}"
    }

    if options[:typ] == :listnav
      tag_options[:style] = quadicon_default_inline_styles
      tag_options[:class] = ""
    end

    quadicon_tag(tag_options) do
      quadicon_builder_factory(item, options)
    end
  end

  def img_for_physical_vendor(item)
    "svg/vendor-#{h(item.label_for_vendor.downcase)}.svg"
  end

  # FIXME: Even better would be to ask the object what method to use
  def quadicon_builder_factory(item, options)
    case quadicon_builder_name_from(item)
    when 'service', 'service_template', 'service_ansible_tower', 'service_template_ansible_tower'
      render_service_quadicon(item, options)
    when 'resource_pool'         then render_resource_pool_quadicon(item, options)
    when 'host'                  then render_host_quadicon(item, options)
    when 'ext_management_system' then render_ext_management_system_quadicon(item, options)
    when 'ems_cluster'           then render_ems_cluster_quadicon(item, options)
    when 'single_quad'           then render_single_quad_quadicon(item, options)
    when 'storage'               then render_storage_quadicon(item, options)
    when 'vm_or_template'        then render_vm_or_template_quadicon(item, options)
    when 'physical_server'       then render_physical_server_quadicon(item, options)
    else
      raise "unknown quadicon kind - #{quadicon_builder_name_from(item)}"
    end
  end

  def quadicon_tag(options = {}, &block)
    options = {:class => "quadicon"}.merge!(options)
    content_tag(:div, options, &block)
  end

  def img_for_compliance(item)
    case item.passes_profiles?(session[:policies].keys)
    when true  then '100/check.png'
    when 'N/A' then '100/na.png'
    else            '100/x.png'
    end
  end

  def img_for_vendor(item)
    "svg/vendor-#{h(item.vendor)}.svg"
  end

  def img_for_host_vendor(item)
    "svg/vendor-#{h(item.vmm_vendor_display.downcase)}.svg"
  end

  def img_for_auth_status(item)
    case item.authentication_status
    when "Invalid" then "100/x.png"
    when "Valid"   then "100/checkmark.png"
    when "None"    then "100/unknown.png"
    else                "100/exclamationpoint.png"
    end
  end

  def render_quadicon_text(item, row)
    render_quadicon_label(item, row)
  end

  def render_quadicon_label(item, row)
    return unless item

    content = quadicon_label_content(item, row)
    opts    = quadicon_build_label_options(item, row)

    if quadicon_hide_links?
      content_tag(:span, content, opts[:options])
    else
      url = quadicon_build_label_url(item, row)
      quadicon_link_to(url, **opts) { content }
    end
  end

  # Renders a quadicon for PhysicalServer
  #
  def render_physical_server_quadicon(item, options)
    output = []
    if settings(:quadicons, :physical_server)
      output << flobj_img_simple("layout/base.png")

      output << flobj_p_simple("a72", (item.host ? 1 : 0))
      output << flobj_img_simple("svg/currentstate-#{h(item.power_state.downcase)}.svg", "b72")
      output << flobj_img_simple(img_for_physical_vendor(item), "c72")
      output << flobj_img_simple(img_for_health_state(item), "d72")
      output << flobj_img_simple('100/shield.png', "g72") unless item.get_policies.empty?
    else
      output << flobj_img_simple(size)
      output << flobj_img_simple(width * 1.8, img_for_physical_vendor(item), "e72")
    end

    if options[:typ] == :listnav
      # Listnav, no href needed
      output << content_tag(:div, :class => 'flobj') do
        tag(:img, :src => ActionController::Base.helpers.image_path("layout/reflection.png"), :border => 0)
      end
    else
      href = if quadicon_show_links?
               quadicon_edit_key?(:hostitems) ? "/physical_server/edit/?selected_physical_server=#{item.id}" : url_for_record(item)
             end

      output << content_tag(:div, :class => 'flobj') do
        title = _("Name: %{name} ") % {:name => h(item.name)}

        link_to(href, :title => title) do
          quadicon_reflection_img
        end
      end
    end
    # TODO(odravison): rubocop saying that is risky use html_safe
    # to use instead safe_join or others Rails tag helpers.
    output.collect(&:html_safe).join('').html_safe
  end

  # FIXME: Even better would be to ask the object what name to use
  def quadicon_label_content(item, row, truncate: true)
    return item.address if item.kind_of? FloatingIp

    key = case quadicon_model_name(item)
          when "ConfiguredSystem"     then "hostname"
          when "ServiceResource"      then "resource_name"
          when "ConfigurationProfile" then "description"
          when "EmsCluster"           then "v_qualified_desc"
          else
            %w(evm_display_name key name).detect { |k| row[k] }
          end

    if truncate
      truncate_for_quad(row[key], :mode => quadicon_truncate_mode)
    else
      row[key]
    end
  end

  def quadicon_build_label_url(item, row)
    if quadicon_in_explorer_view?
      quadicon_build_explorer_url(item, row)
    else
      url_for_db(quadicon_model_name(item), "show", item)
    end
  end

  def quadicon_build_explorer_url(item, row)
    attrs = default_url_options

    if quadicon_service_ctrlr_and_vm_view_db?
      if quadicon_vm_attributes(item)
        attrs.merge!(quadicon_vm_attributes(item))
      end
    else
      attrs[:controller] = controller_name
      attrs[:action]  = 'x_show'
      attrs[:id]      = to_cid(row['id']) || row['x_show_id']
    end

    url_for_only_path(attrs)
  end

  def quadicon_build_label_options(item, row)
    link_options = {
      :options => {
        :title => quadicon_label_content(item, row, :truncate => false)
      }
    }

    if quadicon_render_for_policy_sim?
      link_options[:options][:title] = _("Show policy details for %{name}") % {:name => row['name']}
    end

    if quadicon_in_explorer_view?
      link_options[:sparkle] = true

      if quadicon_service_ctrlr_and_vm_view_db? && !quadicon_vm_attributes_present?(item)
        link_options[:sparkle] = false
      end

      unless quadicon_service_ctrlr_and_vm_view_db?
        link_options[:remote] = true
      end
    end

    link_options
  end

  def quadicon_model_name(item)
    # Fix this with methods in these classes (if necessary)
    if item.class.respond_to?(:db_name)
      item.class.db_name
    # FIXME: quadicon_model_name() and url_for_record() need to be unified, since both do basically the same thing
    elsif item.kind_of?(ManageIQ::Providers::EmbeddedAnsible::AutomationManager::Playbook)
      'ansible_playbook'
    elsif item.kind_of?(ManageIQ::Providers::EmbeddedAutomationManager::ConfigurationScriptSource)
      'ansible_repository'
    elsif item.kind_of?(ManageIQ::Providers::EmbeddedAutomationManager::Authentication)
      'ansible_credential'
    else
      item.class.base_model.name
    end
  end

  # Build a link with common quadicon options
  #
  def quadicon_link_to(url, sparkle: false, remote: false, options: {}, &block)
    return if url.nil? && !quadicon_show_url?
    if sparkle
      options["data-miq_sparkle_on"] = true
      options["data-miq_sparkle_off"] = true
    end

    if remote
      options[:remote] = true
      options["data-method"] = :post
    end

    link_to(url, options, &block)
  end

  # Build a reflection img with common options
  #
  def quadicon_reflection_img(options = {})
    path = options.delete(:path) || "layout/reflection.png"

    options = {
      :border => 0,
      :width  => 72,
      :height => 72,
    }.merge(options)

    image_tag(image_path(path), options)
  end

  CLASSLY_NAMED_ITEMS = %w(
    PhysicalServer
    EmsCluster
    ResourcePool
    Repository
    Service
    ServiceTemplate
    Storage
    ServiceAnsibleTower
    ServiceTemplateAnsibleTower
  ).freeze

  def quadicon_named_for_base_class?(item)
    %w(ExtManagementSystem Host PhysicalServer).include?(item.class.base_class.name)
  end

  def quadicon_named_for_base_model?(item)
    %w(VmOrTempalte PhysicalServer).include?(item.class.base_model.name)
  end
  def quadicon_builder_name_from(item)
    builder_name = if CLASSLY_NAMED_ITEMS.include?(item.class.name)
                     item.class.name.underscore
                   elsif quadicon_named_for_base_model?(item)
                     item.class.base_model.to_s.underscore
                   elsif item.kind_of?(ManageIQ::Providers::ConfigurationManager)
                     "single_quad"
                   elsif quadicon_named_for_base_class?(item)
                     item.class.base_class.name.underscore
                   else
                     # All other models that only need single large icon and use name for hover text
                     "single_quad"
                   end
    builder_name = 'vm_or_template' if %w(miq_template vm).include?(builder_name)
    builder_name
  end

  # Truncate text to fit below a quad icon
  # mode originally from @settings.fetch_path(:display, :quad_truncate)
  #
  def truncate_for_quad(value, mode: 'm', trunc_to: 10, trunc_at: 13)
    return value.to_s if value.to_s.length < trunc_at

    case mode
    when "b" then quadicon_truncate_back(value, trunc_to)
    when "f" then quadicon_truncate_front(value, trunc_to)
    else          quadicon_truncate_middle(value, trunc_to)
    end
  end

  def quadicon_truncate_back(value, trunc_to = 10)
    value.first(trunc_to) + "..."
  end

  def quadicon_truncate_front(value, trunc_to = 10)
    "..." + value.last(trunc_to)
  end

  def quadicon_truncate_middle(value, trunc_to = 10)
    value.first(trunc_to / 2) + "..." + value.last(trunc_to / 2)
  end

  def flobj_img_simple(image = nil, cls = '', size = 72)
    image ||= "layout/base-single.png"

    content_tag(:div, :class => "flobj #{cls}") do
      tag(:img, :border => 0, :src => ActionController::Base.helpers.image_path(image),
          :width => size, :height => size)
    end
  end

  def flobj_img_small(image = nil, cls = '')
    flobj_img_simple(image, cls, 64)
  end

  def flobj_p_simple(cls, text)
    content_tag(:div, :class => "flobj #{cls}") do
      content_tag(:p, text)
    end
  end

  # Renders a quadicon for service classes
  #
  def render_service_quadicon(item, options)
    output = []
    output << flobj_img_simple

    url = ""
    link_opts = {}

    if quadicon_show_links?
      url = quadicon_url_to_xshow_from_cid(item)
      link_opts = {:sparkle => true, :remote => true}
    end

    output << content_tag(:div, :class => "flobj e72") do
      quadicon_link_to(url, **link_opts) do
        quadicon_reflection_img(:path => item.decorate.listicon_image)
      end
    end

    output.collect(&:html_safe).join('').html_safe
  end

  # Renders a quadicon for resource_pools
  #
  def render_resource_pool_quadicon(item, options)
    img = item.vapp ? "100/vapp.png" : "100/resource_pool.png"
    output = []

    output << flobj_img_simple
    output << flobj_img_small(img, "e72")
    output << flobj_img_simple('100/shield.png', "g72") unless item.get_policies.empty?

    unless options[:typ] == :listnav
      # listnav, no clear image needed
      output << content_tag(:div, :class => "flobj") do
        url = quadicon_show_links? ? url_for_record(item) : ""

        link_to(url, :title => h(item.name)) do
          quadicon_reflection_img(:path => "layout/clearpix.gif")
        end
      end
    end
    output.collect(&:html_safe).join('').html_safe
  end

  # Renders a quadicon for hosts
  #
  def render_host_quadicon(item, options)
    output = []

    if settings(:quadicons, :host)
      output << flobj_img_simple("layout/base.png")

      output << flobj_p_simple("a72", item.vms.size)
      output << flobj_img_simple("svg/currentstate-#{h(item.normalized_state.downcase)}.svg", "b72")
      output << flobj_img_simple(img_for_host_vendor(item), "c72")
      output << flobj_img_simple(img_for_auth_status(item), "d72")
      output << flobj_img_simple('100/shield.png', "g72") unless item.get_policies.empty?
    else
      output << flobj_img_simple
      output << flobj_img_small(img_for_host_vendor(item), "e72")
    end

    if options[:typ] == :listnav
      # Listnav, no href needed
      output << content_tag(:div, :class => 'flobj') do
        tag(:img, :src => ActionController::Base.helpers.image_path("layout/reflection.png"), :border => 0)
      end
    else
      href = if quadicon_show_links?
               quadicon_edit_key?(:hostitems) ? "/host/edit/?selected_host=#{item.id}" : url_for_record(item)
             end

      output << content_tag(:div, :class => 'flobj') do
        title = _("Name: %{name} | Hostname: %{hostname}") % {:name => h(item.name), :hostname => h(item.hostname)}

        link_to(href, :title => title) do
          quadicon_reflection_img
        end
      end
    end
    output.collect(&:html_safe).join('').html_safe
  end

  # Renders a quadicon for ext_management_systems
  #
  def render_ext_management_system_quadicon(item, options)
    output = []
    if settings(:quadicons, db_for_quadicon)
      output << flobj_img_simple("layout/base.png")
      item_count = case item
                   when EmsPhysicalInfra then item.physical_servers.size
                   when EmsCloud         then item.total_vms
                   else
                     item.hosts.size
                   end
      output << flobj_p_simple("a72", item_count)
      output << flobj_p_simple("b72", item.total_miq_templates) if item.kind_of?(EmsCloud)
      output << flobj_img_simple("svg/vendor-#{h(item.image_name)}.svg", "c72")
      output << flobj_img_simple(img_for_auth_status(item), "d72")
      output << flobj_img_simple('100/shield.png', "g72") unless item.get_policies.empty?
    else
      output << flobj_img_simple("layout/base-single.png")
      output << flobj_img_small("svg/vendor-#{h(item.image_name)}.svg", "e72")
    end

    if options[:typ] == :listnav
      output << flobj_img_simple("layout/reflection.png")
    else
      output << content_tag(:div, :class => 'flobj') do
        title = _("Name: %{name} | Hostname: %{hostname} | Refresh Status: %{status}") %
          {:name     => h(item.name),
           :hostname => h(item.hostname),
           :status   => h(item.last_refresh_status.titleize)}

        link_to(url_for_record(item), :title => title) do
          quadicon_reflection_img
        end
      end
    end
    output.collect(&:html_safe).join('').html_safe
  end

  # Renders quadicon for ems_clusters
  #
  def render_ems_cluster_quadicon(item, options)
    output = []

    output << flobj_img_simple("layout/base-single.png")
    output << flobj_img_small("100/emscluster.png", "e72")
    output << flobj_img_simple("100/shield.png", "g72") unless item.get_policies.empty?

    unless options[:typ] == :listnav
      # Listnav, no clear image needed
      url = quadicon_show_links? ? url_for_record(item) : nil

      output << content_tag(:div, :class => 'flobj') do
        link_to(url, :title => h(item.v_qualified_desc)) do
          quadicon_reflection_img
        end
      end
    end
    output.collect(&:html_safe).join('').html_safe
  end

  def render_non_listicon_single_quadicon(item, options)
    output = []

    img_path = if item.decorate
                 item.decorate.try(:listicon_image)
               else
                 "100/#{item.class.base_class.to_s.underscore}.png"
               end

    output << flobj_img_simple("layout/base-single.png")
    output << flobj_img_simple(img_path, "e72")

    unless options[:typ] == :listnav
      name = item.name

      img_opts = {
        :title => h(name),
        :path  => "layout/clearpix.gif"
      }

      link_opts = {}

      url = ""

      if quadicon_show_links?
        if quadicon_in_explorer_view?
          img_opts.delete(:path)
          url = quadicon_url_to_xshow_from_cid(item, options)
          link_opts = {:sparkle => true, :remote => true}
        else
          url = url_for_record(item)
        end
      end

      output << content_tag(:div, :class => "flobj") do
        quadicon_link_to(url, **link_opts) do
          quadicon_reflection_img(img_opts)
        end
      end
    end

    output
  end

  def render_listicon_single_quadicon(item, options)
    output = []

    output << flobj_img_simple("layout/base-single.png")
    output << flobj_img_small("100/#{@listicon}.png", "e72")

    unless options[:typ] == :listnav
      title = case @listicon
              when "scan_history"
                item.started_on
              when "orchestration_stack_output", "output"
                item.key
              else
                item.try(:name)
              end

      url = nil

      if quadicon_show_links?
        url = quadicon_url_with_parent_and_lastaction(item)
      end

      output << content_tag(:div, :class => 'flobj') do
        link_to(url, :title => title) do
          quadicon_reflection_img
        end
      end
    end

    output
  end

  # Renders a single_quad uh, quadicon
  #
  def render_single_quad_quadicon(item, options)
    output =  if listicon_nil?
                render_non_listicon_single_quadicon(item, options)
              else
                render_listicon_single_quadicon(item, options)
              end

    output.collect(&:html_safe).join('').html_safe
  end

  def img_for_health_state(item)
    case item.health_state
    when "Valid"    then "100/healthstate-normal.png"
    when "Critical" then "svg/healthstate-critical.svg"
    when "None"     then "svg/healthstate-unknown.svg"
    when "Warning"  then "100/warning.png"
    end
  end

  # Renders a storage quadicon
  #
  def render_storage_quadicon(item, options)
    output = []

    if settings(:quadicons, :storage)
      output << flobj_img_simple("layout/base.png")
      output << flobj_img_simple("100/storagetype-#{item.store_type.nil? ? "unknown" : h(item.store_type.to_s.downcase)}.png", "a72")
      output << flobj_p_simple("b72", item.v_total_vms)
      output << flobj_p_simple("c72", item.v_total_hosts)

      space_percent = item.free_space_percent_of_total == 100 ? 20 : ((item.free_space_percent_of_total.to_i + 2) / 5.25).round
      output << flobj_img_simple("100/piecharts/datastore/#{h(space_percent)}.png", "d72")
    else
      space_percent = (item.used_space_percent_of_total.to_i + 9) / 10
      output << flobj_img_simple("layout/base-single.png")
      output << flobj_img_simple("100/datastore-#{h(space_percent)}.png", "e72")
    end

    if options[:typ] == :listnav
      output << flobj_img_simple("layout/reflection.png")
    else
      output << content_tag(:div, :class => 'flobj') do
        quadicon_link_to(quadicon_storage_url(item), **quadicon_storage_link_options) do
          quadicon_reflection_img(quadicon_storage_img_options(item))
        end
      end
    end

    output.collect(&:html_safe).join('').html_safe
  end

  def quadicon_storage_url(item)
    url = nil

    if quadicon_in_explorer_view? && quadicon_show_links?
      url = quadicon_url_to_xshow_from_cid(item)
    end

    if !quadicon_in_explorer_view? && quadicon_show_links?
      url = url_for_record(item)
    end

    url
  end

  def quadicon_storage_link_options
    opts = {}

    if quadicon_in_explorer_view? && quadicon_show_links?
      opts = {
        :sparkle => true,
        :remote  => true
      }
    end

    opts
  end

  def quadicon_storage_img_options(item)
    opts = {
      :title  => _("Name: %{name} | Datastore Type: %{storage_type}") % {:name => h(item.name), :storage_type => h(item.store_type)}
    }

    opts
  end

  # Renders a vm quadicon
  #
  def render_vm_or_template_quadicon(item, options)
    output = []

    if settings(:quadicons, item.class.base_model.name.underscore.to_sym)
      output << flobj_img_simple("layout/base.png")
      output << flobj_img_simple("svg/os-#{h(item.os_image_name.downcase)}.svg", "a72")
      output << flobj_img_simple("svg/currentstate-#{h(item.normalized_state.downcase)}.svg", "b72")
      output << flobj_img_simple("svg/vendor-#{h(item.vendor.downcase)}.svg", "c72")

      unless item.get_policies.empty?
        output << flobj_img_simple("100/shield.png", "g72")
      end

      if quadicon_policy_sim? && !session[:policies].empty? && quadicon_lastaction_is_policy_sim?
        output << flobj_img_simple(img_for_compliance(item), "d72")
      end

      unless quadicon_lastaction_is_policy_sim?
        output << flobj_p_simple("d72", h(item.v_total_snapshots))
      end
    else
      output << flobj_img_simple("layout/base-single.png")

      if quadicon_policy_sim? && !session[:policies].empty?
        output << flobj_img_small(img_for_compliance(item), "e72")
      end

      output << flobj_img_small(img_for_vendor(item), "e72")
    end

    unless options[:typ] == :listnav
      output << content_tag(:div, :class => 'flobj') do
        quadicon_link_to(quadicon_vt_url(item), **quadicon_vt_link_options) do
          quadicon_reflection_img(quadicon_vt_img_options(item))
        end
      end
    end
    output.collect(&:html_safe).join('').html_safe
  end

  def quadicon_vt_img_link(item)
    quadicon_link_to(quadicon_vt_url(item), **quadicon_vt_link_options) do
      quadicon_reflection_img(quadicon_vt_img_options(item))
    end
  end

  def quadicon_vt_url(item)
    url = nil # inferred by default

    if quadicon_show_links? && quadicon_in_explorer_view? &&
       quadicon_service_ctrlr_and_vm_view_db?

      url = if quadicon_vm_attributes_present?(item)
              quadicon_vm_attributes(item).slice(:controller, :action, :id)
            else
              ''
            end
    end

    if quadicon_show_links? && !quadicon_service_ctrlr_and_vm_view_db?
      url = url_for_record(item)
    end

    if quadicon_hide_links? && quadicon_policy_sim?
      url = url_for_record(item, "policies")
    end

    url
  end

  def quadicon_vt_img_options(item)
    options = {
      :title  => item.name
    }

    if quadicon_hide_links? && quadicon_policy_sim? && !quadicon_edit_key?(:explorer)
      options = {:title => _("Show policy details for %{item_name}") % {:item_name => h(item.name)}}
    end

    options
  end

  def quadicon_vt_link_options
    options = {}

    if (quadicon_show_links? && quadicon_in_explorer_view?) ||
       (quadicon_hide_links? && quadicon_policy_sim? && quadicon_edit_key?(:explorer))

      options = {
        :sparkle => true,
        :remote  => true
      }
    end

    if quadicon_show_links? && quadicon_in_explorer_view? &&
       quadicon_service_ctrlr_and_vm_view_db?

      options[:remote] = false
    end

    options
  end

  private

  def vm_quad_link_attributes(record)
    attributes = vm_cloud_attributes(record) if record.kind_of?(ManageIQ::Providers::CloudManager::Vm)
    attributes ||= vm_infra_attributes(record) if record.kind_of?(ManageIQ::Providers::InfraManager::Vm)
    attributes
  end

  def vm_cloud_attributes(record)
    attributes = vm_cloud_explorer_accords_attributes(record)
    attributes ||= service_workload_attributes(record)
    attributes
  end

  def vm_infra_attributes(record)
    attributes = vm_infra_explorer_accords_attributes(record)
    attributes ||= service_workload_attributes(record)
    attributes
  end

  def vm_cloud_explorer_accords_attributes(record)
    if role_allows?(:feature => 'instances_accord') || role_allows?(:feature => 'instances_filter_accord')
      attributes = {}
      attributes[:link] = true
      attributes[:controller] = 'vm_cloud'
      attributes[:action] = 'show'
      attributes[:id] = record.id
    end
    attributes
  end

  def vm_infra_explorer_accords_attributes(record)
    if role_allows?(:feature => 'vandt_accord') || role_allows?(:feature => 'vms_filter_accord')
      attributes = {}
      attributes[:link] = true
      attributes[:controller] = 'vm_infra'
      attributes[:action] = 'show'
      attributes[:id] = record.id
    end
    attributes
  end

  def service_workload_attributes(record)
    attributes = {}
    if role_allows?(:feature => 'vms_instances_filter_accord')
      attributes[:link] = true
      attributes[:controller] = 'vm_or_template'
      attributes[:action] = 'explorer'
      attributes[:id] = "v-#{record.id}"
    end
    attributes
  end
end
