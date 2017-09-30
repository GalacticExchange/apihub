module Gexcore
  class NameGenerator < BaseService

    @nouns = nil
    @adjectives = nil

    @filename_nouns = ''
    @filename_adj = ''


    def initialize(filename_nouns, filename_adj)
      @filename_nouns = filename_nouns
      @filename_adj = filename_adj

    end

    def filename_nouns
      @filename_nouns
    end

    def filename_adjectives
      @filename_adj
    end



    ####

    def get_nouns
      return @nouns unless @nouns.nil?

      # load from file
      txt = File.read(filename_nouns)
      @nouns = JSON.parse(txt, :quirks_mode => true)
    end

    def get_adjectives
      return @adjectives unless @adjectives.nil?

      # load from file
      txt = File.read(filename_adjectives)
      @adjectives = JSON.parse(txt, :quirks_mode => true)
    end


    ###
    # returns array with indexes
    def get_name_indexes(id)
      nouns = get_nouns
      adjectives = get_adjectives


      #
      n = id - 1

      #
      n_g = nouns.count
      n_adj = adjectives.count

      #
      i_g = n % n_g
      block_g = (n) / n_g
      i_adj = ( block_g + i_g - 1) % n_adj

      [i_g, i_adj, block_g]
    end



    def generate_name(id)
      #
      nouns = get_nouns
      adjectives = get_adjectives

      #
      ind = get_name_indexes(id)
      i_g, i_adj, block_g = ind

      if block_g==0
        # without adjective
        nouns[i_g]
      else
        # adj + galactic
        adjectives[i_adj]+'-'+nouns[i_g]
      end

    end
  end
end


