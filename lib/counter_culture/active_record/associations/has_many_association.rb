module CounterCulture
  module ActiveRecord
    module Associations
      module HasManyAssociation

        private

        # Overwrite method of `ActiveRecord::Associations:HasManyAssociation`
        def count_records
          if has_cached_counter_culture?
            count = owner._read_attribute cached_counter_attribute_name

            # If there's nothing in the database and @target has no new records
            # we are certain the current target is an empty array. This is a
            # documented side-effect of the method that may avoid an extra SELECT.
            @target ||= [] and loaded! if count == 0

            [association_scope.limit_value, count].compact.min
          else
            super
          end
        end

        # Method inspired from `ActiveRecord::Associations:HasManyAssociation#has_cached_counter?`
        def has_cached_counter_culture?(reflection = reflection())
          if (inverse = inverse_which_updates_counter_culture_cache(reflection))
            owner.attribute_present?(cached_counter_culture_attribute_name(reflection))
          end
        end

        # Method inspired from `ActiveRecord::Associations:HasManyAssociation#inverse_which_updates_counter_cache`
        def inverse_which_updates_counter_culture_cache(reflection = reflection())
          reflection.klass._reflections.values.find { |inverse_reflection|
            inverse_reflection.belongs_to? &&
            counter_culture_counter(reflection)
          }
        end
        alias inverse_updates_counter_culture_cache? inverse_which_updates_counter_culture_cache

        # Method inspired from `ActiveRecord::Associations:HasManyAssociation#cached_counter_attribute_name`
        def cached_counter_culture_attribute_name(reflection = reflection())
          counter_cache_name = counter_culture_counter(reflection).counter_cache_name
          counter_cache_name.is_a?(Proc) ? counter_cache_name.call(klass.new) : counter_cache_name
        end

        # Overwrite method of `ActiveRecord::Associations:HasManyAssociation`
        def cached_counter_attribute_name(reflection = reflection())
          if inverse_updates_counter_culture_cache?(reflection) &&
              (counter_cache_name = cached_counter_culture_attribute_name(reflection))
            counter_cache_name
          else
            super
          end
        end

        # Method to get the `CounterCulture::Counter` instance
        def counter_culture_counter(reflection = reflection())
          reflection.klass.after_commit_counter_cache.find do |counter|
            counter.model.name == reflection.class_name &&
              (counter.relation.include?(reflection.inverse_of&.name) ||
                counter.relation.include?(reflection.options[:as]))
          end
        end

      end
    end
  end
end
