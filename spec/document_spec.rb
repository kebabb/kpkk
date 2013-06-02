require 'spec_helper'

describe TfIdfSimilarity::Document do
  let :text do
    "FOO-foo BAR bar \r\n\t 123 !@#"
  end

  let :tokens do
    ['FOO-foo', 'BAR', 'bar', "\r\n\t", '123', '!@#']
  end

  let :document_without_text do
    TfIdfSimilarity::Document.new('')
  end

  let :document do
    TfIdfSimilarity::Document.new(text)
  end

  let :document_with_id do
    TfIdfSimilarity::Document.new(text, :id => 'baz')
  end

  let :document_with_tokens do
    TfIdfSimilarity::Document.new(text, :tokens => tokens)
  end

  describe '#id' do
    it 'should return the ID if no ID given' do
      document.id.should be_an(Integer)
    end

    it 'should return the given ID' do
      document_with_id.id.should == 'baz'
    end
  end

  describe '#tokens' do
    it 'should return nil if no tokens given' do
      document.tokens.should == nil
    end

    it 'should return the given tokens' do
      document_with_tokens.tokens.should == tokens
    end
  end

  describe '#text' do
    it 'should return the text' do
      document.text.should == text
    end
  end

  describe '#size' do
    it 'should return the number of terms if no tokens given' do
      document.size.should == 4
    end

    it 'should return the number of terms if tokens given' do
      document_with_tokens.size.should == 3
    end

    it 'should return the number of terms if no text given' do
      document_without_text.size.should == 0
    end
  end

  describe '#term_counts' do
    it 'should return the term counts if no tokens given' do
      document.term_counts.should == {'foo' => 2, 'bar' => 2}
    end

    it 'should return the term counts if tokens given' do
      document_with_tokens.term_counts.should == {'foo-foo' => 1, 'bar' => 2}
    end

    it 'should return no term counts if no text given' do
      document_without_text.term_counts.should == {}
    end
  end

"X.Y.Z. Inc.'s new product is a 123 new product \r\n\t !@#"

  describe '#terms' do
    it 'should return the terms if no tokens given' do
      document.terms.should == %w(foo bar)
    end

    it 'should return the terms if tokens given' do
      document_with_tokens.terms.should == %w(foo-foo bar)
    end

    it 'should return no terms if no text given' do
      document_without_text.terms.should == []
    end
  end

  describe '#term_frequency' do
    it 'should return the term frequency if no tokens given' do
      document.term_frequency('foo').should == Math.sqrt(2)
    end

    it 'should return the term frequency if tokens given' do
      document_with_tokens.term_frequency('foo-foo').should == 1
    end

    it 'should return no term frequency if no text given' do
      document_without_text.term_frequency('foo').should == 0
    end
  end
end
