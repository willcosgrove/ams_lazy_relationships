# frozen_string_literal: true

module AmsLazyRelationships::Core
  # Module responsible for lazy loading the relationships during the runtime
  module Evaluation
    private

    LAZY_NESTING_LEVELS = 3
    NESTING_START_LEVEL = 1

    # Recursively loads the tree of lazy relationships
    #
    # @param instance [Object] Lazy relationships will be loaded for this serializer.
    def load_all_lazy_relationships(instance, level = NESTING_START_LEVEL)
      return unless instance.object
      return if level >= LAZY_NESTING_LEVELS

      return unless lazy_relationships

      lazy_relationships.each_value do |lrm|
        load_lazy_relationship(lrm, instance, level)
      end
    end

    # @param lrm [LazyRelationshipMeta] relationship data
    # @param instance [Object] Serializer instance to load the relationship for
    def load_lazy_relationship(lrm, instance, level = NESTING_START_LEVEL)

      lrm.loader.load(instance, lrm.load_for) do |batch_records|
        deep_load_for_yielded_records(
          batch_records,
          lrm,
          level
        )
      end
    end

    def deep_load_for_yielded_records(batch_records, lrm, level)
      # There'll be no more nesting if there's no
      # reflection for this relationship. We can skip deeper lazy loading.
      return unless lrm.reflection

      Array.wrap(batch_records).each do |r|
        serializer_class =
          lrm.serializer_class || ActiveModel::Serializer.serializer_for(r)

        serializer_class.new(r, level: level + 1)
      end
    end
  end
end
