#--
# BibTeX-Ruby
# Copyright (C) 2010-2011  Sylvester Keil <sylvester.keil.or.at>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

require 'forwardable'

module BibTeX

  class Value
    extend Forwardable
    include Comparable
    
    attr_reader :tokens
    alias :to_a :tokens
    
    def_delegators :to_s, :<=>, :empty?, :=~, :match, :length, :intern, :to_sym, :to_i, :to_f, :end_with?, :start_with?, :include?, :upcase, :downcase, :reverse, :chop, :chomp, :rstrip, :gsub, :sub, :size, :strip, :succ, :to_c, :to_r, :to_str
    def_delegators :@tokens, :push
    
    def initialize(*arguments)
      @tokens = []
      
      arguments.flatten.each do |argument|
        case argument
        when Value
          @tokens += argument.tokens.dup
        when ::String
          @tokens << argument
        when Symbol
          @tokens << argument
        else
          raise(ArgumentError, "Failed to create Value from argument #{ argument.inspect }; expected String, Symbol or Value instance.")
        end
      end
    end
    
    def initialize_copy(other)
      @tokens = other.tokens.dup
    end
    
    def replace(*arguments)
      return self unless symbol?
      arguments.flatten.each do |argument|
        case argument
        when ::String # simulate Ruby's String#replace
          @tokens = [argument]
        when String
          @tokens = @tokens.map { |v| argument[v] || v }
        when Hash
          @tokens = @tokens.map { |v| argument[v] || v }
        end
      end
      self
    end


    # Returns the Value instance with all consecutive String tokens joined.
    #
    # call-seq:
    # Value.new('foo', 'bar').join #=> <'foobar'>
    # Value.new(:foo, 'bar').join  #=> <:foo, 'bar'>
    #
    def join
      @tokens = @tokens.inject([]) do |a,b|
        a[-1].is_a?(::String) && b.is_a?(::String) ? a[-1] += b : a << b; a
      end
      self
    end
    
    # Returns a the Value as a string. @see #value; the only difference is
    # that single symbols are returned as String, too.
    # If the Value is atomic and the option :quotes is given, the string
    # will be quoted using the quote symbols specified.
    #
    # call-seq:
    # Value.new('foo').to_s                       #=> "foo"
    # Value.new(:foo).to_s                        #=> "foo"
    # Value.new('foo').to_s(:quotes => '"')       #=> "\"foo\""
    # Value.new('foo').to_s(:quotes => ['"','"']) #=> "\"foo\""
    # Value.new('foo').to_s(:quotes => ['{','}']) #=> "{foo}"
    # Value.new(:foo, 'bar').to_s                 #=> "foo # \"bar\""
    # Value.new('foo', 'bar').to_s                #=> "\"foo\" # \"bar\""
    #
    def to_s(options = {})
      return value.to_s unless options.has_key?(:quotes) && !atomic?
      *q = options[:quotes]
      [q[0], value, q[-1]].join
    end

    # Returns the Value as a string or, if it consists of a single symbol, as
    # a Symbol instance. If the Value contains multiple tokens, they will be
    # joined by a '#', additionally, all string tokens will be turned into
    # string literals (i.e., delimitted by quotes).
    def value
      atomic? ? @tokens[0] : @tokens.map { |v|  v.is_a?(::String) ? v.inspect : v }.join(' # ')
    end
    
    alias :v :value

    def inspect
      '<' + @tokens.map(&:inspect).join(', ') + '>'
    end
    
    # Returns true if the Value is empty or consists of a single token.
    def atomic?
      @tokens.length < 2
    end
    
    # Returns true if the Value looks like a BibTeX name value.
    def name?
    end
    
    alias :is_name? :name?
    
    # Returns true if the Value's content is numeric.
    def numeric?
      to_s =~ /^\s*[+-]?\d+[\/\.]?\d*\s*$/
    end
    
    alias :is_numeric? :numeric?
    
    # Returns true if the Value contains at least one symbol.
    def symbol?
      @tokens.detect { |v| v.is_a?(Symbol) }
    end
    
    alias :is_symbol? :symbol?
    
    # Returns all symbols contained in the Value.
    def symbols
      @tokens.select { |v| v.is_a?(Symbol) }
    end
    
  end
  
end