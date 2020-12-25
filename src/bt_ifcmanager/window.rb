#  window.rb
#
#  Copyright 2017 Jan Brouwer <jan@brewsky.nl>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#
# IFC properties window

require 'yaml'

module BimTools::IfcManager
  require File.join(PLUGIN_PATH, 'observers.rb')
  require File.join(PLUGIN_PATH_UI, 'html.rb')
  require File.join(PLUGIN_PATH_UI, 'title.rb')
  require File.join(PLUGIN_PATH_UI, 'input_name.rb')
  require File.join(PLUGIN_PATH_UI, 'select.rb')
  require File.join(PLUGIN_PATH_UI, 'select_classifications.rb')
  require File.join(PLUGIN_PATH_UI, 'select_materials.rb')
  require File.join(PLUGIN_PATH_UI, 'select_layers.rb')

  module PropertiesWindow
    attr_reader :window, :ready
    extend self
    @window = false
    @visible = false
    @ready = false
    @form_elements = Array.new
    @window_options = {
      :dialog_title    => 'Edit IFC properties',
      :preferences_key => 'BimTools-IfcManager-PropertiesWindow',
      :width           => 400,
      :height          => 400,
      :resizable       => true
    }
  
    # create observers for updating form elements content
    @observers = BimTools::IfcManager::Observers.new()

    # create Sketchup HtmlDialog window
    # needs to be recreated only when settings change
    def create()
      model = Sketchup.active_model
      selection = model.selection
      @form_elements = Array.new
      @window = UI::HtmlDialog.new( @window_options )
      @window.set_on_closed {
        @observers.stop
      }

      # Add title showing selected items
      @form_elements << Title.new(@window)

      # Add html select for classifications
      classification_list = {"IFC 2x3" => true}.merge!(Settings.classifications)
      classification_list.each_pair do | classification_name, active |
        if active
          classification = HtmlSelectClassifications.new(@window, classification_name)
          classification.options = YAML.load_file(File.join(PLUGIN_PATH, "classifications", classification_name + ".yml"))
          @form_elements << classification
        end
      end

      # Add html text input for component definition name
      @form_elements << HtmlInputName.new(@window)

      # Add html select for materials
      @form_elements << HtmlSelectMaterials.new(@window, "Material")

      # Add html select for layers
      @form_elements << HtmlSelectLayers.new(@window, "Tag/Layer")
    end # def create

    # close Sketchup HtmlDialog window
    def close
      @observers.stop
      if @window && @window.visible?
        @window.close
      end
    end # def close

    # show Sketchup HtmlDialog window
    def show
      unless @window
        self.create()
      end
      @observers.start
      self.set_html()
      unless @window.visible?
        @window.show
      end
    end # def show

    # toggle Sketchup HtmlDialog window visibility
    # close when visible, show otherwise
    def toggle
      if @window
        if@window.visible?
          self.close
        else
          self.show
        end
      else
        self.create()
        self.show
      end
    end # def toggle
    
    # Refresh entire window contents
    # triggered from show and close window
    def set_html()
      model = Sketchup.active_model
      ifc_able = false
      model.selection.each do |ent|
        if(ent.is_a?(Sketchup::ComponentInstance) || ent.is_a?(Sketchup::Group))
          ifc_able = true
          break
        end
      end
      html = html_header()
      @form_elements.each do |form_element|
        unless(ifc_able)
          form_element.hide()
        end
        html << form_element.html(model.selection)
      end
      js = ""
      @form_elements.each do |form_element|
        js << form_element.js
        js << form_element.onchange
      end
      html << html_footer(js)
      @window.set_html(html)
      set_callbacks()
    end

    def set_callbacks()
      @form_elements.each do |form_element|
        form_element.set_callback()
      end
    end
    
    # Update form elements content
    # triggered from observers on selection or object changes
    def update()
      model = Sketchup.active_model
      ifc_able = false
      model.selection.each do |ent|
        if(ent.is_a?(Sketchup::ComponentInstance) || ent.is_a?(Sketchup::Group))
          ifc_able = true
          break
        end
      end
      if ifc_able
        @form_elements.each do |form_element|
          form_element.update(model.selection)
          form_element.show()
        end
      else
        @form_elements.each do |form_element|
          form_element.update(model.selection)
          form_element.hide()
        end
      end
    end
  end
end