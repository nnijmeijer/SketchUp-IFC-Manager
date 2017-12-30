#  ObjectCreator.rb
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


# # parent_shape_representation = shape representation linked to the parent_ifc (containing the brep's)
# transformation = the sketchup transformation object that translates back to the parent_ifc

# indexer = row numbering object (temporarily replaced by the complete ifc_model object)
# su_instance = sketchup component instance or group
# su_total_transformation = sketchup total transformation from model root to this instance placement
# parent_ifc = ifc entity above this one in the hierarchy
# parent_space = ifc space above this one in the hierarchy
# parent_buildingstorey = ifc buildingstorey above this one in the hierarchy
# parent_building = ifc building above this one in the hierarchy
# parent_site = ifc site above this one in the hierarchy
# parent_project = the IfcProject object


require_relative File.join('IFC2X3', 'IfcSpatialStructureElement.rb')
require_relative File.join('IFC2X3', 'IfcSite.rb')
require_relative File.join('IFC2X3', 'IfcBuilding.rb')
require_relative File.join('IFC2X3', 'IfcBuildingStorey.rb')
require_relative File.join('IFC2X3', 'IfcBuildingElementProxy.rb')
require_relative File.join('IFC2X3', 'IfcLocalPlacement.rb')
require_relative File.join('IFC2X3', 'IfcFacetedBrep.rb')
require_relative File.join('IFC2X3', 'IfcStyledItem.rb')

module BimTools
 module IfcManager

  # checks the current definition for ifc objects, and calls itself for all nested items
  class ObjectCreator
    
    include IFC2X3
    
    # def initialize(indexer, su_instance, container, containing_entity, parent_ifc, transformation_from_entity, transformation_from_container, site=nil, site_container=nil, building=nil, building_container=nil, building_storey=nil, building_storey_container=nil)
    def initialize(indexer, su_instance, su_total_transformation, parent_ifc, parent_project, parent_site=nil, parent_building=nil, parent_buildingstorey=nil, parent_space=nil)
      definition = su_instance.definition
      
      #temporary translator 
      
      # create IfcEntity
      
      # Create IFC entity based on the IFC classification in sketchup
      begin
        require_relative File.join('IFC2X3', definition.get_attribute("AppliedSchemaTypes", "IFC 2x3") + ".rb")
        entity_type = eval("" + definition.get_attribute("AppliedSchemaTypes", "IFC 2x3"))
        ifc_entity = entity_type.new(indexer, su_instance)
      rescue
        
        # If not classified as IFC in sketchup AND the parent is an IfcSpatialStructureElement then this is an IfcBuildingElementProxy
        if parent_ifc.is_a?(IfcSpatialStructureElement) || parent_ifc.is_a?(IfcProject)
          ifc_entity = IfcBuildingElementProxy.new(indexer, su_instance)
        else # this instance is pure geometry, ifc_entity = nil
          ifc_entity = nil
        end
      end
      
      # find the correct parent in the spacialhierarchy
      if ifc_entity.is_a? IfcProduct
        
        # check the element type and set the correct parent in the spacialhierarchy
        case ifc_entity.class.to_s
        when 'IfcSite'
          #indexer.site = true
          parent_site = ifc_entity
          #parent_ifc = parent_project
        when 'IfcBuilding'
          #indexer.building = true
          if parent_site.nil? # create new site
            parent_site = indexer.get_base_site
          end
          parent_building = ifc_entity
          parent_ifc = parent_site
        when 'IfcBuildingStorey'
          #indexer.buildingstorey = true
          if parent_building.nil? # create new building
            parent_building = indexer.get_base_building
          end
          parent_buildingstorey = ifc_entity
          parent_ifc = parent_building
        when 'IfcSpace'
          if parent_buildingstorey.nil? # create new buildingstorey
            parent_buildingstorey = indexer.get_base_buildingstorey
          end
          parent_space = ifc_entity
          parent_ifc = parent_buildingstorey
        else # 'normal' product, no IfcSpatialStructureElement
          if parent_space
            parent_ifc = parent_space
          else
            # if parent_buildingstorey.nil? # create new buildingstorey
              # if parent_building.nil?
                # if parent_site.nil?
                  # parent_ifc = indexer.get_base_site
                # else
                  # parent_ifc = parent_site
                # end
              # else
                # parent_ifc = parent_building
                # #parent_building = indexer.get_base_building
              # end
              # #parent_buildingstorey = indexer.get_base_buildingstorey
            # else
              # parent_ifc = parent_buildingstorey
            # end
            
            # (?) kan misschien beter, door te bekijken of er al een building bestaat of niet???
            if parent_buildingstorey.nil? # create new buildingstorey
              parent_buildingstorey = indexer.get_base_buildingstorey( parent_building )
            end
            parent_ifc = parent_buildingstorey
          end
          
          # add this element to the model
          parent_ifc.add_related_element( ifc_entity )
        end
        
        # add spacialstructureelements to the spacialhierarchy
        if ifc_entity.is_a? IfcSpatialStructureElement
          parent_ifc.add_related_object( ifc_entity )
        end
        ifc_entity.parent = parent_ifc
      end
      
      # calculate the total transformation
      su_total_transformation = su_total_transformation * su_instance.transformation
      
      # create objectplacement for ifc_entity
      # set objectplacement based on transformation
      if ifc_entity
        if parent_ifc.is_a?(IfcProject)
          parent_objectplacement = nil
        else
          parent_objectplacement = parent_ifc.objectplacement
        end
        
        ifc_entity.objectplacement = IfcLocalPlacement.new(indexer, su_total_transformation, parent_objectplacement )
        
        #ifc_entity.objectplacement.set_transformation( 
        #unless parent_ifc.is_a?(IfcProject) # (?) check unnecessary?
        #  ifc_entity.objectplacement.placementrelto = parent_ifc.objectplacement
        #end
      end
      
      # if this SU object is not an IFC Entity then set the parent entity as Ifc Entity
      unless ifc_entity
        ifc_entity = parent_ifc
      end
      
      # calculate the local transformation
      # if the SU object if not an IFC entity, then BREP needs to be transformed with SU object transformation
      
      
      # corrigeren voor het geval beide transformties dezelfde verschaling hebben, die mag niet met inverse geneutraliseerd worden
      # er zou in de ifc_total_transformation eigenlijk geen verschaling mogen zitten.
      # wat mag er wel in zitten? wel verdraaiing en verplaatsing.
      
      # find sub-objects (geometry and entities)
      faces = Array.new
      definition.entities.each do | ent |
        case ent
        when Sketchup::Group, Sketchup::ComponentInstance
          # ObjectCreator.new( indexer, ent, container, containing_entity, parent_ifc, transformation_from_entity, transformation_from_container)
          ObjectCreator.new(indexer, ent, su_total_transformation, ifc_entity, parent_project, parent_site, parent_building, parent_buildingstorey, parent_space)
        when Sketchup::Face
          faces << ent
        end
      end
      
      unless parent_ifc.is_a?(IfcProject)
        brep_transformation = ifc_entity.objectplacement.ifc_total_transformation.inverse * su_total_transformation
      else
        brep_transformation = su_total_transformation
      end
      
      # create geometry from faces
      unless faces.empty?
        brep = IfcFacetedBrep.new( indexer, faces, brep_transformation )
        ifc_entity.representation.representations.first.items.add( brep )
        
        # add color from su-object material
        if su_instance.material
          IfcStyledItem.new( indexer, brep, su_instance.material )
        end
      end
    end # def initialize
  end # class ObjectCreator

 end # module IfcManager
end # module BimTools
