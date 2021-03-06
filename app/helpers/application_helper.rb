# Methods added to this helper will be available to all templates in the application.

# You can extend refinery with your own functions here and they will likely not get overriden in an update.
module ApplicationHelper

# -----------------------------------------------------------------------------  
# choose_body_floats -- dynamically choose float for body content sides of page
# this allows admin to change refinery setting (:gardenia_main_content_side)
# to make the sides switch selectable .. but that means we must dynamically 
# set the css float style for the sections
# -----------------------------------------------------------------------------  
  def choose_body_floats( section )
    main_is_left = (RefinerySetting.get(:gardenia_main_content_side) =~ /left/i)
    case section
      when :body_content_title,:body_content_left  then (main_is_left ? 'left' : 'right' )
      when :body_content_right then  (main_is_left ? 'right' : 'left' )
    else
      'right'
    end  # case
      
  end

# -----------------------------------------------------------------------------
# select_outer_div -- returns the outer div for properly selecting content sides of page
# -----------------------------------------------------------------------------  
  def select_outer_div( section )
    return "<div id = '#{section == :body_content_left ?  "main_content" : "sidebar_content" }' style = 'float: #{choose_body_floats( section )};'>"    
  end

# -----------------------------------------------------------------------------
# prep_dom_section -- prepatory stuff for an individual section; returns dom_id
# preps the fall back stuff
# ----------------------------------------------------------------------------- 
  def prep_dom_section(section, need_fallback )
    
       # actual rendering occurs here
    section[:html] = ( content_for( section[:yield] ) )
      
    if section[:html].blank? and need_fallback and
        section.keys.include?(:fallback) and
        section[:fallback].present?
        
      section[:html] = section[:fallback].to_s.html_safe
      
    end  # if

    return ( section[:id] ||= section[:yield].to_s.downcase.gsub(/\s+/,"_") )  # dom_id
  end
# -----------------------------------------------------------------------------  
# prepare_content_page -- replaces *ALL* the erb/haml code on shared/content_page
# args: assumed to be local variables prior to invoking the view?
# expected (from controller?)
#   @page
# RESULTS & SIDE EFFECTS:
#   @sections -- array of section hashes (used by calling view)
#   @class_list -- list of css classes required
# -----------------------------------------------------------------------------  
  def prepare_content_page(show_empty_sections, remove_automatic_sections , hide_sections)
  
    need_fallback = (!show_empty_sections and !remove_automatic_sections)
    empty_fill = ( RefinerySetting.get(:gardenia_parts_skip_empty) ? nil : "&nbsp;" )

    main_part = Page.default_parts.first
    sidebar_part = Page.default_parts.second
    
    # ***************************************************************************
    #   PART A --  BASIC PREPARATION of PAGE SECTIONS
    # ***************************************************************************
      # start off by defining the default sections and fallback content for each
    # since sidebar is special, its content cannot be nil (for main loop in PART B
    # to work correctly)
    @sections = [ 
        {:yield => :body_content_right, :fallback => (@page.present? ? @page.content_for(sidebar_part.to_sym) : nil )},
        {:yield => :body_content_title, :fallback => page_title, :id => 'body_content_page_title', :title => true},
        {:yield => :body_content_left, :fallback => (@page.present? ? @page.content_for(main_part.to_sym) : nil )},
      ]
    
      # remove any sections designated as hidden
    @sections.delete_if{ |section| hide_sections.include?( section[:yield] ) }
    
      # need any default sidebar boxes?; populate these too
    if @page.present? && !@page.parts.empty?
      
      sidebar_sections = @page.parts.inject([]) do |list, page_part|
        part = page_part.title
        if part == main_part || part == sidebar_part  # part already handled
          list
        else
          list << {:yield => part.to_sym, :fallback => @page.content_for(part.to_sym) }
        end
      end  # do each page part
        
        # remove any sections designated as hidden
      sidebar_sections.reject{ |section| hide_sections.include?( section[:yield] ) }
      
    else
      
      sidebar_sections = []   # no further sidebar sections
          
    end  # if..else for sidebars

    # ***************************************************************************
    #   PART B --  PER SECTION CONTENT POPULATION
    # ***************************************************************************
    css = []
  
    @sections.each do |section|

      dom_id = prep_dom_section(section, need_fallback )
      
         # sidebar part always is handled
      if  section[:yield] == :body_content_right || !section[:html].blank?  
      # see application_helper.rb for select_outer_div and choose_body_floats
    
        if section[:title]
          section[:html] = "<div id = 'body_content_title' style = 'float: #{choose_body_floats( section[:yield] )};'> <h1 id='#{dom_id}'>#{section[:html]}</h1> </div>"
        else
          section[:html] = "#{select_outer_div( section[:yield] )} <div class='clearfix' id='#{dom_id}'> #{section[:html]} #{( section[:yield] == :body_content_left && !@_page_image_gallery.blank? ? @_page_image_gallery : '' )} </div> "
          
            # if this is the sidebar area, then also insert subsidiary boxes to sidebar
          if section[:yield] == :body_content_right

            sidebar_sections.each do |sub_section|
              
              sub_dom_id = prep_dom_section(sub_section, need_fallback )
              sub_section[:html] = empty_fill if sub_section[:html].blank?

              unless sub_section[:html].blank?
                section[:html] << "<div class='sidebar_box clearfix' id='#{sub_dom_id}'>#{sub_section[:html]} </div> "
              end  # sub_section unless
            end  # each sub_section
          end # special sidebar handling
          
          section[:html] << "</div>" # attach trailing div closure
        end  # innermost unless .. else
        
      else
        css << "no_#{dom_id}"
      end  # outermost unless .. else
      
    end   # do each section
    
    @class_list = "clearfix#{" #{css.join(' ')}" if css.any?}"

  end


# -----------------------------------------------------------------------------  
# -----------------------------------------------------------------------------  
end # class helpers
