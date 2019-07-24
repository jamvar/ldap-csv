RSpec.describe Csv::Ldap do
  before(:all) do
    @fixtures_path = 'spec/fixtures'
    @ldap = Csv::Ldap.new(host: 'localhost',
                          port: 389,
                          auth: {
                            method: :simple,
                            username: 'cn=admin,dc=example,dc=org',
                            password: 'secret'
                          })
  end

  describe 'read from csv and check to ldap' do
    it 'connection check to ldap' do
      expect(@ldap.bind).to eq(true)
    end

    it 'check if input file has headers' do
      expect do
        @ldap.import(@fixtures_path + '/invalid_entries.csv')
      end.to raise_error('need headers to process the file. Fix this error first')
    end

    it 'import successfully' do
      @ldap.delete dn: "cn=John Doe, #{Csv::Ldap::BASE_DEFAULTS}"
      @ldap.delete dn: "cn=Jeannine Sylviane, #{Csv::Ldap::BASE_DEFAULTS}"

      @ldap.import(@fixtures_path + '/valid_entries.csv')
      expect(@ldap.errors.empty?).to eq(true)
    end
  end

  describe 'writing to csv' do
    before(:each) do
      @ldap.delete dn: "cn=John Doe, #{Csv::Ldap::BASE_DEFAULTS}"
      @ldap.delete dn: "cn=Jeannine Sylviane, #{Csv::Ldap::BASE_DEFAULTS}"
      @ldap.import(@fixtures_path + '/valid_entries.csv')
    end

    context 'generate csv' do
      before(:each) do
        @output_file_path = @fixtures_path + '/ldap_entry_output.csv'
        @ldap.export(output_file_path: @output_file_path)
      end

      it 'creates a results file' do
        expect(File.file?(@output_file_path)).to be true
      end
    end

    context 'should generate csv with specific filter' do
      before(:each) do
        filter = Net::LDAP::Filter.eq('cn', 'John*')
        @output_file_path = @fixtures_path + '/ldap_data_entries_with_filter.csv'
        @ldap.export(output_file_path: @output_file_path, filter: filter)
      end

      it 'creates a results' do
        expect(File.file?(@output_file_path)).to be true
      end
    end

    after(:each) do
      @ldap.delete dn: "cn=John Doe, #{Csv::Ldap::BASE_DEFAULTS}"
      @ldap.delete dn: "cn=Jeannine Sylviane, #{Csv::Ldap::BASE_DEFAULTS}"
    end
  end
end
