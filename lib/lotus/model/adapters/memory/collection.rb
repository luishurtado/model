require 'lotus/model/adapters/abstract'

module Lotus
  module Model
    module Adapters
      class Memory < Abstract
        class Collection
          class PrimaryKey
            def initialize
              @current = 0
            end

            def increment!
              yield(@current += 1)
              @current
            end
          end

          attr_reader :name, :key, :records

          def initialize(name, key)
            @name, @key = name, key
            clear
          end

          def create(entity)
            @primary_key.increment! do |id|
              entity[key] = id
              records[id] = entity
            end
          end

          def update(entity)
            records[entity.fetch(key)] = entity
          end

          def delete(entity)
            records[entity.id] = nil
          end

          def all
            records.values
          end

          def find(id)
            records[id] unless id.nil?
          end

          def first
            all.first
          end

          def clear
            @records     = {}
            @primary_key = PrimaryKey.new
          end

          # TODO extract into another file
          class Query
            def initialize(collection)
              @collection = collection
              @conditions = []
            end

            def where(condition)
              @conditions.push [:find_all, *condition]
              self
            end

            def all
              @conditions.map do |finder, (attr,value)|
                @collection.all.send(finder, &Proc.new{|record| record.fetch(attr) == value})
              end
            end
          end

          def where(condition)
            Query.new(self).where(condition)
          end
        end
      end
    end
  end
end