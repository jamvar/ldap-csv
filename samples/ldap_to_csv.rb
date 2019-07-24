require 'csv/ldap'

ldap = Csv::Ldap.new host: 'localhost',
                     port: 389,
                     auth: {
                       method: :simple,
                       username: 'cn=admin,dc=example,dc=org',
                       password: 'secret'
                     }

if ldap.bind
  # authentication succeeded
  ldap.export({output_file_path: ARGV[0]})
else
  # authentication failed
  puts ldap.get_operation_result
end
