require 'json-schema'
class Edit < ApplicationRecord
  acts_as_paranoid
  belongs_to :user
  belongs_to :development
  before_save :update_development, if: :approved?
  validate :new_development, unless: :development_id?
  validate :existing_development, if: :development_id?

  private

  def proposed_required_attributes
    ["singfamhu", "smmultifam", "lgmultifam"]
  end

  def groundbroken_required_attributes
    ["singfamhu", "smmultifam", "lgmultifam",
     "affrd_unit", "aff_u30", "aff_30_50", "aff_50_80",
     "aff_80p", "gqpop", "ret_sqft", "ofcmd_sqft", "indmf_sqft", "whs_sqft",
     "rnd_sqft", "ei_sqft", "other_sqft", "hotel_sqft", "hotelrms",
     "publicsqft"]
  end

  def base_schema
    {
      "title": "Edit",
      "type": "object",
      "required": ["name", "status", "latitude", "longitude", "year_compl", "hu", "commsf", "descr"],
      "properties": {
        "name": {
          "type": "string"
        },
        "year_compl": {
          "type": "number"
        },
        "yrcomp_est": {
          "type": "boolean"
        },
        "status": {
          "type": "string"
        },
        "address": {
          "type": "string"
        },
        "zip_code": {
          "type": "string",
          "pattern": "[0-9]{5}"
        },
        "hu": {
          "type": "number"
        },
        "commsf": {
          "type": "number"
        },
        "desc": {
          "type": "string"
        },
        "rdv": {
          "type": "boolean"
        },
        "asofright": {
          "type": "boolean"
        },
        "clusteros": {
          "type": "boolean"
        },
        "phased": {
          "type": "boolean"
        },
        "stalled": {
          "type": "boolean"
        },
        "mied_use": {
          "type": "boolean"
        },
        "headqtrs": {
          "type": "boolean"
        },
        "ovr55": {
          "type": "boolean"
        },
        "prj_url": {
          "type": "string"
        },
        "state": {
          "type": "string"
        },
        "height": {
          "type": "number"
        },
        "stories": {
          "type": "number"
        },
        "prjarea": {
          "type": "number"
        },
        "singfamhu": {
          "type": "number"
        },
        "smmultifam": {
          "type": "number"
        },
        "lgmultifam": {
          "type": "number"
        },
        "gqpop": {
          "type": "number"
        },
        "rptdemp": {
          "type": "number"
        },
        "hotelrms": {
          "type": "number"
        },
        "onsitepark": {
          "type": "number"
        },
        "total_cost": {
          "type": "number"
        },
        "ret_sqft": {
          "type": "number"
        },
        "ofcmd_sqft": {
          "type": "number"
        },
        "indmf_sqft": {
          "type": "number"
        },
        "whs_sqft": {
          "type": "number"
        },
        "rnd_sqft": {
          "type": "number"
        },
        "ei_sqft": {
          "type": "number"
        },
        "other_sqft": {
          "type": "number"
        },
        "hotel_sqft": {
          "type": "number"
        },
        "other_rate": {
          "type": "number"
        },
        "affordable": {
          "type": "number"
        },
        "latitude": {
          "type": "number"
        },
        "longitude": {
          "type": "number"
        },
        "mixed_use": {
          "type": "boolean"
        },
        "programs": {
          "type": "string"
        },
        "forty_b": {
          "type": "boolean"
        },
        "residential": {
          "type": "boolean"
        },
        "commercial": {
          "type": "boolean"
        },
        "municipal": {
          "type": "string"
        },
        "devlper": {
          "type": "string"
        },
        "units_1bd": {
          "type": "number"
        },
        "units_2bd": {
          "type": "number"
        },
        "units_3bd": {
          "type": "number"
        },
        "affrd_unit": {
          "type": "number"
        },
        "aff_u30": {
          "type": "number"
        },
        "aff_30_50": {
          "type": "number"
        },
        "aff_50_80": {
          "type": "number"
        },
        "aff_80p": {
          "type": "number"
        },
        "park_type": {
          "type": "string"
        },
        "publicsqft": {
          "type": "number"
        },
        "unknownhu": {
          "type": "number"
        },
        "unk_sqft": {
          "type": "number"
        },
        "aff_unknown": {
          "type": "number"
        }
      }
    }
  end

  def update_development
    if development
      # Make sure we call the lifecycle callbacks to update calculated values
      development.update(proposed_changes)
    else
      merged_changes = proposed_changes.merge(user_id: user.id)
      development = Development.new(merged_changes)
      development.save
    end
    UserMailer.edit_approved_email(self)
  end

  def existing_development
    updated_development_hash = development.attributes.merge(proposed_changes)
    schema = base_schema
    if updated_development_hash['status'] == 'proposed'
      proposed_required_attributes.each do |value|
        schema[:required] << value
      end
    elsif updated_development_hash['status'] == ('in_construction' || 'completed')
      groundbroken_required_attributes.each do |value|
        schema[:required] << value
      end
    end

    updated_development_hash.each do |key, value|
      if value.blank?
        updated_development_hash.delete(key)
      end
    end

    JSON::Validator.fully_validate(schema, updated_development_hash, errors_as_objects: true).each do |json_error|
      errors.add(json_error[:fragment], json_error[:message])
    end
  end

  def new_development
    schema = base_schema
    if proposed_changes['status'] == 'proposed'
      proposed_required_attributes.each do |value|
        schema[:required] << value
      end
    elsif proposed_changes['status'] == ('in_construction' || 'completed')
      groundbroken_required_attributes.each do |value|
        schema[:required] << value
      end
    end
    JSON::Validator.fully_validate(schema, proposed_changes, errors_as_objects: true).each do |json_error|
      errors.add(json_error[:fragment], json_error[:message])
    end
  end
end
