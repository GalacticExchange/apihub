module Gexcore
  class ElasticSearchHelpers
    # sanitize a search query for Lucene. Useful if the original
    # query raises an exception, due to bad adherence to DSL.
    # Taken from here:
    #
    # http://stackoverflow.com/questions/16205341/symbols-in-query-string-for-elasticsearch
    #
    def self.sanitize_string(str)
      return '' if str.nil?

      # Escape special characters
      # http://lucene.apache.org/core/old_versioned_docs/versions/2_9_1/queryparsersyntax.html#Escaping Special Characters
      escaped_characters = Regexp.escape('\\+-&|!(){}[]^~*?:\/')

      str = str.gsub(/([#{escaped_characters}])/, '\\\\\1')

      # AND, OR and NOT are used by lucene as logical operators. We need
      # to escape them
      ['AND', 'OR', 'NOT'].each do |word|
        escaped_word = word.split('').map {|char| "\\#{char}" }.join('')
        str = str.gsub(/\s*\b(#{word.upcase})\b\s*/, " #{escaped_word} ")
      end

      # Escape odd quotes
      quote_count = str.count '"'
      str = str.gsub(/(.*)"(.*)/, '\1\"\3') if quote_count % 2 == 1

      str
    end


    def self.autocomplete_elastic_dsl_array_for_render_json(query_string, class_name, fields_names)

      array_of_hashes = Gexcore::LogFromElasticsearch.autocomplete_elastic_dsl(query_string, class_name, fields_names)
      #
      array_of_hashes.collect do |t|
        [t['_id'], t["#{fields_names[0]}"]]
      end

    end

  end
end
