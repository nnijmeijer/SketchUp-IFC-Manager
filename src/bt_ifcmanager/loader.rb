#  loader.rb
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
#

# Main loader for IfcManager plugin

# (!) Note: securerandom takes very long to load
require 'securerandom'

module BimTools  
  module IfcManager
  
    PLATFORM_IS_OSX     = ( Object::RUBY_PLATFORM =~ /darwin/i ) ? true : false
    PLATFORM_IS_WINDOWS = !PLATFORM_IS_OSX
    
    # set icon file type
    if Sketchup.version_number < 1600000000
      ICON_TYPE = '.png'
    elsif PLATFORM_IS_WINDOWS
      ICON_TYPE = '.svg'
    else # OSX
      ICON_TYPE = '.pdf'
    end
    
    attr_reader :toolbar

    extend self

    PLUGIN_PATH_IMAGE = File.join(PLUGIN_PATH, 'images')
    PLUGIN_PATH_CSS = File.join(PLUGIN_PATH, 'css')
    PLUGIN_PATH_LIB = File.join(PLUGIN_PATH, 'lib')
    PLUGIN_PATH_UI = File.join(PLUGIN_PATH, 'ui')
    PLUGIN_PATH_TOOLS = File.join(PLUGIN_PATH, 'tools')
    PLUGIN_PATH_CLASSIFICATIONS = File.join(PLUGIN_PATH, 'classifications')

    # Create IfcManager toolbar
    @toolbar = UI::Toolbar.new "IFC Manager"

    # Load settings from yaml file
    require File.join(PLUGIN_PATH, 'settings.rb')
    Settings.load()

    require File.join(PLUGIN_PATH, 'window.rb')
    require File.join(PLUGIN_PATH, 'export.rb')
    require File.join(PLUGIN_PATH_TOOLS, 'paint_properties.rb')
    require File.join(PLUGIN_PATH_TOOLS, 'create_component.rb')
    
    # add tools to toolbar  
    # Open window button
    btn_ifc_window = UI::Command.new('Show IFC properties') {
      PropertiesWindow.toggle
    }
    btn_ifc_window.small_icon = File.join(PLUGIN_PATH_IMAGE, "IfcEdit" << ICON_TYPE)
    btn_ifc_window.large_icon = File.join(PLUGIN_PATH_IMAGE, "IfcEdit" << ICON_TYPE)
    btn_ifc_window.tooltip = "Show IFC properties"
    btn_ifc_window.status_bar_text = "Edit IFC properties"

    @toolbar.add_item btn_ifc_window

    # IFC export button
    btn_ifc_export = UI::Command.new('Export model to IFC') {

      # get model current path
      model_path = Sketchup.active_model.path

      # get model file name
      if File.basename(model_path) == ""
        filename = "Untitled.ifc" # (?) translate?
      else
        filename = File.basename(model_path, ".*") << ".ifc"
      end

      # get model directory name
      dirname = File.dirname(model_path)

      # enter save path
      export_path = UI.savepanel('Export Model', dirname, filename)

      # only start export if path is valid
      unless export_path.nil?
        export( export_path )
      end
    }
    btn_ifc_export.small_icon = File.join(PLUGIN_PATH_IMAGE, "IfcExport" << ICON_TYPE)
    btn_ifc_export.large_icon = File.join(PLUGIN_PATH_IMAGE, "IfcExport" << ICON_TYPE)
    btn_ifc_export.tooltip = 'Export model to IFC'
    btn_ifc_export.status_bar_text = 'Export model to IFC'

    # Open settings window
    btn_settings_window = UI::Command.new("IFC Manager settings") {
      Settings.toggle
    }
    btn_settings_window.small_icon = File.join(PLUGIN_PATH_IMAGE, "settings" + ICON_TYPE)
    btn_settings_window.large_icon = File.join(PLUGIN_PATH_IMAGE, "settings" + ICON_TYPE)
    btn_settings_window.tooltip = "Open IFC Manager settings"
    btn_settings_window.status_bar_text = "Open IFC Manager settings"
    @toolbar.add_item btn_settings_window

    @toolbar.add_item btn_ifc_export
    @toolbar.show

  end # module IfcManager
end # module BimTools
