#!/usr/bin/env ruby
require 'csv'

module Revolut
  Transaction = Struct.new(:date, :description, :paid_out, :paid_in, :exchange_out, :exchange_in, :balance, :category, :notes)
  class Statement
    attr_reader :path
    def initialize(path)
      @path = path
    end

    def transactions
      @transactions ||= parse_statement
    end

    def parse_statement
      CSV.read(path, col_sep: '; ', headers: true).map do |row|
        Transaction.new(
          Date.parse(row.fetch('Completed Date ')),
          row.fetch('Description ').sub(/ FX Rate .*/, '').strip,
          row.fetch('Paid Out (GBP) ').strip.to_f,
          row.fetch('Paid In (GBP) ').strip.to_f,
          row.fetch('Exchange Out').lstrip.rstrip,
          row.fetch('Exchange In').lstrip.rstrip,
          Float(row.fetch('Balance (GBP)').sub(',', '')),
          row.fetch('Category'),
          row.fetch('Notes')
        )
      end
    end

    private

    def extract_rate(desc)
      desc.split(' FX Rate ')
    end
  end

  YNABTransaction = Struct.new(:date, :payee, :memo, :inflow, :outflow)
  class YNABStatement
    attr_reader :transactions
    def self.from_revolut(rev)
      new_statement = new
      transactions = rev.transactions.map { |r| YNABTransaction.new(r.date, r.description, r.category, r.paid_in, r.paid_out) }
      new_statement.instance_variable_set(:@transactions, transactions)
      new_statement
    end

    def to_csv
      output = "Date,Payee,Memo,Outflow,Inflow\n"
      transactions.each do |transaction|
        output += "#{transaction.date.iso8601},"
        output += "#{transaction.payee},"
        output += "#{transaction.memo},"
        output += "#{transaction.outflow},"
        output += "#{transaction.inflow}"
        output += "\n"
      end
      output
    end

    def save_csv(path)
      File.open(path, 'w') { |f| f.write(to_csv) }
    end
  end
end


if $PROGRAM_NAME == __FILE__
  input, output = ARGV
  abort "\n#{$0} <revolut_statement.csv> <desired_output.csv>" unless input && output

  revolut_statement = Revolut::Statement.new(input)
  Revolut::YNABStatement.from_revolut(revolut_statement).save_csv('output.csv')
end
#Revolut::Statement.new($1)
