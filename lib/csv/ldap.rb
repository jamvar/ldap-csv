require 'rubygems'
require 'net/ldap'
require 'csv'

# Csv::Ldap class
module Csv
  module Ldap
    attr_accessor :ldap, :errors
    HEAD_DEFAULTS = ["cn", "sn", "mail", "uid", "homeDirectory", "uidNumber", "gidNumber"].freeze
    BASE_DEFAULTS = 'ou=people, dc=example, dc=org'.freeze
    FILE_PATH_DEFAULT = "#{Dir.home}/ldap_entry_output.csv"

    def initialize(args)
      @ldap = Net::LDAP.new args
    end

    def valid_headers(headers = [])
      unless headers.all? { |header| @headers.include?(header) }
        raise 'need headers to process the file. Fix this error first'
      end
    end

    def delete(args)
      @ldap.delete(args)
    end

    def import(input_file_path = nil, headers = [])
      @headers ||= headers.empty? ? HEAD_DEFAULTS : headers
      @errors = []

      CSV.foreach(input_file_path, headers: true, skip_blanks: true) do |row|
        valid_headers row.headers

        dn = "cn=#{row['cn']}, ou=people, dc=example, dc=org"
        attr = row.to_h
        attr['objectclass'] = ['inetOrgPerson', 'posixAccount', 'shadowAccount']

        @ldap.add(dn: dn, attributes: attr)
        if @ldap.get_operation_result['message'] == 'Success'
          puts 'Adding cn:' + row['cn'] + ' ' +
          @ldap.get_operation_result['message']
        else
          puts 'Error cn:' + row['cn'] + ' ' +
          @ldap.get_operation_result['message']
          @errors << row['cn'] + ' ' + @ldap.get_operation_result['message']
        end
      end
    end

    def export(args = {})
      @headers = args[:headers] || HEAD_DEFAULTS
      @treebase = args[:treebase] || BASE_DEFAULTS
      @output_file_path = args[:output_file_path] || FILE_PATH_DEFAULT
      @filter ||= args[:filter]

      add_header

      CSV.open(@output_file_path, 'a+', { force_quotes: false }) do |csv|
        ldap.search(base: @treebase, filter: @filter) do |entry|
          csv << @headers.map { |x| entry.send(x).first } rescue nil
        end
      end
    end

    def add_header
      CSV.open(@output_file_path, 'w+', { force_quotes: false }) do |csv|
        csv << @headers
      end
    end

    def bind
      @ldap.bind
    end

  end
end
