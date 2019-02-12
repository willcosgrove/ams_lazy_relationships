# frozen_string_literal: true

module AmsLazyRelationships::Core
  # Module responsible for lazy loading the relationships during the runtime
  module Evaluation
    private

    # Recursively loads the tree of lazy relationships
    #
    # @param instance [Object] Lazy relationships will be loaded for this serializer.
    def load_all_lazy_relationships(instance)
      return unless instance.object

      return unless lazy_relationships

      lazy_relationships.each_value do |lrm|
        load_lazy_relationship(lrm, instance)
      end
    end

    # @param lrm [LazyRelationshipMeta] relationship data
    # @param instance [Object] Serializer instance to load the relationship for
    def load_lazy_relationship(lrm, instance)

      lrm.loader.load(instance, lrm.load_for) do |batch_records|
        deep_load_for_yielded_records(
          batch_records,
          lrm
        )
      end
    end

    def deep_load_for_yielded_records(batch_records, lrm)
      # There'll be no more nesting if there's no
      # reflection for this relationship. We can skip deeper lazy loading.
      return unless lrm.reflection

      Array.wrap(batch_records).each do |r|
        serializer_class =
          lrm.serializer_class || ActiveModel::Serializer.serializer_for(r)

        serializer_class.new(r)
      end
    end
  end
end
