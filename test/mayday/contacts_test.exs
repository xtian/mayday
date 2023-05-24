defmodule Mayday.ContactsTest do
  use Mayday.DataCase

  alias Mayday.Contacts

  describe "all_matching_filters/1" do
    test "filters contacts based on tag inclusion" do
      tag_a = unique_string()
      tag_b = unique_string()

      insert(:contact)
      insert(:contact, tags: [tag_a])
      insert(:contact, tags: [tag_b])
      insert(:contact, tags: [tag_a, tag_b])

      assert [_, _] = Contacts.all_matching_filters([%{direction: :include, tag: tag_a}])
      assert [_, _] = Contacts.all_matching_filters([%{direction: :include, tag: tag_b}])

      assert [_, _, _] =
               Contacts.all_matching_filters([
                 %{direction: :include, tag: tag_a},
                 %{direction: :include, tag: tag_b}
               ])
    end

    test "filters contacts based on tag exclusion" do
      tag_a = unique_string()
      tag_b = unique_string()

      insert(:contact)
      insert(:contact, tags: [tag_a])
      insert(:contact, tags: [tag_b])
      insert(:contact, tags: [tag_a, tag_b])

      assert [_, _] = Contacts.all_matching_filters([%{direction: :exclude, tag: tag_a}])
      assert [_, _] = Contacts.all_matching_filters([%{direction: :exclude, tag: tag_b}])

      assert [_] =
               Contacts.all_matching_filters([
                 %{direction: :exclude, tag: tag_a},
                 %{direction: :exclude, tag: tag_b}
               ])
    end

    test "filters contacts based on tag inclusion and exclusion" do
      tag_a = unique_string()
      tag_b = unique_string()

      insert(:contact)
      insert(:contact, tags: [tag_a])
      insert(:contact, tags: [tag_b])
      insert(:contact, tags: [tag_a, tag_b])

      assert [_] =
               Contacts.all_matching_filters([
                 %{direction: :include, tag: tag_a},
                 %{direction: :exclude, tag: tag_b}
               ])
    end
  end

  describe "contact_matches_filters?/2" do
    test "matches contacts based on tag inclusion" do
      tag_a = unique_string()
      filters = [%{direction: :include, tag: tag_a}]

      contact_a = insert(:contact)
      contact_b = insert(:contact, tags: [tag_a])
      contact_c = insert(:contact, tags: [tag_a, unique_string()])

      refute Contacts.contact_matches_filters?(contact_a, filters)
      assert Contacts.contact_matches_filters?(contact_b, filters)
      assert Contacts.contact_matches_filters?(contact_c, filters)
    end

    test "filters contacts based on tag exclusion" do
      tag_a = unique_string()
      filters = [%{direction: :exclude, tag: tag_a}]

      contact_a = insert(:contact)
      contact_b = insert(:contact, tags: [tag_a])
      contact_c = insert(:contact, tags: [tag_a, unique_string()])
      contact_d = insert(:contact, tags: [unique_string()])

      assert Contacts.contact_matches_filters?(contact_a, filters)
      refute Contacts.contact_matches_filters?(contact_b, filters)
      refute Contacts.contact_matches_filters?(contact_c, filters)
      assert Contacts.contact_matches_filters?(contact_d, filters)
    end

    test "filters contacts based on tag inclusion and exclusion" do
      tag_a = unique_string()
      tag_b = unique_string()

      filters = [
        %{direction: :include, tag: tag_a},
        %{direction: :exclude, tag: tag_b}
      ]

      contact_a = insert(:contact)
      contact_b = insert(:contact, tags: [tag_a])
      contact_c = insert(:contact, tags: [tag_a, tag_b])
      contact_d = insert(:contact, tags: [tag_b])

      refute Contacts.contact_matches_filters?(contact_a, filters)
      assert Contacts.contact_matches_filters?(contact_b, filters)
      refute Contacts.contact_matches_filters?(contact_c, filters)
      refute Contacts.contact_matches_filters?(contact_d, filters)
    end
  end
end
