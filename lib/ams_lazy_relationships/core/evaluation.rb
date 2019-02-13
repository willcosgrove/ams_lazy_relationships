# frozen_string_literal: true

require "jsonapi/include_directive"

module AmsLazyRelationships::Core
  # Module responsible for lazy loading the relationships during the runtime
  module Evaluation
    private

    DEFAULT_PREFETCH = JSONAPI::IncludeDirective.new("")

    # Recursively loads the tree of lazy relationships
    #
    # @param instance [Object] Lazy relationships will be loaded for this serializer.
    def load_all_lazy_relationships(instance, prefetch)
      return unless instance.object

      return unless lazy_relationships

      lazy_relationships.each do |key, lrm|
        next unless prefetch.key? key

        next_prefetch = prefetch[key]
        load_lazy_relationship(lrm, instance, next_prefetch)
      end
    end

    # @param lrm [LazyRelationshipMeta] relationship data
    # @param instance [Object] Serializer instance to load the relationship for
    def load_lazy_relationship(lrm, instance, prefetch = DEFAULT_PREFETCH)
      lrm.loader.load(instance, lrm.load_for) do |batch_records|
        deep_load_for_yielded_records(
          batch_records,
          lrm,
          prefetch
        )
      end
    end

    def deep_load_for_yielded_records(batch_records, lrm, prefetch)
      # There'll be no more nesting if there's no
      # reflection for this relationship. We can skip deeper lazy loading.
      return unless lrm.reflection

      Array.wrap(batch_records).each do |r|
        serializer_class =
          lrm.serializer_class || ActiveModel::Serializer.serializer_for(r)

        serializer_class.new(r, prefetch: prefetch)
      end
    end
  end
end
