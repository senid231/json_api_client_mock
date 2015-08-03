require 'ostruct'

module JsonApiClientMock
  class MockConnection
    class_attribute :mocks
    self.mocks = {}

    # ignored
    def initialize(*attrs)
    end

    def use(*attrs)
    end

    def delete(*attrs)
    end

    def run(request_method, path, params = {}, headers = {})
      if results = find_test_results(request_method, path, params)
        OpenStruct.new(:body => {
                           "data" => parse_resource(results[:results], path),
                           "meta" => results[:meta]
                       },
                       env: {}
        )
      else
        raise MissingMock, missing_message(request_method, path, params)
      end
    end

    def parse_resource(results, type)
      if results.is_a?(Hash)
        {'id' => results[:id].to_s, 'type' => type, 'attributes' => results.except(:id)}
      else
        results.map do |result|
          {'id' => result[:id].to_s, 'type' => type, 'attributes' => result.except(:id)}
        end
      end
    end

    def set_test_results(klass, results, options = {})
      self.class.mocks[klass.table_name] ||= []
      id = results[:id] if results.is_a?(Hash)
      self.class.mocks[klass.table_name].unshift({
                                                     results: results,
                                                     conditions: options[:conditions],
                                                     method: options[:method] || :get,
                                                     id: id,
                                                     meta: options[:meta]
                                                 })
    end

    def clear_test_results
      self.class.mocks = {}
    end

    protected

    def class_mocks(path)
      self.class.mocks.fetch(path, [])
    end

    def find_test_results(method, path, params)
      types = path.split('/').last(2)
      mocks = class_mocks(types.last).select { |mock| mock[:method] == method && mock[:id].nil? }
      mocks = class_mocks(types.first).select { |mock| mock[:method] == method && mock[:id].to_s == types.last } if mocks.blank? && types.length == 2
      mocks.detect { |mock| mock[:conditions] == params } || mocks.detect { |mock| mock[:conditions].blank? }
    end

    def missing_message(method, path, params)
      ["no test results set for request_path #{path} with method #{method} and conditions: #{params.pretty_inspect}",
       "mocks available: #{class_mocks(path).map { |m| m.pretty_inspect }}"
      ].join("\n\n")
    end
  end
end
