RSpec.describe "Name generator", :type => :request do

  def get_test_name(i)
    ind = @lib.get_name_indexes(i)

    block_g = ind[2]
    if block_g==0
      test_name = @a_g[ind[0]]
    else
      test_name = @a_adj[ind[1]] + '-'+@a_g[ind[0]]
    end

  end

  def get_our_name(i_g, i_adj)
    @a_adj[i_adj] + '-'+@a_g[i_g]
  end

  describe "generate cluster name" do

    before :each do
      # stub
      #allow(Apiservice::ClustersLib).to receive(:filename_galactics).and_return('data/galactics.test.json')
      #allow(Apiservice::ClustersLib).to receive(:filename_adjectives).and_return('data/adjectives.test.json')

      #allow(Apiservice::ClustersLib).to receive(:filename_galactics).and_return('data/galactics.json')
      #allow(Apiservice::ClustersLib).to receive(:filename_adjectives).and_return('data/adjectives.json')

      #
      @generator  = Gexcore::NameGenerator.new('data/galactics.json', 'data/adjectives.json')


      #
      #@lib = Apiservice::ClustersLib
      @lib = @generator

      @a_g = @generator.get_nouns
      @a_adj = @generator.get_adjectives

      # add debug numbers to names
      #@a_g = @a_g.each_with_index.map { |s,i| i.to_s+s }
      #@a_adj = @a_adj.each_with_index.map { |s,i| i.to_s+s }

      # counts
      @n_g = @a_g.count
      @n_adj = @a_adj.count

    end




    it "debug" do
      name = get_test_name(16)

    end

    it "one" do
      name = get_test_name(1)

      expect(name).to eq (@a_g[0])
    end

    it "two" do
      name = get_test_name(2)

      expect(name).to eq (@a_g[1])
    end


    it 'all' do
      ind = 0
      i_g = 0
      i_adj = 0
      block_g = 1

      puts "Galactics :#{@n_g}, adjectives: #{@n_adj}"

      all_names = []


      numbers = ((@n_g+1)..((@n_g-1)*@n_adj-1)).to_a
      numbers.each do |i|
        test_name = get_test_name(i)

        #
        our_name = get_our_name(i_g, i_adj)


        puts "#{i} - #{test_name} - #{our_name}"

        expect(test_name).to eq our_name

        # check if unique
        ind_found = all_names.index(test_name)

        if ind_found
          puts "NOT UNIQUE: #{test_name}, ind = #{ind_found}, duplicate: #{all_names[ind_found]}"
        end


        #
        all_names << test_name

        # next
        i_g += 1
        if i_g >= @n_g
          i_g = 0
          block_g +=1
        end

        i_adj = ( i_g + block_g - 1) % @n_adj


      end

      # all names should be unique
      #all_names << '8deep1beta'
      expect(all_names.uniq.length).to eq (all_names.length)

    end

  end

  describe "generate NODE name" do

    before :each do
      @generator  = Gexcore::NameGenerator.new('data/stars.json', 'data/adjectives.json')

      @lib = @generator

      @a_g = @generator.get_nouns
      @a_adj = @generator.get_adjectives

      # add debug numbers to names
      #@a_g = @a_g.each_with_index.map { |s,i| i.to_s+s }
      #@a_adj = @a_adj.each_with_index.map { |s,i| i.to_s+s }

      # counts
      @n_g = @a_g.count
      @n_adj = @a_adj.count

    end

    it 'all' do
      ind = 0
      i_g = 0
      i_adj = 0
      block_g = 1

      puts "Stars :#{@n_g}, adjectives: #{@n_adj}"

      all_names = []


      numbers = ((@n_g+1)..((@n_g-1)*@n_adj-1)).to_a
      numbers.each do |i|
        test_name = get_test_name(i)

        #
        our_name = get_our_name(i_g, i_adj)


        puts "#{i} - #{test_name} - #{our_name}"

        expect(test_name).to eq our_name

        # check if unique
        ind_found = all_names.index(test_name)

        if ind_found
          puts "NOT UNIQUE: #{test_name}, ind = #{ind_found}, duplicate: #{all_names[ind_found]}"
        end


        #
        all_names << test_name

        # next
        i_g += 1
        if i_g >= @n_g
          i_g = 0
          block_g +=1
        end

        i_adj = ( i_g + block_g - 1) % @n_adj


      end

      # all names should be unique
      expect(all_names.uniq.length).to eq (all_names.length)

    end
  end


end
