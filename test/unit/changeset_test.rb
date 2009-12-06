require File.dirname(__FILE__) + '/../test_helper'

class ChangesetTest < ActiveSupport::TestCase
  api_fixtures
  
  def test_changeset_count
    assert_equal 7, Changeset.count
  end
  
  def test_xml_from_id_zero
    id_list = ["", "0", "00", "0.0", "a"]
    id_list.each do |id|
      zero_id = "<osm><changeset id='#{id}' /></osm>"
      assert_nothing_raised(OSM::APIBadUserInput) {
        Changeset.from_xml(zero_id, true)
      }
      message_update = assert_raise(OSM::APIBadUserInput) {
        Changeset.from_xml(zero_id, false)
      }
      assert_match /ID of changeset cannot be zero when updating/, message_update.message
    end
  end
  
  def test_from_xml_no_text
    no_text = ""
    message_create = assert_raise(OSM::APIBadXMLError) {
      Changeset.from_xml(no_text, true)
    }
    assert_match /Must specify a string with one or more characters/, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) {
      Changeset.from_xml(no_text, false)
    }
    assert_match /Must specify a string with one or more characters/, message_update.message
  end
  
  def test_from_xml_no_changeset
    nocs = "<osm></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) {
      Changeset.from_xml(nocs, true)
    }
    assert_match /XML doesn't contain an osm\/changeset element/, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) {
      Changeset.from_xml(nocs, false)
    }
    assert_match /XML doesn't contain an osm\/changeset element/, message_update.message
  end
  
  def test_from_xml_no_k_v
    nokv = "<osm><changeset><tag /></changeset></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) {
      Changeset.from_xml(nokv, true)
    }
    assert_match /tag is missing key/, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) {
      Changeset.from_xml(nokv, false)
    }
    assert_match /tag is missing key/, message_create.message
  end
  
  def test_from_xml_no_v
    no_v = "<osm><changeset id='1'><tag k='key' /></changeset></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) {
      Changeset.from_xml(no_v, true)
    }
    assert_match /tag is missing value/, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) {
      Changeset.from_xml(no_v, false)
    }
    assert_match /tag is missing value/, message_update.message
  end
  
  def test_from_xml_duplicate_k
    dupk = "<osm><changeset id='1'><tag k='dup' v='test' /><tag k='dup' v='value' /></changeset></osm>"
    message_create = assert_raise(OSM::APIDuplicateTagsError) {
      Changeset.from_xml(dupk, true)
    }
    assert_equal "Element changeset/ has duplicate tags with key dup", message_create.message
    message_update = assert_raise(OSM::APIDuplicateTagsError) {
      Changeset.from_xml(dupk, false)
    }
    assert_equal "Element changeset/1 has duplicate tags with key dup", message_update.message
  end
end
