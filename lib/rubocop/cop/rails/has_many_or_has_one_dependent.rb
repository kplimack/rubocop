# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # This cop looks for `has_many` or `has_one` associations that don't
      # specify a `:dependent` option.
      # It doesn't register an offense if `:through` option was specified.
      #
      # @example
      #   # bad
      #   class User < ActiveRecord::Base
      #     has_many :comments
      #     has_one :avatar
      #   end
      #
      #   # good
      #   class User < ActiveRecord::Base
      #     has_many :comments, dependent: :restrict_with_exception
      #     has_one :avatar, dependent: :destroy
      #     has_many :patients, through: :appointments
      #   end
      class HasManyOrHasOneDependent < Cop
        MSG = 'Specify a `:dependent` option.'.freeze

        def_node_matcher :has_many_or_has_one_without_options?, <<-PATTERN
          (send nil? {:has_many :has_one} _)
        PATTERN

        def_node_matcher :has_many_or_has_one_with_options?, <<-PATTERN
          (send nil? {:has_many :has_one} _ (hash $...))
        PATTERN

        def_node_matcher :has_dependent?, <<-PATTERN
          (pair (sym :dependent) !nil)
        PATTERN

        def_node_matcher :has_through?, <<-PATTERN
          (pair (sym :through) !nil)
        PATTERN

        def_node_matcher :with_options_block, <<-PATTERN
          (block
            (send nil? :with_options
              (hash $...))
            (args) ...)
        PATTERN

        def on_send(node)
          if !has_many_or_has_one_without_options?(node)
            return if valid_options?(has_many_or_has_one_with_options?(node))
          elsif with_options_block(node.parent)
            return if valid_options?(with_options_block(node.parent))
          end

          add_offense(node, location: :selector)
        end

        private

        def valid_options?(options)
          return true unless options
          return true if options.any? do |o|
            has_dependent?(o) || has_through?(o)
          end

          false
        end
      end
    end
  end
end
