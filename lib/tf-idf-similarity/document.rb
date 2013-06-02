# coding: utf-8
begin
  require 'unicode_utils'
rescue LoadError
  # Ruby 1.8
end

class TfIdfSimilarity::Document
  # An optional document identifier.
  attr_reader :id
  # The document's text.
  attr_reader :text
  # The number of times each term appears in the document.
  attr_reader :term_counts
  # The number of tokens in the document.
  attr_reader :size

  # @param [String] text the document's text
  # @param [Hash] opts optional arguments
  # @option opts [String] :id a string to identify the document
  # @option opts [Array] :tokens the document's tokenized text
  # @option opts [Hash] :term_counts the number of times each term appears
  # @option opts [Integer] :size the number of tokens in the document
  def initialize(text, opts = {})
    @text        = text
    @id          = opts[:id] || object_id
    @tokens      = opts[:tokens]

    if opts[:term_counts]
      @term_counts = opts[:term_counts]
      @size = opts[:size] || term_counts.values.reduce(0, :+)
      # Nothing to do.
    else
      @term_counts = Hash.new(0)
      @size = 0
      set_term_counts_and_size
    end
  end

  # Returns the set of terms in the document.
  #
  # @return [Array<String>] the unique terms in the document
  def terms
    term_counts.keys
  end

  # Returns the term's frequency in the document.
  #
  # @param [String] term a term
  # @return [Float] the square root of the term count
  #
  # @see http://lucene.apache.org/core/4_0_0-BETA/core/org/apache/lucene/search/similarities/TFIDFSimilarity.html
  def term_frequency(term)
    Math.sqrt(plain_term_frequency(term))
  end
  alias_method :tf, :term_frequency

  # Returns the number of occurrences of the term in the document.
  #
  # @param [String] term a term
  # @return [Integer] the number of occurrences of the term in the document
  def plain_term_frequency(term)
    term_counts[term].to_i # need #to_i if unmarshalled
  end
  alias_method :plain_tf, :plain_term_frequency

private

  # Tokenizes the text and counts terms.
  def set_term_counts_and_size
    tokenize(text).each do |word|
      token = TfIdfSimilarity::Token.new(word)
      if token.valid?
        term = token.lowercase_filter.classic_filter.to_s
        @term_counts[term] += 1
        @size              += 1
      end
    end
  end

  # Tokenizes a text, respecting the word boundary rules from Unicode’s Default
  # Word Boundary Specification.
  #
  # If a tokenized text was provided at the document's initialization, those
  # tokens will be returned without additional processing.
  #
  # @param [String] text a text
  # @return [Enumerator] a token enumerator
  #
  # @note We should evaluate the tokenizers by {http://www.sciencemag.org/content/suppl/2010/12/16/science.1199644.DC1/Michel.SOM.revision.2.pdf Google}
  #   or {http://wiki.apache.org/solr/AnalyzersTokenizersTokenFilters#solr.UAX29URLEmailTokenizerFactory Solr}.
  #
  # @see http://unicode.org/reports/tr29/#Default_Word_Boundaries
  # @see http://wiki.apache.org/solr/AnalyzersTokenizersTokenFilters#solr.StandardTokenizerFactory
  def tokenize(text)
    @tokens || defined?(UnicodeUtils) && UnicodeUtils.each_word(text) || text.split(/\b/) # @todo Ruby 1.8.7 has no good word boundary code
  end
end
