require 'helper.rb'

module BibTeX
  class EntryTest < MiniTest::Spec

    describe 'a new entry' do
      it "won't be nil" do
        Entry.new.wont_be_nil
      end
    end

		describe '#names' do
			it 'returns an empty list by default' do
				Entry.new.names.must_be :==, []
			end
			
			it 'returns the author (if set)' do
				Entry.new(:author => 'A').names.must_be :==, %w{ A }
			end

			it 'returns all authors (if set)' do
				Entry.new(:author => 'A B and C D').parse_names.names.length.must_be :==, 2
			end
			
			it 'returns the editor (if set)' do
				Entry.new(:editor => 'A').names.must_be :==, %w{ A }
			end

			it 'returns the translator (if set)' do
				Entry.new(:translator => 'A').names.must_be :==, %w{ A }
			end
			
		end
		
    context 'month conversion' do
      setup do
        @entry = Entry.new
      end
      
      [[:jan,'January'], [:feb,'February'], [:sep,'September']].each do |m|
        should 'convert english months' do
          @entry.month = m[1]
          assert_equal m[0], @entry.month.v
        end
      end

      [[:jan,:jan], [:feb,:feb], [:sep,:sep]].each do |m|
        should 'convert bibtex abbreviations' do
          @entry.month = m[1]
          assert_equal m[0], @entry.month.v
        end
      end

      [[:jan,1], [:feb,2], [:sep,9]].each do |m|
        should 'convert numbers' do
          @entry.month = m[1]
          assert_equal m[0], @entry.month.v
        end
        should 'convert numbers when parsing' do
          @entry = Entry.parse("@misc{id, month = #{m[1]}}")[0]
          assert_equal m[0], @entry.month.v
        end
      end
      
    end

    context 'given an entry' do
      setup do
        @entry = Entry.new do |e|
          e.type = :book
          e.key = :key
          e.title = 'Moby Dick'
          e.author = 'Herman Melville'
          e.publisher = 'Penguin'
          e.address = 'New York'
          e.month = 'Nov'
          e.year = 1993
          e.parse_names
        end
      end
      
      should 'support renaming! of field attributes' do
        @entry.rename!(:title => :foo)
        refute @entry.has_field?(:title)
        assert_equal 'Moby Dick', @entry[:foo]
      end

      should 'support renaming of field attributes' do
        e = @entry.rename(:title => :foo)

        assert @entry.has_field?(:title)
        refute @entry.has_field?(:foo)

        assert e.has_field?(:foo)
        refute e.has_field?(:title)
        
        assert_equal 'Moby Dick', @entry[:title]
        assert_equal 'Moby Dick', e[:foo]
      end

      
      should 'support citeproc export' do
        e = @entry.to_citeproc
        assert_equal 'book', e['type']
        assert_equal 'New York', e['publisher-place']
        assert_equal [1993,11], e['issued']['date-parts'][0]
        assert_equal 1, e['author'].length
        assert_equal 'Herman', e['author'][0]['given']
        assert_equal 'Melville', e['author'][0]['family']
      end
      
      context 'given a filter' do
        setup do
          @filter = Object.new
          def @filter.apply (value); value.is_a?(::String) ? value.upcase : value; end
        end
        
        should 'support arbitrary conversion' do
          e = @entry.convert(@filter)
          assert_equal 'MOBY DICK', e.title
          assert_equal 'Moby Dick', @entry.title
        end

        should 'support arbitrary in-place conversion' do
          @entry.convert!(@filter)
          assert_equal 'MOBY DICK', @entry.title
        end

        should 'support conditional arbitrary in-place conversion' do
          @entry.convert!(@filter) { |k,v| k.to_s =~ /publisher/i  }
          assert_equal 'Moby Dick', @entry.title
          assert_equal 'PENGUIN', @entry.publisher
        end

        should 'support conditional arbitrary conversion' do
          e = @entry.convert(@filter) { |k,v| k.to_s =~ /publisher/i  }
          assert_equal 'Moby Dick', e.title
          assert_equal 'PENGUIN', e.publisher
          assert_equal 'Penguin', @entry.publisher
        end
        
      end
      
    end

    context 'citeproc export' do
      setup do
        @entry = Entry.new do |e|
          e.type = :book
          e.key = :key
          e.author = 'van Beethoven, Ludwig'
          e.parse_names
        end
      end
      
      should 'use dropping-particle by default' do
        assert_equal 'van', @entry.to_citeproc['author'][0]['dropping-particle']
      end
      
      should 'accept option to use non-dropping-particle' do
        assert_equal 'van', @entry.to_citeproc(:particle => 'non-dropping-particle')['author'][0]['non-dropping-particle']
      end
    end
    
    def test_simple
      bib = BibTeX::Bibliography.open(Test.fixtures(:entry), :debug => false)
      refute_nil(bib)
      assert_equal(BibTeX::Bibliography, bib.class)
      assert_equal(3, bib.data.length)
      assert_equal([BibTeX::Entry], bib.data.map(&:class).uniq)
      assert_equal('key:0', bib.data[0].key)
      assert_equal('key:1', bib.data[1].key)
      assert_equal('foo', bib.data[2].key)
      assert_equal(:book, bib.data[0].type)
      assert_equal(:article, bib.data[1].type)
      assert_equal(:article, bib.data[2].type)
      assert_equal('Poe, Edgar A.', bib.data[0][:author].to_s)
      assert_equal('Hawthorne, Nathaniel', bib.data[1][:author].to_s)
      assert_equal('2003', bib.data[0][:year])
      assert_equal('2001', bib.data[1][:year])
      assert_equal('American Library', bib.data[0][:publisher])
      assert_equal('American Library', bib.data[1][:publisher])
      assert_equal('Selected \\emph{Poetry} and `Tales\'', bib.data[0].title)
      assert_equal('Tales and Sketches', bib.data[1].title)
    end
  
    def test_ghost_methods
      bib = BibTeX::Bibliography.open(Test.fixtures(:entry), :debug => false)

      assert_equal 'Poe, Edgar A.', bib[0].author.to_s
    
      expected = 'Poe, Edgar Allen'
      bib.data[0].author = expected
    
      assert_equal expected, bib[0].author.to_s
    end
  
    def test_creation_simple    
      entry = BibTeX::Entry.new
      entry.type = :book
      entry.key = :raven
      entry.author = 'Poe, Edgar A.'
      entry.title = 'The Raven'
    
      assert_equal :book, entry.type
      assert_equal 'raven', entry.key
      assert_equal 'Poe, Edgar A.', entry.author
      assert_equal 'The Raven', entry.title
    end

    def test_creation_from_hash
      entry = BibTeX::Entry.new({
        :type => 'book',
        :key => :raven,
        :author => 'Poe, Edgar A.',
        :title => 'The Raven'
      })
    
      assert_equal :book, entry.type
      assert_equal 'raven', entry.key
      assert_equal 'Poe, Edgar A.', entry.author
      assert_equal 'The Raven', entry.title
    end

    def test_creation_from_block
      entry = BibTeX::Entry.new do |e|
        e.type = :book
        e.key = 'raven'
        e.author = 'Poe, Edgar A.'
        e.title = 'The Raven'
      end
    
      assert_equal :book, entry.type
      assert_equal 'raven', entry.key
      assert_equal 'Poe, Edgar A.', entry.author
      assert_equal 'The Raven', entry.title
    end
  
    def test_sorting
      entries = []
      entries << Entry.new({ :type => 'book', :key => 'raven3', :author => 'Poe, Edgar A.', :title => 'The Raven'})
      entries << Entry.new({ :type => 'book', :key => 'raven2', :author => 'Poe, Edgar A.', :title => 'The Raven'})
      entries << Entry.new({ :type => 'book', :key => 'raven1', :author => 'Poe, Edgar A.', :title => 'The Raven'})
      entries << Entry.new({ :type => 'book', :key => 'raven1', :author => 'Poe, Edgar A.', :title => 'The Aven'})
    
      entries.sort!
    
      assert_equal ['raven1', 'raven1', 'raven2', 'raven3'], entries.map(&:key)
      assert_equal ['The Aven', 'The Raven'], entries.map(&:title)[0,2]

    end
  
		describe 'default keys' do
			setup {
				@e1 = Entry.new(:type => 'book', :author => 'Poe, Edgar A.', :title => 'The Raven', :editor => 'John Hopkins', :year => 1996)
				@e2 = Entry.new(:type => 'book', :title => 'The Raven', :editor => 'John Hopkins', :year => 1996)
				@e3 = Entry.new(:type => 'book', :author => 'Poe, Edgar A.', :title => 'The Raven', :editor => 'John Hopkins')
			}
	
			it 'should return "unknown-a" for an empty Entry' do
				Entry.new.key.must_be :==, 'unknown-a'
			end
	
			it 'should return a key made up of author-year-a if all fields are present' do
				@e1.key.must_be :==, 'poe1996a'
			end

			it 'should return a key made up of editor-year-a if there is no author' do
				@e2.key.must_be :==, 'john1996a'
			end

			it 'should return use the last name if the author/editor names have been parsed' do
				@e2.parse_names.key.must_be :==, 'hopkins1996a'
			end

			it 'skips the year if not present' do
				@e3.key.must_be :==, 'poe-a'
			end
		end
		
		context 'when the entry is added to a Bibliography' do
			setup {
				@e = Entry.new
				@bib = Bibliography.new
			}
			
			it 'should register itself with its key' do
				@bib << @e
				@bib.entries.keys.must_include @e.key
			end
			
			context "when there is already an element registered with the entry's key" do
				setup { @bib << Entry.new }
				
				it "should find a suitable key" do
					k = @e.key
					@bib << @e
					@bib.entries.keys.must_include @e.key
					k.wont_be :==, @e.key
				end
				
			end
		end
		
  end
end